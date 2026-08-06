import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Stats> _stats;
  late Future<List<Announcement>> _anns;

  @override
  void initState() {
    super.initState();
    _stats = Api.getStats();
    _anns = Api.getAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _stats = Api.getStats();
            _anns = Api.getAnnouncements();
          });
          await _stats;
        },
        child: FutureBuilder<Stats>(
          future: _stats,
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
            final s = snap.data!;
            final u = Api.user;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DashboardHero(
                  icon: Icons.dashboard_outlined,
                  title: 'Admin Overview',
                  subtitle:
                      '${DateFormat('EEEE, MMM d').format(DateTime.now())} · ${u?.name ?? ''} · ${u?.uid ?? ''}',
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(npr(s.revenue),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const Text('REVENUE',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                  footer: Row(
                    children: [
                      const Icon(Icons.insights_outlined,
                          size: 15, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.pending > 0
                              ? '${s.pending} booking(s) pending approval · ${s.newFb} new feedback awaiting reply'
                              : 'All systems clear — ${s.todaysBookings} booking(s) today.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.hygieneFb > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KbColors.redBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF5B5B5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cleaning_services_outlined,
                            size: 20, color: KbColors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hygiene alert! ${s.hygieneFb} unresolved hygiene report(s). Review them in Feedback.',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: KbColors.red,
                                height: 1.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const SectionHeader(
                    icon: Icons.grid_view_outlined,
                    title: 'At a glance',
                    subtitle: 'Live canteen numbers'),
                const SizedBox(height: 10),
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
                        icon: Icons.payments_outlined,
                        value: npr(s.revenue),
                        label: 'Total revenue (NPR)'),
                    StatTile(
                        icon: Icons.calendar_month_outlined,
                        value: '${s.todaysBookings}',
                        label: 'Bookings today',
                        bg: KbColors.amberBg),
                    StatTile(
                        icon: Icons.hourglass_top_outlined,
                        value: '${s.pending}',
                        label: 'Pending bookings',
                        bg: KbColors.redBg),
                    StatTile(
                        icon: Icons.star_outline_rounded,
                        value: s.avgRating == 0
                            ? '—'
                            : s.avgRating.toStringAsFixed(1),
                        label: 'Avg rating (${s.reviewCount} reviews)'),
                    StatTile(
                        icon: Icons.restaurant_menu_outlined,
                        value: '${s.items}',
                        label: 'Menu items'),
                    StatTile(
                        icon: Icons.group_outlined,
                        value: '${s.users}',
                        label: 'Registered users'),
                    StatTile(
                        icon: Icons.chat_bubble_outline,
                        value: '${s.newFb}',
                        label: 'New feedback',
                        bg: KbColors.greenBg),
                    StatTile(
                        icon: Icons.cleaning_services_outlined,
                        value: '${s.hygieneFb}',
                        label: 'Hygiene flags',
                        bg: KbColors.redBg),
                  ],
                  );
                }),
                const SizedBox(height: 18),
                const SectionHeader(
                    icon: Icons.campaign_outlined,
                    title: 'Latest announcements',
                    subtitle: 'Latest news sent to students'),
                const SizedBox(height: 10),
                FutureBuilder<List<Announcement>>(
                  future: _anns,
                  builder: (context, asnap) {
                    if (asnap.connectionState != ConnectionState.done) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: KbColors.orange600),
                      ));
                    }
                    final list = asnap.data ?? [];
                    return Column(
                      children: list
                          .take(3)
                          .map((a) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.campaign_outlined,
                                      size: 20, color: KbColors.orange700),
                                  title: Text(a.title,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      '${a.body}\n${a.createdAt}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11.5)),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
