import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _anns;

  @override
  void initState() {
    super.initState();
    _anns = Api.getAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(
        title: 'Announcements 📢',
        subtitle: 'Official updates from the canteen team',
      ),
      body: KbWidth(
        child: FutureBuilder<List<Announcement>>(
        future: _anns,
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
          final anns = snap.data ?? [];
          if (anns.isEmpty) {
            return const EmptyState(emoji: '📭', text: 'No announcements yet.');
          }
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() { _anns = Api.getAnnouncements(); }),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: anns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = anns[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  KbColors.orange200,
                                  KbColors.ivory100
                                ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.campaign_outlined,
                                  size: 20, color: KbColors.orange800),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(a.body,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: KbColors.inkSoft,
                                      height: 1.5)),
                              const SizedBox(height: 6),
                              Text('By ${a.author} · ${a.createdAt}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: KbColors.inkFaint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        ),
      ),
    );
  }
}
