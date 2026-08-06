import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  /// When true (used inside staff/admin shells that already show an AppBar),
  /// the screen renders only its content without its own Scaffold/AppBar.
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _curPw = TextEditingController();
  final _newPw = TextEditingController();
  bool _savingName = false;
  bool _savingPw = false;
  bool _obscureCur = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _name.text = Api.user?.name ?? '';
  }

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _savingName = true);
    try {
      await Api.updateName(_name.text.trim());
      Api.user = Api.user!.copyWithName(_name.text.trim());
      if (mounted) {
        showSnack(context, 'Name updated.');
        setState(() {});
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePw() async {
    if (_curPw.text.isEmpty || _newPw.text.isEmpty) {
      showSnack(context, 'Fill both current and new password.', error: true);
      return;
    }
    setState(() => _savingPw = true);
    try {
      await Api.changePassword(_curPw.text, _newPw.text);
      await Api.logout();
      if (mounted) {
        showSnack(context, 'Password changed. Please log in again.');
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _savingPw = false);
    }
  }

  Future<void> _copyUid() async {
    final u = Api.user!;
    await Clipboard.setData(ClipboardData(text: u.uid));
    if (mounted) showSnack(context, 'ID copied: ${u.uid}');
  }

  Future<void> _topup(double amount) async {
    try {
      final result = await Api.topupWallet(amount);
      if (!mounted) return;
      showSnack(context, 'Wallet topped up! New balance: ${npr(result['balance'])}');
      setState(() {});
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  String get _initials {
    final parts = (Api.user?.name ?? '?').trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (Api.user?.name.isNotEmpty ?? false)
        ? Api.user!.name[0].toUpperCase()
        : '?';
  }

  String _roleLabel(String role) => switch (role) {
        'admin' => 'Admin',
        'staff' => 'Staff',
        _ => 'Student',
      };

  String _roleIcon(String role) => switch (role) {
        'admin' => '🛡️',
        'staff' => '🧑‍🍳',
        _ => '🎓',
      };

  Widget _content(BuildContext context) {
    final u = Api.user!;
    return KbWidth(
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KbColors.orange800, KbColors.orange500],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: KbColors.orange800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(u.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(u.email,
                    style: const TextStyle(
                        color: KbColors.orange200, fontSize: 12.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${_roleIcon(u.role)} ${_roleLabel(u.role)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: _copyUid,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              u.uid.isEmpty ? 'ING-???' : u.uid,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded,
                                size: 13, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account details',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _detailRow(Icons.badge_outlined, 'Unique ID', u.uid,
                    monospace: true),
                _detailRow(Icons.person_outline, 'User ID', '#${u.id}'),
                _detailRow(Icons.email_outlined, 'Email', u.email),
                _detailRow(Icons.work_outline, 'Role',
                    _roleLabel(u.role)),
                 if (u.createdAt.isNotEmpty)
                   _detailRow(Icons.event_outlined, 'Member since',
                       u.createdAt.substring(0, 10)),
                _detailRow(Icons.account_balance_wallet_rounded, 'Wallet balance', npr(u.walletBalance)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wallet',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: KbColors.green, size: 28),
                    const SizedBox(width: 10),
                    Text(npr(u.walletBalance),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: KbColors.orange700)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Top up your wallet to pay for orders instantly.',
                    style: TextStyle(fontSize: 11.5, color: KbColors.inkFaint)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final amt in [100, 200, 500])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: () => _topup(amt.toDouble()),
                            child: Text('₹$amt', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Update name',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.edit_outlined,
                          size: 20, color: KbColors.orange600)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _savingName ? null : _saveName,
                  icon: _savingName
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(_savingName ? 'Saving…' : 'Save name'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🔒 Change password',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _curPw,
                  obscureText: _obscureCur,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        size: 20, color: KbColors.orange600),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCur
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                          size: 19),
                      onPressed: () =>
                          setState(() => _obscureCur = !_obscureCur),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPw,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New password (min 6 characters)',
                    prefixIcon: const Icon(Icons.lock_reset,
                        size: 20, color: KbColors.orange600),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                          size: 19),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _savingPw ? null : _savePw,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KbColors.red),
                  icon: _savingPw
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(_savingPw ? 'Changing…' : 'Change password'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Changing your password logs you out for security.',
                  style: TextStyle(
                      fontSize: 11, color: KbColors.inkFaint),
                 ),
               ],
             ),
           ),
         ),
         const SizedBox(height: 14),
         _buildTransactionHistory(),
         const SizedBox(height: 14),
         OutlinedButton.icon(
          onPressed: () async {
            await Api.logout();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          icon: const Icon(Icons.logout, color: KbColors.red),
          label: const Text('Logout',
              style: TextStyle(color: KbColors.red)),
        ),
      ],
      ),
     );
  }

  Widget _buildTransactionHistory() {
    return FutureBuilder<List<Txn>>(
      future: Api.getTransactions(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: KbColors.orange600),
          ));
        }
        if (snap.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${snap.error}',
                style: const TextStyle(color: KbColors.red)),
          ));
        }
        final txns = snap.data ?? [];
        if (txns.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No transactions yet.',
                  style: TextStyle(color: KbColors.inkSoft)),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment History',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (final t in txns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: t.status == 'success'
                                ? KbColors.greenBg
                                : KbColors.amberBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            t.status == 'success'
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            size: 18,
                            color: t.status == 'success'
                                ? KbColors.green
                                : KbColors.amber,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.method == 'card'
                                    ? 'Card'
                                    : t.method == 'esewa'
                                        ? 'eSewa'
                                        : t.method == 'khalti'
                                            ? 'Khalti'
                                            : 'Cash',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                              Text(
                                t.txnRef,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: KbColors.inkFaint,
                                    fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        Text(npr(t.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: KbColors.orange700)),
                        const SizedBox(width: 8),
                        StatusBadge(t.status),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KbColors.inkFaint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: KbColors.inkSoft)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: monospace ? 'monospace' : null)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _content(context);
    return Scaffold(
      appBar: const KbAppBar(title: 'My Profile 👤'),
      body: _content(context),
    );
  }
}
