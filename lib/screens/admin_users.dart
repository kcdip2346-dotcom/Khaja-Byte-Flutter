import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<User>> _users;

  @override
  void initState() {
    super.initState();
    _users = Api.getAdminUsers();
  }

  void _reload() {
    setState(() { _users = Api.getAdminUsers(); });
  }

  Future<void> _adjustCredits(User u) async {
    final controller = TextEditingController();
    bool deduct = false;
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Adjust credits · ${u.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Current balance:',
                  style: TextStyle(fontSize: 12.5, color: KbColors.inkSoft)),
              const SizedBox(height: 4),
              Text(npr(u.creditBalance),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: KbColors.orange700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setDlgState(() => deduct = false),
                      style: deduct
                          ? OutlinedButton.styleFrom(
                              backgroundColor: KbColors.ivory100)
                          : FilledButton.styleFrom(
                              backgroundColor: KbColors.green),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setDlgState(() => deduct = true),
                      style: deduct
                          ? FilledButton.styleFrom(
                              backgroundColor: KbColors.red)
                          : OutlinedButton.styleFrom(
                              backgroundColor: KbColors.ivory100),
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Deduct'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: deduct ? 'Amount to deduct' : 'Amount to add',
                  prefixText: 'NRs ',
                  hintText: deduct ? 'e.g. 100' : 'e.g. 200',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v == null || v <= 0) return;
                  Navigator.pop(ctx, deduct ? -v : v);
                },
                child: const Text('Apply')),
          ],
        ),
      ),
    );
    if (amount == null) return;
    try {
      await Api.adminAdjustCredits(u.id, amount);
      if (!mounted) return;
      showSnack(context, amount > 0
          ? 'Added credits to ${u.name}.'
          : 'Deducted credits from ${u.name}.');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _changeRole(User u) async {
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change role · ${u.name}'),
        children: [
          for (final r in ['customer', 'staff', 'admin'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Row(
                children: [
                  Icon(
                    r == 'admin'
                        ? Icons.shield_outlined
                        : r == 'staff'
                            ? Icons.restaurant_outlined
                            : Icons.school_outlined,
                    size: 20,
                    color: r == u.role
                        ? KbColors.orange700
                        : KbColors.inkSoft,
                  ),
                  const SizedBox(width: 12),
                  Text(r[0].toUpperCase() + r.substring(1),
                      style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  if (r == u.role)
                    const Icon(Icons.check, size: 18, color: KbColors.orange700),
                ],
              ),
            ),
        ],
      ),
    );
    if (role == null || role == u.role) return;
    try {
      await Api.adminSetRole(u.id, role);
      if (!mounted) return;
      showSnack(context, '${u.name} is now a $role.');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _rename(User u) async {
    final controller = TextEditingController(text: u.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename · ${u.email}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == u.name) return;
    try {
      await Api.adminSetName(u.id, newName);
      if (!mounted) return;
      showSnack(context, 'Name updated for ${u.email}.');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<User>>(
        future: _users,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: KbColors.orange600));
          }
          if (snap.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${snap.error}',
                  style: const TextStyle(color: KbColors.red)),
            ));
          }
          final users = snap.data ?? [];
          final myId = Api.user?.id;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = users[i];
                final isSelf = u.id == myId;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: KbColors.orange600,
                          foregroundColor: Colors.white,
                          child: Text(
                              u.name.isEmpty ? '?' : u.name[0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              Text(u.email,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: KbColors.inkSoft)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                children: [
                                  StatusBadge(u.role),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: KbColors.orange200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '🪙 ${npr(u.creditBalance)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: KbColors.orange800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelf)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('You',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: KbColors.inkFaint)),
                          )
                        else ...[
                          _iconBtn(Icons.monetization_on_rounded,
                              'Adjust credits', KbColors.green,
                              () => _adjustCredits(u)),
                          _iconBtn(Icons.swap_horiz_rounded, 'Change role',
                              KbColors.blue, () => _changeRole(u)),
                          _iconBtn(Icons.edit_outlined, 'Rename',
                              KbColors.orange700, () => _rename(u)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
