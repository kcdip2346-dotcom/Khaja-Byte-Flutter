import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = Api.getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(title: 'My Bookings 📅'),
      body: KbWidth(
        child: FutureBuilder<List<Booking>>(
        future: _bookings,
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
          final bookings = snap.data ?? [];
          if (bookings.isEmpty) {
            return const EmptyState(
                emoji: '🍴',
                text: 'No bookings yet.\nPre-book your lunch and skip the queue!');
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _bookings = Api.getBookings()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BookingCard(
                b: bookings[i],
                onChanged: () => setState(() => _bookings = Api.getBookings()),
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking b;
  final VoidCallback onChanged;
  const _BookingCard({required this.b, required this.onChanged});

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(b.paymentStatus == 'paid'
            ? 'Your payment will be refunded automatically.'
            : 'You can cancel this pre-booking.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel booking',
                  style: TextStyle(color: KbColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.cancelBooking(b.id);
      if (!context.mounted) return;
      showSnack(context, 'Booking cancelled.');
      onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(kbRef(b.id),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        color: KbColors.orange700)),
                const Spacer(),
                StatusBadge(b.status),
                const SizedBox(width: 6),
                StatusBadge(b.paymentStatus == 'paid' ? 'Paid' : 'Unpaid'),
              ],
            ),
            const SizedBox(height: 10),
            Text(b.itemSummary,
                style: const TextStyle(fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event,
                    size: 15, color: KbColors.inkFaint),
                const SizedBox(width: 4),
                Text('${b.bookingDate} · ${b.timeSlot}',
                    style: const TextStyle(
                        fontSize: 12.5, color: KbColors.inkSoft)),
                const Spacer(),
                Text(npr(b.total),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: KbColors.orange700)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Placed ${b.createdAt}',
                style: const TextStyle(
                    fontSize: 11, color: KbColors.inkFaint)),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvoiceScreen(bookingId: b.id),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 17),
                  label: const Text('Invoice'),
                ),
                const Spacer(),
                if (b.cancellable)
                  TextButton.icon(
                    onPressed: () => _cancel(context),
                    style: TextButton.styleFrom(
                        foregroundColor: KbColors.red),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceScreen extends StatefulWidget {
  final int bookingId;
  const InvoiceScreen({super.key, required this.bookingId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Future<Invoice> _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = Api.getInvoice(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KbAppBar(title: 'Invoice ${kbRef(widget.bookingId)} 🧾'),
      body: KbWidth(
        child: FutureBuilder<Invoice>(
        future: _invoice,
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
          final inv = snap.data!;
          final b = inv.booking;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Billed to',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: KbColors.inkFaint)),
                          Spacer(),
                          Text('Order',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: KbColors.inkFaint)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.uname ?? 'Customer',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(b.uemail ?? '',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: KbColors.inkSoft)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${b.bookingDate} · ${b.timeSlot}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(b.createdAt,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: KbColors.inkSoft)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 26),
                      for (final line in inv.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    '${line.image} ${line.name} × ${line.qty}',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Text('${npr(line.price)} each',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: KbColors.inkSoft)),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 76,
                                child: Text(npr(line.price * line.qty),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        children: [
                          const Text('Total (NPR)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          const Spacer(),
                          Text(npr(b.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: KbColors.orange700)),
                        ],
                      ),
                      const Divider(height: 26),
                      Row(
                        children: [
                          _meta('Payment',
                              inv.txn?.method ?? 'Cash',
                              b.paymentStatus == 'paid'
                                  ? KbColors.green
                                  : KbColors.amber),
                          const SizedBox(width: 8),
                          _meta('Reference', inv.txn?.txnRef ?? '—',
                              KbColors.blue),
                          const SizedBox(width: 8),
                          _meta('Status', b.status, KbColors.orange700),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KbColors.ivory100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '🙏 Thank you for ordering at Khājā Byte — the official canteen of ING College of Innovation and Leadership. Show this receipt at the counter.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: KbColors.inkSoft,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _meta(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10.5, color: KbColors.inkFaint)),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
