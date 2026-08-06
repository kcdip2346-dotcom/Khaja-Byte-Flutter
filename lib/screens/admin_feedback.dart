import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  late Future<List<FeedbackItem>> _feedbacks;

  @override
  void initState() {
    super.initState();
    _feedbacks = Api.getAdminFeedback();
  }

  Future<void> _respond(FeedbackItem f, String response) async {
    try {
      await Api.respondFeedback(f.id, response);
      if (!mounted) return;
      showSnack(context, 'Feedback updated.');
      setState(() => _feedbacks = Api.getAdminFeedback());
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<FeedbackItem>>(
        future: _feedbacks,
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
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
                emoji: '💬', text: 'No feedback yet.');
          }
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _feedbacks = Api.getAdminFeedback()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _FeedbackCard(
                f: list[i],
                isAdmin: Api.user?.isAdmin ?? false,
                onRespond: (r) => _respond(list[i], r),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  final FeedbackItem f;
  final bool isAdmin;
  final ValueChanged<String> onRespond;
  const _FeedbackCard(
      {required this.f, required this.isAdmin, required this.onRespond});

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reply.text = widget.f.response;
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    final highlighted = f.hygieneIssue && f.status == 'new';
    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: KbColors.red, width: 2))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(f.uname ?? 'Student',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(width: 8),
                StarRow(f.rating),
                const Spacer(),
                StatusBadge(f.status),
              ],
            ),
            const SizedBox(height: 4),
            if (f.hygieneIssue)
              const Text('🧼 Hygiene issue flagged!',
                  style: TextStyle(
                      color: KbColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(f.comment,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 6),
            Text(f.createdAt,
                style: const TextStyle(
                    fontSize: 11, color: KbColors.inkFaint)),
            const SizedBox(height: 10),
            if (widget.isAdmin)
              TextField(
                controller: _reply,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: f.response.isEmpty
                      ? 'Reply to student…'
                      : 'Update reply…',
                  isDense: true,
                ),
              )
            else if (f.response.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KbColors.greenBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFE8CF)),
                ),
                child: Text('✅ ${f.response}',
                    style: const TextStyle(
                        fontSize: 12.5, color: KbColors.green, height: 1.4)),
              )
            else
              const Text('🕐 Awaiting a reply from admin.',
                  style: TextStyle(
                      fontSize: 12, color: KbColors.inkFaint)),
            if (widget.isAdmin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                  onPressed: () =>
                      widget.onRespond(_reply.text.trim()),
                  child: Text(
                      f.response.isEmpty ? 'Reply' : 'Update reply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
