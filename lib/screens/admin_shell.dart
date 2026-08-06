import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import 'admin_announcements.dart';
import 'admin_bookings.dart';
import 'admin_dashboard.dart';
import 'admin_feedback.dart';
import 'admin_menu.dart';
import 'admin_transactions.dart';
import 'admin_users.dart';
import 'profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _titles = [
    'Admin Dashboard',
    'Menu & Prices',
    'Bookings',
    'Feedback',
    'Announcements',
    'Transactions',
    'Users',
    'My Profile',
  ];

  static const _screens = [
    AdminDashboardScreen(),
    AdminMenuScreen(),
    AdminBookingsScreen(),
    AdminFeedbackScreen(),
    AdminAnnouncementsScreen(),
    AdminTransactionsScreen(),
    AdminUsersScreen(),
    ProfileScreen(embedded: true),
  ];

  /// Bottom bar shows 5 primary tabs; the rest open from the "More" sheet.
  static const _moreItems = [
    (4, Icons.campaign_outlined, 'Announcements'),
    (5, Icons.receipt_long_outlined, 'Transactions'),
    (6, Icons.group_outlined, 'Users'),
    (7, Icons.person_outline, 'My Profile'),
  ];

  void _openMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KbColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('More',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final (idx, icon, label) in _moreItems)
              ListTile(
                leading: Icon(icon,
                    color: _index == idx
                        ? KbColors.orange700
                        : KbColors.inkSoft),
                title: Text(label,
                    style: TextStyle(
                        color: _index == idx
                            ? KbColors.orange800
                            : KbColors.ink,
                        fontWeight: _index == idx
                            ? FontWeight.w700
                            : FontWeight.w500)),
                trailing: _index == idx
                    ? const Icon(Icons.check,
                        size: 18, color: KbColors.orange700)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _index = idx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
        selectedIndex: _index >= 4 ? 4 : _index,
        onDestinationSelected: (i) {
          if (i == 4) {
            _openMore();
          } else {
            setState(() => _index = i);
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.feedback_outlined),
              selectedIcon: Icon(Icons.feedback),
              label: 'Feedback'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More'),
        ],
      ),
    );
  }
}
