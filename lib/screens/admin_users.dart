import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<User>> _users;

  @override
  void initState() {
    super.initState();
    _users = Api.getAdminUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<User>>(
        future: _users,
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
          final users = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _users = Api.getAdminUsers()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: KbColors.orange600,
                      foregroundColor: Colors.white,
                      child: Text(
                          u.name.isEmpty ? '?' : u.name[0].toUpperCase()),
                    ),
                    title: Text(u.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Text(
                        '${u.email}\nJoined ${u.createdAt}',
                        style: const TextStyle(fontSize: 11.5)),
                    trailing: StatusBadge(u.role),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
