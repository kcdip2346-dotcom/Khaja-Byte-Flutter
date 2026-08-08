import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  List<MenuItem>? _items;
  List<Canteen>? _canteens;
  String? _error;
  Set<int> _specialItemIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';
  final _filterChips = const [
    ('all', 'All'),
    ('available', '✅ Available'),
    ('special', '⭐ Specials'),
    ('soldout', '🚫 Sold out'),
  ];
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _ownCupPrice = TextEditingController();
  final _image = TextEditingController();
  final _ingredients = TextEditingController();
  final _prepTime = TextEditingController(text: '15');
  final _dailyQty = TextEditingController(text: '0');
  String _category = 'Main Course';
  int _canteenId = 1;
  String? _photoPath;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> _filterAndSort(List<MenuItem> items) {
    var filtered = items;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) =>
          i.name.toLowerCase().contains(_searchQuery) ||
          i.category.toLowerCase().contains(_searchQuery) ||
          i.description.toLowerCase().contains(_searchQuery)).toList();
    }
    switch (_filter) {
      case 'available':
        filtered = filtered.where((i) => i.available).toList();
        break;
      case 'special':
        filtered =
            filtered.where((i) => _specialItemIds.contains(i.id)).toList();
        break;
      case 'soldout':
        filtered = filtered.where((i) => !i.available).toList();
        break;
    }
    // Specials first, then by category, then name
    filtered.sort((a, b) {
      final sa = _specialItemIds.contains(a.id) ? 0 : 1;
      final sb = _specialItemIds.contains(b.id) ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      final ca = a.category.compareTo(b.category);
      if (ca != 0) return ca;
      return a.name.compareTo(b.name);
    });
    return filtered;
  }

  Future<void> _load() async {
    try {
      final items = await Api.getMenu();
      final canteens = await Api.getCanteens();
      final offers = await Api.getOffers();
      if (!mounted) return;
      setState(() {
        _items = items;
        _canteens = canteens;
        _specialItemIds =
            offers.map((o) => o.menuItemId).whereType<int>().toSet();
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (mounted) setState(() => _photoPath = b64);
    } else {
      if (mounted) showSnack(context, 'No image selected.', error: true);
    }
  }

  Future<void> _add() async {
    final price = double.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty || price == null || price <= 0) {
      showSnack(context, 'Name and a valid NPR price are required.',
          error: true);
      return;
    }
    setState(() => _adding = true);
    try {
      String photoBase64 = '';
      if (_photoPath != null) {
        photoBase64 = _photoPath!;
      }
      final ownCup = _ownCupPrice.text.trim().isNotEmpty ? double.tryParse(_ownCupPrice.text.trim()) : null;
      final prepTime = int.tryParse(_prepTime.text.trim()) ?? 15;
      final dailyQty = int.tryParse(_dailyQty.text.trim()) ?? 0;
      await Api.addMenuItem(
          _name.text.trim(),
          _category,
          _desc.text.trim(),
          price,
          _image.text.trim().isEmpty ? '🍽️' : _image.text.trim(),
          photo: photoBase64,
          ownCupPrice: ownCup,
          canteenId: _canteenId,
          prepTime: prepTime,
          dailyQuantity: dailyQty,
          ingredients: _ingredients.text.trim());
      if (!mounted) return;
      showSnack(context, 'Menu item added.');
      _name.clear();
      _desc.clear();
      _price.clear();
      _ownCupPrice.clear();
      _image.clear();
      _ingredients.clear();
      _prepTime.text = '15';
      _dailyQty.text = '0';
      _photoPath = null;
      await _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!,
                    style: const TextStyle(color: KbColors.red)),
              ),
            )
          : items == null
              ? const Center(
                  child:
                      CircularProgressIndicator(color: KbColors.orange600))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: KbColors.ivory100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final (value, label) in _filterChips)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(label,
                                      style:
                                          const TextStyle(fontSize: 12.5)),
                                  selected: _filter == value,
                                  onSelected: (_) =>
                                      setState(() => _filter = value),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filterAndSort(items).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _AdminItemCard(
                            item: _filterAndSort(items)[i],
                            isSpecial:
                                _specialItemIds.contains(
                                        _filterAndSort(items)[i].id),
                            isAdmin: Api.user?.isAdmin ?? false,
                            onChanged: _load,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KbColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add menu item',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Item name')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Bakery', child: Text('Bakery')),
                      DropdownMenuItem(value: 'Light Bites', child: Text('Light Bites')),
                      DropdownMenuItem(value: 'Mains', child: Text('Mains')),
                      DropdownMenuItem(value: 'MO:MO', child: Text('MO:MO')),
                      DropdownMenuItem(value: 'Popcorn', child: Text('Popcorn')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                      DropdownMenuItem(value: 'Sides', child: Text('Sides')),
                      DropdownMenuItem(value: 'Combos', child: Text('Combos')),
                      DropdownMenuItem(value: 'Add Ons', child: Text('Add Ons')),
                    ],
                    onChanged: (v) => setSheetState(() => _category = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _desc,
                      decoration: const InputDecoration(
                          labelText: 'Short description')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Price (NPR)',
                                prefixText: 'NRs ')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                            controller: _ownCupPrice,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Own cup price',
                                prefixText: 'NRs ')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: _prepTime,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Prep time (min)')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                            controller: _dailyQty,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Daily qty (0=∞)')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _image,
                      decoration: const InputDecoration(
                          labelText: 'Emoji (e.g. 🍛)')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ingredients,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (comma separated)',
                      hintText: 'e.g. rice, chicken, oil, salt — optional',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _canteenId,
                    decoration: const InputDecoration(labelText: 'Canteen'),
                    items: [
                      for (final c in _canteens ?? [])
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setSheetState(() => _canteenId = v ?? 1),
                  ),
                  const SizedBox(height: 10),
                  if (_photoPath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_photoPath!.split(',')[1]),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(height: 100),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _pickPhoto();
                      setSheetState(() {});
                    },
                    icon: Icon(_photoPath != null ? Icons.check_circle : Icons.photo_camera),
                    label: Text(_photoPath != null ? 'Photo selected ✓' : 'Add photo'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _adding ? null : _add,
                    child: Text(_adding ? 'Adding…' : 'Add Item'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminItemCard extends StatefulWidget {
  final MenuItem item;
  final bool isAdmin;
  final bool isSpecial;
  final VoidCallback onChanged;
  const _AdminItemCard(
      {required this.item,
      required this.isAdmin,
      required this.isSpecial,
      required this.onChanged});

  @override
  State<_AdminItemCard> createState() => _AdminItemCardState();
}

class _AdminItemCardState extends State<_AdminItemCard> {
  late bool _available = widget.item.available;
  bool _toggling = false;

  @override
  void didUpdateWidget(_AdminItemCard old) {
    super.didUpdateWidget(old);
    if (old.item.available != widget.item.available) {
      _available = widget.item.available;
    }
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      final newState = await Api.toggleItem(widget.item.id);
      if (!mounted) return;
      setState(() => _available = newState);
      showSnack(context,
          '${widget.item.name} is now ${newState ? 'available' : 'sold out'}.');
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Widget _buildItemImage(MenuItem item) {
    if (item.photo.isNotEmpty) {
      if (item.photo.startsWith('data:')) {
        try {
          final bytes = base64Decode(item.photo.split(',')[1]);
          return Image.memory(bytes, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emojiFallback(item));
        } catch (_) {
          return _emojiFallback(item);
        }
      } else {
        return Image.network(item.photo, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _emojiFallback(item));
      }
    }
    return _emojiFallback(item);
  }

  Widget _emojiFallback(MenuItem item) {
    return Container(
      color: KbColors.ivory100,
      alignment: Alignment.center,
      child: Text(item.image, style: const TextStyle(fontSize: 22)),
    );
  }

  static String _bytesToB64(List<int> bytes) =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: widget.item.name);
    final desc = TextEditingController(text: widget.item.description);
    final price = TextEditingController(text: widget.item.price.toStringAsFixed(0));
    final ownCupPrice = TextEditingController(text: widget.item.ownCupPrice?.toStringAsFixed(0) ?? '');
    final image = TextEditingController(text: widget.item.image);
    final ingredients = TextEditingController(text: widget.item.ingredients);
    final prepTime = TextEditingController(text: widget.item.prepTime.toString());
    final dailyQty = TextEditingController(text: widget.item.dailyQuantity.toString());
    String? editPhoto;
    String category = widget.item.category;

    Future<void> pick() async {
      final picker = ImagePicker();
      final picked = await picker
          .pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        editPhoto = _bytesToB64(bytes);
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KbColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Edit ${widget.item.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    items: [
                      for (final c in ['Bakery', 'Light Bites', 'Mains', 'MO:MO', 'Popcorn', 'Beverages', 'Healthy', 'Sides', 'Combos', 'Add Ons'])
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setSheetState(() => category = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description', isDense: true)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (NPR)', prefixText: 'NRs ', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: ownCupPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Own cup price', prefixText: 'NRs ', isDense: true))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: prepTime, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prep (min)', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: dailyQty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily qty (0=∞)', isDense: true))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: image, decoration: const InputDecoration(labelText: 'Emoji (e.g. 🍛)', isDense: true)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ingredients,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Ingredients (comma separated)',
                        hintText: 'e.g. rice, chicken, oil, salt — optional',
                        isDense: true),
                  ),
                  const SizedBox(height: 8),
                  if (editPhoto != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(editPhoto!.split(',')[1]),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(height: 100),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () async {
                      await pick();
                      setSheetState(() {});
                    },
                    icon: Icon(editPhoto != null ? Icons.check_circle : Icons.photo_camera, size: 18),
                    label: Text(editPhoto != null ? 'Photo selected ✓' : 'Change photo', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final p = double.tryParse(price.text.trim());
                      if (name.text.trim().isEmpty || p == null || p <= 0) {
                        showAppError(ctx, 'Name and a valid price are required.');
                        return;
                      }
                      try {
                        final ownCup = ownCupPrice.text.trim().isNotEmpty ? double.tryParse(ownCupPrice.text.trim()) : null;
                        await Api.editItem(widget.item.id, name.text.trim(), category, desc.text.trim(), p,
                            image.text.trim().isEmpty ? '🍽️' : image.text.trim(),
                            photo: editPhoto ?? '', ownCupPrice: ownCup,
                            prepTime: int.tryParse(prepTime.text.trim()) ?? 15,
                            dailyQuantity: int.tryParse(dailyQty.text.trim()) ?? 0,
                            ingredients: ingredients.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } on ApiException catch (e) {
                        if (!ctx.mounted) return;
                        showAppError(context, e.message);
                      }
                    },
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (saved == true) {
      if (!context.mounted) return;
      showSnack(context, 'Menu item updated.');
      widget.onChanged();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${widget.item.name}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: KbColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteItem(widget.item.id);
      if (!context.mounted) return;
      showSnack(context, 'Menu item removed.');
      widget.onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAdmin = widget.isAdmin;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 50,
                height: 50,
                child: _buildItemImage(item),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  if (widget.isSpecial)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('⭐ Today\'s special',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: KbColors.orange700)),
                    ),
                  Text(
                      '${item.category} · ${npr(item.price)}${item.ownCupPrice != null ? ' · 🥤${npr(item.ownCupPrice!)}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: KbColors.inkSoft)),
                  Text('Prep: ${item.prepTime}min · Qty: ${item.dailyQuantity == 0 ? '∞' : item.dailyQuantity}',
                      style: const TextStyle(
                          fontSize: 11, color: KbColors.inkFaint)),
                  if (item.ingredients.isNotEmpty)
                    Text('🥗 ${item.ingredients}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: KbColors.inkFaint)),
                  const SizedBox(height: 4),
                  StatusBadge(_available ? 'Available' : 'Sold out'),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _available
                    ? KbColors.greenBg
                    : KbColors.redBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: _available
                    ? 'Mark sold out'
                    : 'Mark available',
                onPressed: _toggling ? null : _toggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: _toggling
                      ? const SizedBox(
                          key: ValueKey('spin'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: KbColors.orange700),
                        )
                      : Icon(
                          key: ValueKey(_available),
                          _available
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _available
                              ? KbColors.green
                              : KbColors.red,
                        ),
                ),
              ),
            ),
            if (isAdmin) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined,
                    color: KbColors.blue),
                onPressed: () => _edit(context),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline,
                    color: KbColors.red),
                onPressed: () => _delete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
