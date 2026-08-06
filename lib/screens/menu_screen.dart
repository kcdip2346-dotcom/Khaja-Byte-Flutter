import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Map<int, int> _cart = {};
  late Future<List<MenuItem>> _items;
  final _slots = [
    '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', '4:00 PM', '5:30 PM'
  ];

  @override
  void initState() {
    super.initState();
    _items = Api.getMenu();
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
                final categories = items
                    .map((e) => e.category)
                    .toSet()
                    .toList();
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _items = Api.getMenu()),
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
                        for (final item in items.where(
                            (e) => e.category == cat))
                          _ItemCard(
                            item: item,
                            qty: _cart[item.id] ?? 0,
                            onAdd: () => setState(() => _cart[item.id] =
                                (_cart[item.id] ?? 0) + 1),
                            onRemove: () => setState(() {
                              final q = (_cart[item.id] ?? 0) - 1;
                              if (q <= 0) {
                                _cart.remove(item.id);
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
        items: items,
        slots: _slots,
        subtotal: subtotal,
      ),
    );
    setState(() {});
  }
}

class _ItemCard extends StatelessWidget {
  final MenuItem item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _ItemCard({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
  final List<MenuItem> items;
  final List<String> slots;
  final double subtotal;
  const CheckoutSheet({
    super.key,
    required this.cart,
    required this.items,
    required this.slots,
    required this.subtotal,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  String _slot = '11:00 AM';
  String _method = 'card';
  bool _willingToDrink = false;
  bool _useOwnCup = false;
  int _redeemPoints = 0;
  bool _showQR = false;
  final _payName = TextEditingController();
  final _payDetail = TextEditingController();
  bool _loading = false;

  bool get _hasColdDrink => widget.cart.keys.any((id) {
        final item = widget.items.firstWhere((i) => i.id == id);
        return item.category == 'Beverages';
      });

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

  int get _maxRedeemPoints => Api.user?.walletBalance.toInt() ?? 0;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _placeOrder() async {
    if (_hasColdDrink && !_willingToDrink) {
      showSnack(context, 'Please confirm you are willing to drink cold beverages.',
          error: true);
      return;
    }
    if (_method != 'card' &&
        (_payName.text.trim().isEmpty || _payDetail.text.trim().isEmpty)) {
      showSnack(context, 'Please fill in your payment details.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await Api.placeOrder(
        widget.cart.entries
            .map((e) => {'id': e.key, 'qty': e.value})
            .toList(),
        _today,
        _slot,
        _method,
        paymentName: _payName.text.trim(),
        paymentDetail: _payDetail.text.trim(),
        useOwnCup: _useOwnCup,
        redeemPoints: _redeemPoints,
      );
      if (!mounted) return;
      Navigator.pop(context);
      final walletUsed = result['wallet_used'] as double? ?? 0;
      final queueWait = result['queue_wait'] as int? ?? 0;
      final prepTime = result['prep_time'] as int? ?? 15;
      showSnack(
        context,
        'Order placed! ${kbRef(result['booking_id'] as int)} · Prep: ${prepTime}min · Queue: ${queueWait}min${walletUsed > 0 ? ' · ₹${walletUsed.toStringAsFixed(0)} from wallet' : ''}',
      );
      setState(() {});
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.image} ${item.name} × ${e.value}',
                                    style: const TextStyle(fontSize: 13))),
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
            DropdownButtonFormField<String>(
              initialValue: _slot,
              decoration: const InputDecoration(
                  labelText: 'Time slot',
                  prefixIcon: Icon(Icons.schedule,
                      color: KbColors.orange600, size: 20)),
              items: widget.slots
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _slot = v!),
            ),
            const SizedBox(height: 12),
            const Text(
              '📌 Pre-bookings are only accepted for today — same-day pickup.',
              style: TextStyle(
                  fontSize: 12, color: KbColors.inkSoft, height: 1.4),
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
                _payChip('esewa', '🟣', 'eSewa'),
                _payChip('khalti', '🔵', 'Khalti'),
              ],
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
                      onChanged: (v) => setState(() => _useOwnCup = v ?? false),
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
            if (_maxRedeemPoints > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KbColors.ivory100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KbColors.ivory200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            size: 18, color: KbColors.green),
                        const SizedBox(width: 6),
                        Text('Use wallet balance (₹$_maxRedeemPoints)',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _redeemPoints.toDouble(),
                            min: 0,
                            max: _maxRedeemPoints > 100 ? 100 : _maxRedeemPoints.toDouble(),
                            divisions: _maxRedeemPoints > 100 ? 20 : (_maxRedeemPoints > 10 ? 10 : _maxRedeemPoints),
                            onChanged: (v) => setState(() => _redeemPoints = v.round()),
                            activeColor: KbColors.orange600,
                          ),
                        ),
                        Text('₹$_redeemPoints',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            if (_maxRedeemPoints > 0) const SizedBox(height: 14),
            if (_method != 'card') ...[
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
                  onPressed: () => setState(() => _showQR = true),
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
                  : Text('✅ Place Order & Pay · ${npr(_effectiveSubtotal)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payChip(String value, String emoji, String label) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
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
