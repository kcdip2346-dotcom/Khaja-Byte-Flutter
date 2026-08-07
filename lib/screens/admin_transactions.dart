import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  late Future<List<Txn>> _txns;
  late Future<List<Map<String, dynamic>>> _creditsTxns;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _txns = Api.getAdminTransactions();
    _creditsTxns = Api.getCreditsTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_txns, _creditsTxns]),
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
          final txns = (snap.data?[0] as List<dynamic>? ?? [])
              .map((e) =>
                  e is Txn ? e : Txn.fromJson(e as Map<String, dynamic>))
              .toList();
          final creditsTxns = (snap.data?[1] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();

          final orderTxns = txns
              .where((t) => _filter == 'all' || t.method == _filter)
              .toList();

          final totalRevenue = txns
              .where((t) => t.status == 'success' && t.method != 'Refund')
              .fold<double>(0, (a, b) => a + b.amount);

          final totalCreditsTopup = creditsTxns
              .where((t) =>
                  (t['type'] as String).contains('topup') &&
                  (t['amount'] as num) > 0)
              .fold<double>(0, (a, t) => a + (t['amount'] as num).toDouble());

          final totalCreditsSpent = creditsTxns
              .where((t) =>
                  (t['amount'] as num) < 0 ||
                  (t['type'] as String).contains('deduct'))
              .fold<double>(0, (a, t) => a + (t['amount'] as num).toDouble().abs());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats overview
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KbColors.greenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Revenue',
                              style: TextStyle(fontSize: 11, color: KbColors.green)),
                          const SizedBox(height: 4),
                          Text(npr(totalRevenue),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800, color: KbColors.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KbColors.orange200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Credits Topup',
                              style: TextStyle(fontSize: 11, color: KbColors.orange800)),
                          const SizedBox(height: 4),
                          Text(npr(totalCreditsTopup),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800, color: KbColors.orange800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KbColors.blueBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Credits Spent',
                              style: TextStyle(fontSize: 11, color: KbColors.blue)),
                          const SizedBox(height: 4),
                          Text(npr(totalCreditsSpent),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800, color: KbColors.blue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Credits transactions section
              if (creditsTxns.isNotEmpty) ...[
                const Text('Credits Transactions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final t in creditsTxns.take(10))
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (t['amount'] as num) > 0
                              ? KbColors.greenBg
                              : KbColors.redBg,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                            (t['amount'] as num) > 0 ? '⬆️' : '⬇️',
                            style: const TextStyle(fontSize: 19)),
                      ),
                      title: Text('${t['type']}'.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      subtitle: Text('${t['uname'] ?? ''} · ${t['createdAt']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                          '${(t['amount'] as num) > 0 ? '+' : '-'}${npr((t['amount'] as num).toDouble().abs())}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: (t['amount'] as num) > 0
                                  ? KbColors.green
                                  : KbColors.red)),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Filter tabs for order transactions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All'),
                    const SizedBox(width: 6),
                    _filterChip('card', 'Card'),
                    const SizedBox(width: 6),
                    _filterChip('esewa', 'eSewa'),
                    const SizedBox(width: 6),
                    _filterChip('khalti', 'Khalti'),
                    const SizedBox(width: 6),
                    _filterChip('credits', 'Credits'),
                    const SizedBox(width: 6),
                    _filterChip('Refund', 'Refund'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Order transactions
              const Text('Order Transactions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (orderTxns.isEmpty)
                const EmptyState(emoji: '📭', text: 'No transactions found.')
              else
                for (final t in orderTxns)
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: t.method == 'card'
                              ? KbColors.blueBg
                              : t.method == 'Refund'
                                  ? KbColors.greenBg
                                  : t.method == 'credits'
                                      ? KbColors.orange200
                                      : KbColors.amberBg,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                            t.method == 'card'
                                ? '💳'
                                : t.method == 'Refund'
                                    ? '↩️'
                                    : t.method == 'credits'
                                        ? '🪙'
                                        : '📱',
                            style: const TextStyle(fontSize: 19)),
                      ),
                      title: Text(t.txnRef,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${t.uname ?? ''}\n${t.method} · ${t.createdAt}'
                          '${t.bookingId != null ? ' · ${kbRef(t.bookingId!)}' : ''}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(npr(t.amount),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: t.method == 'Refund'
                                      ? KbColors.green
                                      : KbColors.orange700)),
                          const SizedBox(height: 3),
                          StatusBadge(t.status),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KbColors.orange600 : KbColors.ivory100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? KbColors.orange600 : KbColors.ivory200),
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
