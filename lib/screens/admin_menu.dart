import 'package:flutter/material.dart';

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
  String? _error;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _image = TextEditingController();
  String _category = 'Main Course';
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Api.getMenu();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
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
      await Api.addMenuItem(
          _name.text.trim(),
          _category,
          _desc.text.trim(),
          price,
          _image.text.trim().isEmpty ? '🍽️' : _image.text.trim());
      if (!mounted) return;
      showSnack(context, 'Menu item added.');
      _name.clear();
      _desc.clear();
      _price.clear();
      _image.clear();
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _AdminItemCard(
                      item: items[i],
                      isAdmin: Api.user?.isAdmin ?? false,
                      onChanged: _load,
                    ),
                  ),
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
      builder: (ctx) => Padding(
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
                  DropdownMenuItem(value: 'Main Course', child: Text('Main Course')),
                  DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                  DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                  DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _desc,
                  decoration: const InputDecoration(
                      labelText: 'Short description')),
              const SizedBox(height: 10),
              TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Price (NPR)',
                      prefixText: 'रू ')),
              const SizedBox(height: 10),
              TextField(
                  controller: _image,
                  decoration: const InputDecoration(
                      labelText: 'Emoji (e.g. 🍛)')),
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
  }
}

class _AdminItemCard extends StatefulWidget {
  final MenuItem item;
  final bool isAdmin;
  final VoidCallback onChanged;
  const _AdminItemCard(
      {required this.item,
      required this.isAdmin,
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

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: widget.item.name);
    final desc = TextEditingController(text: widget.item.description);
    final price =
        TextEditingController(text: widget.item.price.toStringAsFixed(0));
    final image = TextEditingController(text: widget.item.image);
    String category = widget.item.category;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KbColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit ${widget.item.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Main Course', child: Text('Main Course')),
                    DropdownMenuItem(
                        value: 'Snacks', child: Text('Snacks')),
                    DropdownMenuItem(
                        value: 'Beverages', child: Text('Beverages')),
                    DropdownMenuItem(
                        value: 'Healthy', child: Text('Healthy')),
                  ],
                  onChanged: (v) => setSheetState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: desc,
                    decoration: const InputDecoration(
                        labelText: 'Description')),
                const SizedBox(height: 10),
                TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Price (NPR)', prefixText: 'रू ')),
                const SizedBox(height: 10),
                TextField(
                    controller: image,
                    decoration:
                        const InputDecoration(labelText: 'Emoji')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final p = double.tryParse(price.text.trim());
                    if (name.text.trim().isEmpty || p == null || p <= 0) {
                      showSnack(ctx,
                          'Name and a valid NPR price are required.',
                          error: true);
                      return;
                    }
                    try {
                      await Api.editItem(widget.item.id, name.text.trim(),
                          category,
                          desc.text.trim(), p,
                          image.text.trim().isEmpty ? '🍽️' : image.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } on ApiException catch (e) {
                      if (!ctx.mounted) return;
                      showSnack(ctx, e.message, error: true);
                    }
                  },
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
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
                child: item.photo.isNotEmpty
                    ? Image.network(item.photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: KbColors.ivory100,
                            alignment: Alignment.center,
                            child: Text(item.image,
                                style: const TextStyle(fontSize: 22))))
                    : Container(
                        color: KbColors.ivory100,
                        alignment: Alignment.center,
                        child: Text(item.image,
                            style: const TextStyle(fontSize: 22))),
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
                  Text(
                      '${item.category} · ${npr(item.price)}',
                      style: const TextStyle(
                          fontSize: 12, color: KbColors.inkSoft)),
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
