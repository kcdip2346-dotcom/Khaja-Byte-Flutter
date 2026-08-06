import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<Txn>> _txns;

  @override
  void initState() {
    super.initState();
    _txns = Api.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(
        title: 'Transaction History 💳',
        subtitle: 'Every payment in Nepali Rupees (रू)',
      ),
      body: KbWidth(
        child: FutureBuilder<List<Txn>>(
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
          if (txns.isEmpty) {
            return const EmptyState(
                emoji: '🧾',
                text: 'No transactions yet.\nPlace your first order and pay online!');
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _txns = Api.getTransactions()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: txns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = txns[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _methodColor(t.method),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(_methodEmoji(t.method),
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.txnRef,
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                  '${t.method} · ${t.createdAt}'
                                  '${t.bookingId != null ? ' · ${kbRef(t.bookingId!)}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: KbColors.inkSoft)),
                            ],
                          ),
                        ),
                        Column(
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
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        ),
      ),
    );
  }

  Color _methodColor(String m) {
    switch (m) {
      case 'card':
        return KbColors.blueBg;
      case 'esewa':
      case 'khalti':
        return KbColors.orange200;
      case 'Refund':
        return KbColors.greenBg;
      default:
        return KbColors.ivory200;
    }
  }

  String _methodEmoji(String m) {
    switch (m) {
      case 'card':
        return '💳';
      case 'esewa':
        return '🟣';
      case 'khalti':
        return '🔵';
      case 'Refund':
        return '↩️';
      default:
        return '💵';
    }
  }
}
