import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class TopupScreen extends StatefulWidget {
  final VoidCallback? onBalanceChanged;
  const TopupScreen({super.key, this.onBalanceChanged});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  late Future<Map<String, dynamic>> _credits;
  final _amount = TextEditingController();
  double _quickAmount = 0;
  String _selectedMethod = 'esewa';
  bool _toppingUp = false;

  @override
  void initState() {
    super.initState();
    _credits = Api.getCredits();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _topup() async {
    final amount = _quickAmount > 0
        ? _quickAmount
        : double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      showSnack(context, 'Enter a valid amount.', error: true);
      return;
    }
    if (amount < 100) {
      showSnack(context, 'Minimum topup is NRs 100.', error: true);
      return;
    }
    setState(() => _toppingUp = true);
    try {
      final res = await Api.topupWallet(amount, _selectedMethod);
      if (!mounted) return;
      showSnack(
          context,
          'Topup successful! ${npr(amount)} added to credits.'
          '${res['txn_ref'] != null ? ' Ref: ${res['txn_ref']}' : ''}');
      setState(() => _credits = Api.getCredits());
      widget.onBalanceChanged?.call();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _toppingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top up credits'),
        backgroundColor: KbColors.orange800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _credits,
        builder: (context, snap) {
          final balance =
              (snap.data?['balance'] as num?)?.toDouble() ?? 0;
          final history =
              (snap.data?['history'] as List<dynamic>? ?? []);
          return KbWidth(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance hero
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KbColors.orange800, KbColors.orange600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: KbColors.orange800.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.35)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Credits Balance',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                Text('Instant cashless payments',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('रू',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            balance == 0 && snap.connectionState != ConnectionState.done
                                ? '…'
                                : balance.toStringAsFixed(0),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1.0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Valid for all orders across canteens',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Quick amounts
                const Text('Choose amount',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [100, 200, 500, 1000]
                      .map((v) => InkWell(
                            onTap: () => setState(() {
                              _quickAmount = v.toDouble();
                              _amount.clear();
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: _quickAmount == v
                                    ? KbColors.orange600
                                    : KbColors.ivory100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _quickAmount == v
                                        ? KbColors.orange600
                                        : KbColors.ivory200),
                              ),
                              child: Text('रू $v',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _quickAmount == v
                                          ? Colors.white
                                          : KbColors.ink)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Custom amount
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) =>
                      setState(() => _quickAmount = 0),
                  decoration: const InputDecoration(
                    labelText: 'Or enter custom amount',
                    prefixText: 'रू ',
                    hintText: 'Minimum रू 100',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment method
                const Text('Pay with',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _methodChip('esewa', '🟢', 'eSewa'),
                    const SizedBox(width: 8),
                    _methodChip('khalti', '🔴', 'Khalti'),
                    const SizedBox(width: 8),
                    _methodChip('banking', '🏦', 'Banking'),
                  ],
                ),
                const SizedBox(height: 18),

                // Topup button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _toppingUp ? null : _topup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KbColors.orange700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _toppingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.2))
                        : const Icon(Icons.add_card_rounded, size: 20),
                    label: Text(
                        _toppingUp ? 'Processing…' : 'Top up now',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 6),
                  const Center(
                  child: Text(
                    'Credits are added instantly after payment.',
                    style: TextStyle(
                        fontSize: 11, color: KbColors.inkFaint),
                  ),
                ),
                const SizedBox(height: 18),

                // Recent history
                const Text('Recent topups',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const EmptyState(
                      emoji: '🪙', text: 'No topups yet.')
                else
                  ...history.take(6).map((t) {
                    final amount = (t['amount'] as num).toDouble();
                    return Card(
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: amount > 0
                                ? KbColors.greenBg
                                : KbColors.redBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(amount > 0 ? '⬆️' : '⬇️',
                              style: const TextStyle(fontSize: 16)),
                        ),
                        title: Text(
                          '${t['type']}'.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${t['created_at']}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          '${amount > 0 ? '+' : ''}${npr(amount)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: amount > 0
                                  ? KbColors.green
                                  : KbColors.red),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _methodChip(String value, String emoji, String label) {
    final selected = _selectedMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? KbColors.orange600 : KbColors.ivory100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? KbColors.orange600 : KbColors.ivory200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : KbColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
