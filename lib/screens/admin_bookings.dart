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
  String _filter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bookings = Api.getAdminBookings();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Booking> _filterBookings(List<Booking> bookings) {
    var filtered = bookings;
    if (_filter != 'all') {
      filtered = filtered.where((b) => b.status == _filter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
          (b.uname?.toLowerCase().contains(_searchQuery) ?? false) ||
          b.uemail?.toLowerCase().contains(_searchQuery) == true ||
          b.itemSummary.toLowerCase().contains(_searchQuery) ||
          kbRef(b.id).toLowerCase().contains(_searchQuery)).toList();
    }
    return filtered;
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
          final allBookings = snap.data ?? [];
          final filtered = _filterBookings(allBookings);

          // Stats
          final pending = allBookings.where((b) => b.status == 'pending').length;
          final confirmed = allBookings.where((b) => b.status == 'confirmed').length;
          final completed = allBookings.where((b) => b.status == 'completed').length;
          final totalRevenue = allBookings
              .where((b) => b.paymentStatus == 'paid')
              .fold<double>(0, (sum, b) => sum + b.total);

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _bookings = Api.getAdminBookings()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats cards
                Row(
                  children: [
                    _statCard('Pending', pending, KbColors.amber, KbColors.amberBg),
                    const SizedBox(width: 8),
                    _statCard('Confirmed', confirmed, KbColors.blue, KbColors.blueBg),
                    const SizedBox(width: 8),
                    _statCard('Done', completed, KbColors.green, KbColors.greenBg),
                  ],
                ),
                const SizedBox(height: 8),
                _statCard('Revenue', totalRevenue, KbColors.orange700, KbColors.orange200, isMoney: true),
                const SizedBox(height: 14),

                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, ref...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', 'All (${allBookings.length})'),
                      const SizedBox(width: 6),
                      _filterChip('pending', 'Pending ($pending)'),
                      const SizedBox(width: 6),
                      _filterChip('confirmed', 'Confirmed ($confirmed)'),
                      const SizedBox(width: 6),
                      _filterChip('completed', 'Done ($completed)'),
                      const SizedBox(width: 6),
                      _filterChip('cancelled', 'Cancelled'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  const EmptyState(emoji: '📅', text: 'No bookings match your filter.')
                else
                  ...filtered.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminBookingCard(
                          b: b,
                          onStatus: (s) => _setStatus(b, s),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, dynamic value, Color color, Color bgColor, {bool isMoney = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(isMoney ? npr(value) : '$value',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
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
          border: Border.all(color: selected ? KbColors.orange600 : KbColors.ivory200),
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
                Expanded(
                  child: Text(
                      b.customerName.isNotEmpty ? b.customerName : (b.uname ?? ''),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
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
                const Icon(Icons.event, size: 15, color: KbColors.inkFaint),
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
            // Quick action buttons
            Row(
              children: [
                if (b.status == 'pending') ...[
                  _actionBtn('Confirm', Icons.check_circle_outline, KbColors.green, () => onStatus('confirmed')),
                  const SizedBox(width: 6),
                  _actionBtn('Cancel', Icons.cancel_outlined, KbColors.red, () => onStatus('cancelled')),
                ] else if (b.status == 'confirmed') ...[
                  _actionBtn('Complete', Icons.done_all_rounded, KbColors.blue, () => onStatus('completed')),
                  const SizedBox(width: 6),
                  _actionBtn('Cancel', Icons.cancel_outlined, KbColors.red, () => onStatus('cancelled')),
                ] else if (b.status == 'cancelled') ...[
                  _actionBtn('Restore', Icons.restore_rounded, KbColors.amber, () => onStatus('pending')),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Invoice',
                  icon: const Icon(Icons.receipt_long_outlined, color: KbColors.orange700),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvoiceScreen(bookingId: b.id)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
