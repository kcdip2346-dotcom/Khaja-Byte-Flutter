import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'menu_screen.dart';
import 'transactions_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late Future<List<Announcement>> _anns;
  late Future<List<Offer>> _offers;

  @override
  void initState() {
    super.initState();
    _anns = Api.getAnnouncements();
    _offers = Api.getOffers();
  }

  @override
  Widget build(BuildContext context) {
    final u = Api.user;
    final name = u?.name.split(' ').first ?? '';
    final role = u?.role == 'staff'
        ? 'Staff'
        : u?.role == 'admin'
            ? 'Admin'
            : 'Student';
    final points = u?.creditPoints ?? 0;
    return Scaffold(
      appBar: KbAppBar(
        title: 'Namaste, $name!',
        subtitle:
            '${DateFormat('EEEE, MMM d').format(DateTime.now())} · $role · ${u?.uid ?? ''}',
        actions: [
          if (points > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.stars_rounded, size: 16, color: KbColors.amber),
                label: Text('$points pts', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                backgroundColor: KbColors.ivory100,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: KbColors.orange700),
            tooltip: 'Logout',
            onPressed: () async {
              await Api.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _anns = Api.getAnnouncements());
          await _anns;
        },
        child: KbWidth(
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DashboardHero(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan to Pay',
              subtitle: 'Point your camera at the canteen QR to pay instantly.',
              trailing: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MenuScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: KbColors.orange800,
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Open scanner',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              footer: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Every booking is same-day. Kitchen is audited every Friday — spot an issue? Flag it in Feedback.',
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
            // Combo deals section
            const SectionHeader(
                icon: Icons.local_offer_outlined, title: 'Combo deals'),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _comboCard('Mo:Mo + Drink', 'Any Mo:Mo + beverage at ₹199', '🥟🥤', KbColors.orange700),
                  _comboCard('Rice Bowl Combo', 'Rice + curry + pickle at ₹175', '🍚', KbColors.green),
                  _comboCard('Pasta Special', 'Any pasta + garlic bread at ₹299', '🍝', KbColors.amber),
                  _comboCard('Snack Pack', 'Fries + popcorn + drink at ₹250', '🍟', KbColors.blue),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<Offer>>(
              future: _offers,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                final offers = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        icon: Icons.local_offer_outlined, title: 'Today\'s specials'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: offers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final o = offers[i];
                          return Container(
                            width: 200,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [KbColors.orange700, KbColors.orange500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                if (o.body.isNotEmpty)
                                  Text(o.body,
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    if (o.discountPct > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('${o.discountPct}% OFF',
                                            style: const TextStyle(
                                                color: KbColors.orange800,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const SectionHeader(
                icon: Icons.bolt_outlined, title: 'Quick actions'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    icon: Icons.receipt_long_outlined,
                    iconBg: KbColors.greenBg,
                    iconColor: KbColors.green,
                    title: 'Payment history',
                    sub: 'View transactions',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TransactionsScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.qr_code_scanner_rounded,
                    iconBg: KbColors.orange200,
                    iconColor: KbColors.orange800,
                    title: 'Scan to pay',
                    sub: 'QR payment',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MenuScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionHeader(
                icon: Icons.campaign_outlined,
                title: 'Latest announcements',
                subtitle: 'Official updates from the canteen team'),
            const SizedBox(height: 10),
            FutureBuilder<List<Announcement>>(
              future: _anns,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: KbColors.orange600)),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const EmptyState(emoji: '📭', text: 'No announcements.');
                }
                return Column(
                  children: list
                      .take(3)
                      .map((a) => _AnnouncementTile(a: a))
                      .toList(),
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _comboCard(String title, String subtitle, String emoji, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _QuickCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 11.5, color: KbColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: KbColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement a;
  const _AnnouncementTile({required this.a});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [KbColors.orange200, KbColors.ivory100]),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.campaign_outlined,
                  size: 20, color: KbColors.orange800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 3),
                  Text(a.body,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: KbColors.inkSoft,
                          height: 1.5)),
                  const SizedBox(height: 6),
                  Text('By ${a.author} · ${a.createdAt}',
                      style: const TextStyle(
                          fontSize: 11, color: KbColors.inkFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
