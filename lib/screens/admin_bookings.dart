import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'bookings_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = Api.getAdminBookings();
  }

  Future<void> _setStatus(Booking b, String status) async {
    try {
      await Api.setBookingStatus(b.id, status);
      if (!mounted) return;
      showSnack(context, '${kbRef(b.id)} → ${status.toUpperCase()}');
      setState(() => _bookings = Api.getAdminBookings());
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

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
          final bookings = snap.data ?? [];
          if (bookings.isEmpty) {
            return const EmptyState(emoji: '📅', text: 'No bookings yet.');
          }
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _bookings = Api.getAdminBookings()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AdminBookingCard(
                b: bookings[i],
                onStatus: (s) => _setStatus(bookings[i], s),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final Booking b;
  final ValueChanged<String> onStatus;
  const _AdminBookingCard({required this.b, required this.onStatus});

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
                const SizedBox(width: 8),
                Text(b.uname ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                StatusBadge(b.status),
              ],
            ),
            if (b.uemail != null)
              Text(b.uemail!,
                  style: const TextStyle(
                      fontSize: 11, color: KbColors.inkFaint)),
            const SizedBox(height: 8),
            Text(b.itemSummary,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event,
                    size: 15, color: KbColors.inkFaint),
                const SizedBox(width: 4),
                Text('${b.bookingDate} · ${b.timeSlot}',
                    style: const TextStyle(
                        fontSize: 12.5, color: KbColors.inkSoft)),
                const Spacer(),
                StatusBadge(b.paymentStatus == 'paid' ? 'Paid' : 'Unpaid'),
                const SizedBox(width: 8),
                Text(npr(b.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: KbColors.orange700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DropdownButton<String>(
                  value: b.status,
                  items: ['pending', 'confirmed', 'completed', 'cancelled']
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != b.status) onStatus(v);
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Invoice',
                  icon: const Icon(Icons.receipt_long_outlined,
                      color: KbColors.orange700),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => InvoiceScreen(bookingId: b.id)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
