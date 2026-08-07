import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'feedback_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => BookingsScreenState();
}

class BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> _bookings;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _bookings = Api.getBookings();
  }

  void reload() {
    if (mounted) setState(() => _bookings = Api.getBookings());
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    if (_filter == 'all') return bookings;
    return bookings.where((b) => b.status == _filter).toList();
  }

  int _priority(String status) => switch (status) {
        'pending' => 0,
        'confirmed' => 1,
        'completed' => 2,
        'cancelled' => 3,
        _ => 4,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Booking>>(
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
          final allBookings = snap.data ?? [];
          allBookings.sort((a, b) {
            final byStatus = _priority(a.status).compareTo(_priority(b.status));
            if (byStatus != 0) return byStatus;
            return b.createdAt.compareTo(a.createdAt);
          });
          final bookings = _filterBookings(allBookings);

          final pending = allBookings.where((b) => b.status == 'pending').length;
          final confirmed = allBookings.where((b) => b.status == 'confirmed').length;
          final completed = allBookings.where((b) => b.status == 'completed').length;
          final totalSpent = allBookings
              .where((b) => b.paymentStatus == 'paid')
              .fold<double>(0, (sum, b) => sum + b.total);

          return RefreshIndicator(
            onRefresh: () async => setState(() => _bookings = Api.getBookings()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats overview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KbColors.orange800, KbColors.orange600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Orders',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statChip('$pending', 'Pending', KbColors.amber),
                          const SizedBox(width: 8),
                          _statChip('$confirmed', 'Ready', KbColors.blue),
                          const SizedBox(width: 8),
                          _statChip('$completed', 'Done', KbColors.green),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total spent',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white70)),
                              Text(npr(totalSpent),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', 'All (${allBookings.length})'),
                      const SizedBox(width: 6),
                      _filterChip('pending', 'Pending'),
                      const SizedBox(width: 6),
                      _filterChip('confirmed', 'Ready'),
                      const SizedBox(width: 6),
                      _filterChip('completed', 'Done'),
                      const SizedBox(width: 6),
                      _filterChip('cancelled', 'Cancelled'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (bookings.isEmpty)
                  const EmptyState(
                      emoji: '🍴',
                      text: 'No bookings yet.\nPre-book your lunch and skip the queue!')
                else
                  ...bookings.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookingCard(
                          b: b,
                          onChanged: () =>
                              setState(() => _bookings = Api.getBookings()),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.white70)),
        ],
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

class _BookingCard extends StatelessWidget {
  final Booking b;
  final VoidCallback onChanged;
  const _BookingCard({required this.b, required this.onChanged});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return KbColors.amber;
      case 'confirmed':
        return KbColors.blue;
      case 'completed':
        return KbColors.green;
      case 'cancelled':
        return KbColors.red;
      default:
        return KbColors.inkFaint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _hm(DateTime t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  /// Scheduled pickup time from bookingDate + timeSlot (handles 12h/24h slots).
  DateTime? _pickupTime(Booking b) {
    final date = DateTime.tryParse(b.bookingDate);
    if (date == null) return null;
    final slot = b.timeSlot.trim().toUpperCase();
    var hour = 0;
    var min = 0;
    final m12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(slot);
    if (m12 != null) {
      hour = int.parse(m12.group(1)!);
      if (m12.group(3) == 'PM' && hour < 12) hour += 12;
      if (m12.group(3) == 'AM' && hour == 12) hour = 0;
      min = int.parse(m12.group(2)!);
    } else {
      final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(slot);
      if (m24 == null) return null;
      hour = int.parse(m24.group(1)!);
      min = int.parse(m24.group(2)!);
    }
    return DateTime(date.year, date.month, date.day, hour, min);
  }

  /// Unclaimed-orders policy (30 min pickup hold, no refund after) as a hint
  /// on ready bookings.
  Widget _pickupHoldRow(Booking b) {
    final pickup = _pickupTime(b);
    final heldUntil =
        pickup?.add(const Duration(minutes: 30));
    final overdue =
        heldUntil != null && DateTime.now().isAfter(heldUntil);
    final color = overdue ? KbColors.red : KbColors.amber;
    return Row(
      children: [
        Icon(overdue
            ? Icons.warning_amber_rounded
            : Icons.schedule_send_outlined,
            size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            overdue
                ? 'Unclaimed past the 30-minute pickup hold — order may be '
                    'discarded, no refund.'
                : 'Pickup hold: collect by ${_hm(heldUntil!)} '
                    '(30 min after slot)',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel booking?'),
        content: Text(b.paymentStatus == 'paid'
            ? 'Your payment will be refunded automatically. '
                'This is only possible within the 7-minute free cancellation '
                'window.'
            : 'You can cancel this pre-booking within the 7-minute free '
                'cancellation window.'),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _statusColor(b.status).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(b.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_statusIcon(b.status),
                      color: _statusColor(b.status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kbRef(b.id),
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              color: KbColors.orange700)),
                      Text('${b.bookingDate} · ${b.timeSlot}',
                          style: const TextStyle(
                              fontSize: 12, color: KbColors.inkSoft)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(npr(b.total),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: KbColors.orange700)),
                    StatusBadge(b.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            BookingItemThumbs(itemsJson: b.itemsJson, fallback: b.itemSummary),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: _statusColor(b.status)),
                const SizedBox(width: 4),
                Text(
                    b.status == 'pending'
                        ? 'Waiting for confirmation'
                        : b.status == 'confirmed'
                            ? 'Being prepared'
                            : b.status == 'completed'
                                ? 'Ready for pickup'
                                : 'Cancelled',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: _statusColor(b.status),
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Paid',
                    style: TextStyle(
                        fontSize: 11,
                        color: b.paymentStatus == 'paid'
                            ? KbColors.green
                            : KbColors.amber,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (b.status == 'completed') ...[
              const SizedBox(height: 6),
              _pickupHoldRow(b),
            ],
            if (b.status == 'pending' || b.status == 'confirmed') ...[
              const SizedBox(height: 8),
              LiveTimingChip(
                queueWait: b.queueWait,
                prepTime: b.prepTime,
                totalTime: b.totalTime,
                start: kbUtcToLocal(b.createdAt),
              ),
              const SizedBox(height: 6),
              if (b.cancellable)
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: KbColors.orange700),
                    const SizedBox(width: 5),
                    Text(
                        'Free cancellation until '
                        '${_hm(b.cancelBy!)} — window closes soon',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: KbColors.orange700)),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(Icons.lock_clock_outlined,
                        size: 14, color: KbColors.inkFaint),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Cancellation window closed — order is being prepared '
                        'and is now final.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: KbColors.inkFaint)),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvoiceScreen(bookingId: b.id),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: const Text('Invoice'),
                  ),
                ),
                if (b.status == 'completed') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FeedbackScreen(initialBookingId: b.id),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: KbColors.orange700),
                      icon: const Icon(Icons.rate_review_outlined, size: 17),
                      label: const Text('Review'),
                    ),
                  ),
                ],
                if (b.cancellable) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _cancel(context),                      style: TextButton.styleFrom(
                          foregroundColor: KbColors.red),
                      icon: const Icon(Icons.close, size: 17),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
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
                                    fontSize: 11, color: KbColors.inkFaint)),
                            Spacer(),
                            Text('Order',
                                style: TextStyle(
                                    fontSize: 11, color: KbColors.inkFaint)),
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
                                        fontSize: 11, color: KbColors.inkSoft)),
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
                                        fontSize: 12, color: KbColors.inkSoft)),
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
                            _meta('Payment', inv.txn?.method ?? 'Cash',
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
              style: const TextStyle(fontSize: 10.5, color: KbColors.inkFaint)),
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
