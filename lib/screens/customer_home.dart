import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'topup_screen.dart';
import 'transactions_screen.dart';

class CustomerHome extends StatefulWidget {
  final int unreadNotifs;
  final VoidCallback? onOpenAlerts;
  const CustomerHome({super.key, this.unreadNotifs = 0, this.onOpenAlerts});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late Future<List<Announcement>> _anns;
  double _balance = Api.user?.creditBalance ?? 0;
  Set<int> _seenAnnIds = {};
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _anns = Api.getAnnouncements();
    _anns.then((l) {
      _seenAnnIds = l.map((a) => a.id).toSet();
    });
    _refreshBalance();
    // Live refresh: balance + announcements arrive without user action
    _liveTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshBalance();
      _checkAnnouncements();
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    try {
      final credits = await Api.getCredits();
      if (!mounted) return;
      final bal = (credits['balance'] as num?)?.toDouble();
      if (bal != null && bal != _balance) {
        setState(() { _balance = bal; });
      }
    } catch (_) {}
  }

  Future<void> _checkAnnouncements() async {
    try {
      final list = await Api.getAnnouncements();
      if (!mounted) return;
      final fresh = list
          .where((a) => !_seenAnnIds.contains(a.id))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (fresh.isNotEmpty) {
        setState(() {
          _anns = Future.value(list);
          _seenAnnIds = list.map((a) => a.id).toSet();
        });
        showTopToast(
            context,
            '📢 ${fresh.last.title} — ${fresh.last.body.split('\n').first}',
            icon: Icons.campaign_rounded,
            color: KbColors.orange700);
      }
    } catch (_) {}
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
    return Scaffold(
      appBar: KbAppBar(
        title: 'Namaste, $name!',
        subtitle:
            '${DateFormat('EEEE, MMM d').format(DateTime.now())} · $role · ${u?.uid ?? ''}',
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${widget.unreadNotifs}'),
              isLabelVisible: widget.unreadNotifs > 0,
              child: const Icon(Icons.notifications_outlined,
                  color: KbColors.orange700),
            ),
            tooltip: 'Alerts',
            onPressed: widget.onOpenAlerts ??
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: KbColors.orange700),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
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
          setState(() { _anns = Api.getAnnouncements(); });
          await _anns;
          await _refreshBalance();
        },
        child: KbWidth(
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WalletHero(
              balance: _balance,
              onTopup: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => TopupScreen(
                          onBalanceChanged: _refreshBalance))),
              onOrder: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MenuScreen())),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 18),
            // Combo deals section
            const SectionHeader(
                icon: Icons.local_offer_outlined, title: 'Combo deals'),
            const SizedBox(height: 10),
            FutureBuilder<List<MenuItem>>(
              future: Api.getMenu(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 140,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: KbColors.orange600)),
                  );
                }
                final combos = (snap.data ?? [])
                    .where((i) =>
                        i.category == 'Combos' && i.available)
                    .toList();
                if (combos.isEmpty) {
                  return const EmptyState(
                      emoji: '🍱', text: 'No combos available right now.');
                }
                return SizedBox(
                  height: 178,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in combos)
                        _comboCard(c),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Credit deals section — expensive items with the points discount
            const SectionHeader(
                icon: Icons.savings_outlined,
                title: 'Credit deals',
                subtitle: '20% off when you pay with credit points'),
            const SizedBox(height: 10),
            FutureBuilder<List<MenuItem>>(
              future: Api.getMenu(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 140,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: KbColors.orange600)),
                  );
                }
                final deals = (snap.data ?? [])
                    .where((i) => i.creditDeal && i.available)
                    .toList();
                if (deals.isEmpty) {
                  return const EmptyState(
                      emoji: '🪙', text: 'No credit deals right now.');
                }
                return SizedBox(
                  height: 170,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final d in deals) _dealCard(d),
                    ],
                  ),
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
          ],
          ),
        ),
      ),
    );
  }


  Widget _dealCard(MenuItem deal) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MenuScreen(comboName: deal.name))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KbColors.greenBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFE8CF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${deal.image} ',
                    style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: KbColors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('-20%',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(deal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    height: 1.25)),
            const Spacer(),
            Text('${npr(deal.price)} · 🪙 20% off',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KbColors.green)),
          ],
        ),
      ),
    );
  }

  Widget _comboCard(MenuItem combo) {
    final colors = [
      KbColors.orange700,
      KbColors.green,
      KbColors.amber,
      KbColors.red,
      KbColors.blue,
    ];
    final n = combo.name.toLowerCase();
    final color = (n.contains('snack pack') || n.contains('rice bowl'))
        ? KbColors.red
        : colors[combo.id % colors.length];
    return InkWell(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MenuScreen(comboName: combo.name))),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                      top: Radius.circular(4)),
                ),
                child: const Text('DEAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(combo.image, style: const TextStyle(fontSize: 30)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
                Text(combo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(combo.description.isEmpty
                    ? 'All-in-one meal deal'
                    : combo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 10.5,
                        height: 1.35)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(npr(combo.price),
                          style: TextStyle(
                              color: color,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    const Icon(Icons.add_circle_rounded,
                        size: 22, color: Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  final double balance;
  final VoidCallback onTopup;
  final VoidCallback onOrder;
  const _WalletHero({
    required this.balance,
    required this.onTopup,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KbColors.orange800, KbColors.orange600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: KbColors.orange800.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.wallet_rounded,
                    size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Credits Wallet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Cashless payments made easy 🪙',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text('Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                const Spacer(),
                Text(npr(balance),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: KbColors.orange800,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_card, size: 17),
                  label: const Text('Top up',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.3),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.restaurant_menu, size: 17),
                  label: const Text('Order now',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
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
