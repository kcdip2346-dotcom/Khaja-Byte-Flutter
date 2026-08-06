import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_bookings.dart';
import 'admin_feedback.dart';
import 'admin_menu.dart';
import 'profile_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  static const _titles = [
    'Staff Counter',
    'Bookings',
    'Availability',
    'Feedback',
    'My Profile',
  ];

  static const _screens = [
    StaffHomeScreen(),
    AdminBookingsScreen(),
    AdminMenuScreen(),
    AdminFeedbackScreen(),
    ProfileScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KbColors.orange800,
        foregroundColor: Colors.white,
        title: Text(_titles[_index],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Api.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: IndexedStack(index: _index, children: _screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Counter'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.visibility_outlined),
              selectedIcon: Icon(Icons.visibility),
              label: 'Availability'),
          NavigationDestination(
              icon: Icon(Icons.feedback_outlined),
              selectedIcon: Icon(Icons.feedback),
              label: 'Feedback'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = Api.getStaffToday();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async =>
            setState(() => _data = Api.getStaffToday()),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: KbColors.orange600));
            }
            if (snap.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}',
                    style: const TextStyle(color: KbColors.red)),
              ));
            }
            final today = (snap.data!['today'] as List)
                .map((e) => Booking.fromJson(e as Map<String, dynamic>))
                .toList();
            final anns = (snap.data!['announcements'] as List)
                .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
                .toList();
            final pending =
                today.where((b) => b.status == 'pending').length;
            final unpaid =
                today.where((b) => b.paymentStatus == 'unpaid').length;
            final u = Api.user;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DashboardHero(
                  icon: Icons.storefront_outlined,
                  title: 'Today at the counter',
                  subtitle: '${DateFormat('EEEE, MMM d').format(DateTime.now())} · ${u?.name ?? ''} · ${u?.uid ?? ''}',
                  trailing: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${today.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        const Text('BOOKINGS',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 8)),
                      ],
                    ),
                  ),
                  footer: Row(
                    children: [
                      const Icon(Icons.bolt_outlined,
                          size: 15, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pending > 0
                              ? '$pending order(s) still pending to prepare — get cooking!'
                              : 'All today\'s orders are handled. Great job!',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, cons) {
                  final cols = cons.maxWidth > 700
                      ? 3
                      : cons.maxWidth > 420
                          ? 2
                          : 1;
                  final aspect = switch (cols) { 3 => 3.0, 2 => 4.6, _ => 5.5 };
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: aspect,
                    children: [
                      StatTile(
                          icon: Icons.hourglass_top_outlined,
                          value: '$pending',
                          label: 'Pending to prepare',
                          bg: KbColors.redBg),
                      StatTile(
                          icon: Icons.calendar_month_outlined,
                          value: '${today.length}',
                          label: 'Bookings today'),
                      StatTile(
                          icon: Icons.payments_outlined,
                          value: '$unpaid',
                          label: 'To collect at counter',
                          bg: KbColors.amberBg),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const SectionHeader(
                    icon: Icons.receipt_long_outlined,
                    title: "Today's pre-bookings",
                    subtitle: 'Prepare these before the bell rings'),
                const SizedBox(height: 10),
                if (today.isEmpty)
                  const EmptyState(
                      emoji: '🍃',
                      text:
                          'No pre-bookings today. Quiet day!\nCustomers will pre-book from the student app — orders appear here instantly.')
                else
                  for (final b in today)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const Spacer(),
                                StatusBadge(b.status),
                                const SizedBox(width: 6),
                                StatusBadge(b.paymentStatus == 'paid'
                                    ? 'Paid'
                                    : 'Unpaid'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(b.itemSummary,
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.5)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('${b.bookingDate} · ${b.timeSlot}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: KbColors.inkSoft)),
                                const Spacer(),
                                Text(npr(b.total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: KbColors.orange700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                const SectionHeader(
                    icon: Icons.campaign_outlined,
                    title: 'Latest announcements',
                    subtitle: 'Updates from the canteen team'),
                const SizedBox(height: 10),
                for (final a in anns)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign_outlined,
                          size: 20, color: KbColors.orange700),
                      title: Text(a.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      subtitle: Text('${a.body}\n${a.createdAt}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
