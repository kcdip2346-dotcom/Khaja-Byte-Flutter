import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class MenuScreen extends StatefulWidget {
  final String? comboName;
  const MenuScreen({super.key, this.comboName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Map<int, int> _cart = {};
  final Map<int, List<String>> _excluded = {};
  late Future<List<MenuItem>> _items;
  late Future<List<Offer>> _offers;
  bool _comboAdded = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Set<int> _specialItemIds = {};
  String _categoryFilter = 'all';
  String _quickFilter = 'all';

  @override
  void initState() {
    super.initState();
    _items = Api.getMenu();
    _offers = Api.getOffers();
    _offers.then((offers) {
      _specialItemIds = offers.map((o) => o.menuItemId).whereType<int>().toSet();
    });
    _items.then((items) {
      if (!_comboAdded && widget.comboName != null && widget.comboName!.isNotEmpty) {
        _comboAdded = true;
        for (final item in items) {
          if (item.name == widget.comboName && item.available) {
            _cart[item.id] = 1;
            break;
          }
        }
        if (_cart.isNotEmpty && mounted) {
          setState(() {});
          showSnack(context, '${widget.comboName} added to cart!');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(
        title: 'Menu & Pre-book 🍽️',
        subtitle: 'Transparent prices in Nepali Rupees (रू)',
      ),
      body: KbWidth(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _searchQuery = ''; });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: KbColors.ivory100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() { _searchQuery = v.toLowerCase(); }),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KbColors.greenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFE8CF)),
            ),
            child: const Text(
              '🧼 Hygiene protected · items marked Sold Out are genuinely unavailable. No hidden prices — your bill is itemised.',
              style: TextStyle(
                  fontSize: 12, color: KbColors.green, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildFilterChips(),
          ),
          Expanded(
            child: FutureBuilder<List<MenuItem>>(
              future: _items,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: KbColors.orange600));
                }
                if (snap.hasError) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: KbColors.red)),
                  ));
                }
                final items = snap.data ?? [];
                final filteredItems = items.where((i) {
                  if (_searchQuery.isNotEmpty &&
                      !(i.name.toLowerCase().contains(_searchQuery) ||
                          i.category.toLowerCase().contains(_searchQuery) ||
                          i.description.toLowerCase().contains(_searchQuery))) {
                    return false;
                  }
                  if (_categoryFilter != 'all' &&
                      i.category != _categoryFilter) {
                    return false;
                  }
                  switch (_quickFilter) {
                    case 'available':
                      if (!i.available) return false;
                      break;
                    case 'specials':
                      if (!_specialItemIds.contains(i.id)) return false;
                      break;
                    case 'combos':
                      if (i.category != 'Combos') return false;
                      break;
                  }
                  return true;
                }).toList();
                final categories = filteredItems
                    .map((e) => e.category)
                    .toSet()
                    .toList();
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() { _items = Api.getMenu(); }),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final cat in categories) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(cat,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: KbColors.orange800)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Container(
                                      height: 2,
                                      decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        KbColors.orange200,
                                        Colors.transparent
                                      ])))),
                            ],
                          ),
                        ),
                        for (final item in filteredItems
                            .where((e) => e.category == cat)
                            .toList()
                          ..sort((a, b) {
                            final sa =
                                _specialItemIds.contains(a.id) ? 0 : 1;
                            final sb =
                                _specialItemIds.contains(b.id) ? 0 : 1;
                            return sa != sb
                                ? sa.compareTo(sb)
                                : a.name.compareTo(b.name);
                          }))
                          _ItemCard(
                            item: item,
                            qty: _cart[item.id] ?? 0,
                            isSpecial: _specialItemIds.contains(item.id),
                            excluded: _excluded[item.id] ?? const [],
                            onCustomize: () => _showIngredientPicker(item),
                            onAdd: () => setState(() => _cart[item.id] =
                                (_cart[item.id] ?? 0) + 1),
                            onRemove: () => setState(() {
                              final q = (_cart[item.id] ?? 0) - 1;
                              if (q <= 0) {
                                _cart.remove(item.id);
                                _excluded.remove(item.id);
                              } else {
                                _cart[item.id] = q;
                              }
                            }),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          _CartBar(
            count: _cart.values.fold(0, (a, b) => a + b),
            onCheckout: _cart.isEmpty
                ? null
                : () async {
                    final items = await _items;
                    await _openCheckout(items);
                  },
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _openCheckout(List<MenuItem> items) async {
    final subtotal = _cart.entries.fold<double>(
        0, (sum, e) => sum + (e.value * items.firstWhere((i) => i.id == e.key).price));
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KbColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => CheckoutSheet(
        cart: _cart,
        excluded: _excluded,
        items: items,
        subtotal: subtotal,
      ),
    );
    setState(() {});
  }

  Future<void> _showIngredientPicker(MenuItem item) async {
    final all = item.ingredients
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (all.isEmpty) return;
    final current = _excluded[item.id] ?? [];
    final picked = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          void toggle(String ing) {
            setDlgState(() {
              if (current.contains(ing)) {
                current.remove(ing);
              } else {
                current.add(ing);
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            title: Text('Remove ingredients — ${item.name}',
                style: const TextStyle(fontSize: 15.5)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Allergic? Select what to leave out of your order.',
                    style: TextStyle(fontSize: 12, color: KbColors.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final ing in all)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(ing,
                                style: const TextStyle(fontSize: 13)),
                            value: current.contains(ing),
                            activeColor: KbColors.red,
                            onChanged: (_) => toggle(ing),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, const <String>[]),
                  child: const Text('Reset')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, List.of(current)),
                style: FilledButton.styleFrom(backgroundColor: KbColors.red),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.isEmpty) {
        _excluded.remove(item.id);
      } else {
        _excluded[item.id] = picked;
      }
    });
  }

  Widget _buildFilterChips() {
    return FutureBuilder<List<MenuItem>>(
      future: _items,
      builder: (context, snap) {
        final items = snap.data ?? [];
        final categories = items.map((e) => e.category).toSet().toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('all', 'All', _quickFilter == 'all' &&
                      _categoryFilter == 'all'),
                  const SizedBox(width: 6),
                  _chip('available', '✅ Available', _quickFilter == 'available'),
                  const SizedBox(width: 6),
                  _chip('specials', '⭐ Specials', _quickFilter == 'specials'),
                  const SizedBox(width: 6),
                  _chip('combos', '🍱 Combos', _quickFilter == 'combos'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('cat_all', 'All categories', _categoryFilter == 'all'),
                  for (final c in categories) ...[
                    const SizedBox(width: 6),
                    _chip('cat_$c', c, _categoryFilter == c),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String value, String label, bool selected) {
    Color color;
    if (value == 'all' || value == 'cat_all') {
      color = KbColors.ink;
    } else if (value.startsWith('cat_')) {
      color = KbColors.orange700;
    } else {
      color = KbColors.blue;
    }
    return InkWell(
      onTap: () {
        if (value == 'all') {
          setState(() {
            _categoryFilter = 'all';
            _quickFilter = 'all';
          });
        } else if (value.startsWith('cat_')) {
          final cat = value.substring(4);
          setState(() { _categoryFilter = _categoryFilter == cat ? 'all' : cat; });
        } else {
          setState(() =>
              _quickFilter = _quickFilter == value ? 'all' : value);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : KbColors.ivory100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : KbColors.ivory200, width: 1.2),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : KbColors.ink)),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final MenuItem item;
  final int qty;
  final bool isSpecial;
  final List<String> excluded;
  final VoidCallback onCustomize;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _ItemCard({
    required this.item,
    required this.qty,
    this.isSpecial = false,
    this.excluded = const [],
    required this.onCustomize,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSpecial ? KbColors.ivory100 : null,
      shape: isSpecial
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: KbColors.orange400, width: 1.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: item.photo.isNotEmpty
                    ? Image.network(
                        item.photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _emPlaceholder(),
                      )
                    : _emPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      if (isSpecial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KbColors.orange200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('SPECIAL',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: KbColors.orange800)),
                        ),
                      const SizedBox(width: 6),
                      if (!item.available)
                        const StatusBadge('Sold out'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: KbColors.inkSoft)),
                  const SizedBox(height: 6),
                  Text(npr(item.price),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: KbColors.orange700)),
                  if (item.ingredients.isNotEmpty)
                    _IngredientsToggle(ingredients: item.ingredients),
                  if (item.ingredients.isNotEmpty && item.available) ...[
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: onCustomize,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_food_outlined,
                              size: 15, color: KbColors.red),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              excluded.isEmpty
                                  ? 'Remove ingredients (allergy)'
                                  : 'Removing: ${excluded.join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: KbColors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.available)
              _QtyStepper(qty: qty, onAdd: onAdd, onRemove: onRemove),
          ],
        ),
      ),
    );
  }

  Widget _emPlaceholder() => Container(
        color: KbColors.ivory100,
        alignment: Alignment.center,
        child: Text(item.image, style: const TextStyle(fontSize: 26)),
      );
}

class _IngredientsToggle extends StatefulWidget {
  final String ingredients;
  const _IngredientsToggle({required this.ingredients});

  @override
  State<_IngredientsToggle> createState() => _IngredientsToggleState();
}

class _IngredientsToggleState extends State<_IngredientsToggle> {
  bool _open = false;

  static const _allergens = [
    'nut', 'peanut', 'soy', 'wheat', 'gluten', 'dairy', 'milk', 'egg',
    'shellfish', 'fish', 'sesame',
  ];

  @override
  Widget build(BuildContext context) {
    final text = widget.ingredients.toLowerCase();
    final hasAllergen = _allergens.any(text.contains);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() { _open = !_open; }),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_open ? Icons.expand_less : Icons.expand_more,
                  size: 15, color: KbColors.blue),
              const SizedBox(width: 3),
              Text(_open ? 'Hide ingredients' : 'View ingredients',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KbColors.blue)),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KbColors.ivory100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.ingredients,
                style: const TextStyle(fontSize: 11, height: 1.4)),
          ),
          if (hasAllergen) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KbColors.amberBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('⚠️ May contain common allergens — check before ordering.',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: KbColors.amber)),
            ),
          ],
        ],
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyStepper(
      {required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: KbColors.orange300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            color: KbColors.orange900,
            onPressed: qty == 0 ? null : onRemove,
          ),
          Text('$qty',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            color: KbColors.orange900,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int count;
  final VoidCallback? onCheckout;
  const _CartBar({required this.count, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: KbColors.ivory,
        border: Border(top: BorderSide(color: KbColors.ivory200)),
      ),
      child: ElevatedButton.icon(
        onPressed: onCheckout,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text(count == 0
            ? 'Add items to pre-book & pay'
            : 'Checkout · $count item(s)'),
      ),
    );
  }
}

class CheckoutSheet extends StatefulWidget {
  final Map<int, int> cart;
  final Map<int, List<String>> excluded;
  final List<MenuItem> items;
  final double subtotal;
  const CheckoutSheet({
    super.key,
    required this.cart,
    this.excluded = const {},
    required this.items,
    required this.subtotal,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  TimeOfDay _slot = const TimeOfDay(hour: 11, minute: 0);
  String _method = 'card';
  bool _useOwnCup = false;
  bool _showQR = false;
  static const double _creditsDiscountPct = 0.10; // keep in sync with backend
  double get _creditsDue => _effectiveSubtotal * (1 - _creditsDiscountPct);
  final _payName = TextEditingController();
  final _payDetail = TextEditingController();
  final _customerName = TextEditingController();
  bool _loading = false;

  bool get _hasBeverageWithOwnCup => widget.cart.keys.any((id) {
        final item = widget.items.firstWhere((i) => i.id == id);
        return item.category == 'Beverages' && item.ownCupPrice != null;
      });

  double get _effectiveSubtotal {
    double total = 0;
    for (final e in widget.cart.entries) {
      final item = widget.items.firstWhere((i) => i.id == e.key);
      final price = (_useOwnCup && item.ownCupPrice != null) ? item.ownCupPrice! : item.price;
      total += price * e.value;
    }
    return total;
  }

  double get _creditBalance => Api.user?.creditBalance ?? 0;

  String get _formattedTime {
    final hour = _slot.hourOfPeriod;
    final minute = _slot.minute.toString().padLeft(2, '0');
    final period = _slot.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get _timeForApi {
    return '${_slot.hour.toString().padLeft(2, '0')}:${_slot.minute.toString().padLeft(2, '0')}';
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _slot,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Only allow times between 9 AM and 5 PM
      if (picked.hour >= 9 && picked.hour <= 17) {
        setState(() { _slot = picked; });
      } else {
        if (mounted) {
          showAppError(context, 'Please select a time between 9 AM and 5 PM.');
        }
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_method != 'card' && _method != 'credits' && _method != 'cash' &&
        (_payName.text.trim().isEmpty || _payDetail.text.trim().isEmpty)) {
      showAppError(context, 'Please fill in your payment details.');
      return;
    }
    if (_method == 'credits' && _creditBalance < _creditsDue) {
      showAppError(context,
          'Insufficient credits. Please topup or choose another method.');
      return;
    }
    setState(() { _loading = true; });
    try {
      final result = await Api.placeOrder(
        widget.cart.entries
            .map((e) => {
                  'id': e.key,
                  'qty': e.value,
                  if ((widget.excluded[e.key] ?? const []).isNotEmpty)
                    'exclude': widget.excluded[e.key],
                })
            .toList(),
        _today,
        _timeForApi,
        _method,
        paymentName: _payName.text.trim(),
        paymentDetail: _payDetail.text.trim(),
        useOwnCup: _useOwnCup,
        useWallet: _method == 'credits' ? _creditsDue : 0,
        customerName: _customerName.text.trim().isNotEmpty
            ? _customerName.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      final creditsUsed = result['wallet_used'] as double? ?? 0;
      final queueWait = result['queue_wait'] as int? ?? 0;
      final prepTime = result['prep_time'] as int? ?? 15;
      showSnack(
        context,
        'Order placed! ${kbRef(result['booking_id'] as int)} · Prep: ${prepTime}min · Queue: ${queueWait}min${creditsUsed > 0 ? ' · ${npr(creditsUsed)} paid from credits (10% off)' : ''}',
      );
      setState(() {});
    } on ApiException catch (e) {
      if (mounted) showAppError(context, e.message);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: safe),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Checkout & Payment',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Itemised bill — no hidden prices 🇳🇵',
                style: TextStyle(
                    fontSize: 12, color: KbColors.inkSoft)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KbColors.ivory100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KbColors.orange300),
              ),
              child: Column(
                children: [
                  for (final e in widget.cart.entries)
                    Builder(builder: (_) {
                      final item = widget.items
                          .firstWhere((i) => i.id == e.key);
                      final excl = widget.excluded[e.key] ?? const <String>[];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${item.image} ${item.name} × ${e.value}',
                                      style: const TextStyle(fontSize: 13)),
                                  if (excl.isNotEmpty)
                                    Text(
                                        '🚫 no ${excl.join(', no ')}',
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: KbColors.red)),
                                ],
                              ),
                            ),
                            Text(npr(item.price * e.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total payable',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(npr(widget.subtotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: KbColors.orange700)),
                    ],
                  ),
                  if (_method == 'credits') ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Credits discount (10%)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: KbColors.green)),
                          Text('- ${npr(_effectiveSubtotal - _creditsDue)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: KbColors.green)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You pay with credits',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: KbColors.inkSoft)),
                        Text(npr(_creditsDue),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: KbColors.green)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Pre-booking date',
                prefixIcon: Icon(Icons.event,
                    color: KbColors.orange600, size: 20),
                suffixIcon: Icon(Icons.lock_outline,
                    size: 16, color: KbColors.inkFaint),
              ),
              child: Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: KbColors.ink),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Pickup time',
                    prefixIcon: Icon(Icons.schedule,
                        color: KbColors.orange600, size: 20)),
                child: Text(
                  _formattedTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to select time (9 AM - 5 PM)',
              style: TextStyle(fontSize: 11, color: KbColors.inkFaint),
            ),
            const SizedBox(height: 12),
            const Text(
              '📌 Pre-bookings are only accepted for today — same-day pickup.',
              style: TextStyle(
                  fontSize: 12, color: KbColors.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerName,
              decoration: const InputDecoration(
                labelText: 'Name on order (optional)',
                prefixIcon: Icon(Icons.person_outline,
                    color: KbColors.orange600, size: 20),
                hintText: 'Different name for this order',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment method',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: KbColors.inkSoft)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _payChip('card', '💳', 'Card'),
                _payChip('esewa', '🟢', 'eSewa'),
                _payChip('khalti', '🔴', 'Khalti'),
                _payChip('credits', '🪙', 'Credits'),
                _payChip('cash', '💵', 'Cash'),
              ],
            ),
            const SizedBox(height: 14),
            if (_method == 'credits' && _creditBalance <= 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KbColors.redBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5B5B5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: KbColors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('No credits balance. Topup via Alerts tab.',
                          style: TextStyle(fontSize: 12, color: KbColors.red)),
                    ),
                  ],
                ),
              ),
            if (_method == 'credits' && _creditBalance > 0 && _creditBalance < _creditsDue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KbColors.amberBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: KbColors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Insufficient credits (${_creditBalance.toInt()} available). Topup via Alerts tab.',
                          style: const TextStyle(fontSize: 12, color: KbColors.amber)),
                    ),
                  ],
                ),
              ),
            if (_method == 'credits' && _creditBalance >= _creditsDue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KbColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFE8CF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: KbColors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Pay ${npr(_creditsDue)} from credits — 10% off (save ${npr(_effectiveSubtotal - _creditsDue)})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KbColors.green)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (_hasBeverageWithOwnCup)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _useOwnCup ? KbColors.greenBg : KbColors.ivory100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _useOwnCup ? const Color(0xFFBFE8CF) : KbColors.ivory200),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _useOwnCup,
                      onChanged: (v) => setState(() { _useOwnCup = v ?? false; }),
                      activeColor: KbColors.orange700,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bringing my own cup 🥤',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: KbColors.green),
                          ),
                          Text(
                            'Get discounted price on beverages',
                            style: TextStyle(
                                fontSize: 11, color: KbColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_hasBeverageWithOwnCup) const SizedBox(height: 14),
            if (_method != 'card' && _method != 'credits') ...[
              if (_showQR)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KbColors.orange300),
                  ),
                  child: Column(
                    children: [
                      const Text('Scan this QR to pay',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_rounded,
                                size: 120, color: KbColors.orange800),
                            const SizedBox(height: 4),
                            Text('KB-PAY-${_method.toUpperCase()}',
                                style: const TextStyle(
                                    fontSize: 10, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Show this to the canteen staff',
                          style: TextStyle(
                              fontSize: 11, color: KbColors.inkFaint)),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => setState(() { _showQR = true; }),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: Text('Show QR for $_method payment'),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _payName,
                decoration: InputDecoration(
                  labelText: _method == 'card'
                      ? 'Name on card'
                      : '$_method full name',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _payDetail,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _method == 'card'
                      ? 'Card number'
                      : '$_method number (98XXXXXXXX)',
                ),
              ),
            ] else if (_method == 'credits') ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KbColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFE8CF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: KbColors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('Pay ${npr(_creditsDue)} from credits balance — 10% off',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _payName,
                decoration: const InputDecoration(
                  labelText: 'Name on card',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _payDetail,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card number',
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loading ? null : _placeOrder,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('✅ Place Order & Pay · ${npr(_method == 'credits' ? _creditsDue : widget.subtotal)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payChip(String value, String emoji, String label) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() { _method = value; }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? KbColors.orange200 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KbColors.orange500 : KbColors.ivory200,
            width: 1.5,
          ),
        ),
        child: Text('$emoji $label',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? KbColors.orange900 : KbColors.ink)),
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: KbColors.orange800,
        foregroundColor: Colors.white,
        title: const Text('Scan Canteen QR',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handled = true;
              try {
                _controller.stop();
              } catch (_) {}
              if (mounted) Navigator.of(context).pop(raw);
            },
            errorBuilder: (context, error) => const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_photography_outlined,
                        size: 42, color: Colors.white54),
                    SizedBox(height: 12),
                    Text(
                      'Could not start the camera.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Allow camera access in your browser, or press the back button.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: KbColors.orange500, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            bottom: 34,
            child: Text(
              'Point the camera at the canteen payment QR',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
