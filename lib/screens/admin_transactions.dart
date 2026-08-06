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

  @override
  void initState() {
    super.initState();
    _txns = Api.getAdminTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Txn>>(
        future: _txns,
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
          final txns = snap.data ?? [];
          final total = txns
              .where((t) => t.status == 'success' && t.method != 'Refund')
              .fold<double>(0, (a, b) => a + b.amount);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatTile(
                  icon: Icons.payments_outlined,
                  value: npr(total),
                  label: 'Total revenue (NPR) · ${txns.length} transactions'),
              const SizedBox(height: 12),
              for (final t in txns)
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
                                : KbColors.orange200,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                          t.method == 'card'
                              ? '💳'
                              : t.method == 'Refund'
                                  ? '↩️'
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
}
