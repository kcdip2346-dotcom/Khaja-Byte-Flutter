import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  late Future<List<Announcement>> _anns;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _anns = Api.getAdminAnnouncements();
  }

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      showSnack(context, 'Title and message are required.', error: true);
      return;
    }
    setState(() { _posting = true; });
    try {
      await Api.addAnnouncement(_title.text.trim(), _body.text.trim());
      if (!mounted) return;
      showSnack(context, 'Announcement published 📢');
      _title.clear();
      _body.clear();
      setState(() { _anns = Api.getAdminAnnouncements(); });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() { _posting = false; });
    }
  }

  Future<void> _delete(Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${a.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: KbColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteAnnouncement(a.id);
      if (!mounted) return;
      showSnack(context, 'Announcement deleted.');
      setState(() { _anns = Api.getAdminAnnouncements(); });
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('➕ Publish announcement',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                        labelText: 'Title (e.g. Momo special Friday 🥟)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _posting ? null : _post,
                    child: Text(_posting ? 'Publishing…' : '📢 Publish'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Announcement>>(
            future: _anns,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: KbColors.orange600),
                ));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const EmptyState(
                    emoji: '📭', text: 'No announcements yet.');
              }
              return Column(
                children: list
                    .map((a) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.campaign_outlined,
                                size: 20, color: KbColors.orange700),
                            title: Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                            subtitle: Text(
                                '${a.body}\nBy ${a.author} · ${a.createdAt}',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: KbColors.red),
                              onPressed: () => _delete(a),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
