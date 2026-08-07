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
  int _newCount = 0;
  String _statusFilter = 'all';
  final _statusChips = const [
    ('all', 'All'),
    ('new', '🆕 New'),
    ('read', '👀 Reviewed'),
    ('responded', '💬 Responded'),
  ];

  @override
  void initState() {
    super.initState();
    _feedbacks = Api.getAdminFeedback();
    _feedbacks.then((l) {
      if (mounted) {
        setState(() =>
            _newCount = l.where((f) => f.status == 'new').length);
      }
    });
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _feedbacks = Api.getAdminFeedback());
  }

  Future<void> _respond(FeedbackItem f, String response) async {
    try {
      await Api.respondFeedback(f.id, response);
      if (!mounted) return;
      showSnack(context, 'Feedback updated.');
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _markReviewed(FeedbackItem f) async {
    try {
      await Api.markFeedbackReviewed(f.id);
      if (!mounted) return;
      showSnack(context, 'Marked as reviewed ✓');
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in _statusChips)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label,
                          style: const TextStyle(fontSize: 12.5)),
                      selected: _statusFilter == value,
                      onSelected: (_) => setState(() => _statusFilter = value),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FeedbackItem>>(
            future: _feedbacks,
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
              var list = snap.data ?? [];
              if (_statusFilter != 'all') {
                list =
                    list.where((f) => f.status == _statusFilter).toList();
              }
              if (list.isEmpty) {
                return const EmptyState(
                    emoji: '💬', text: 'No feedback yet.');
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _FeedbackCard(
                    f: list[i],
                    isAdmin: Api.user?.isAdmin ?? false,
                    onRespond: (r) => _respond(list[i], r),
                    onMarkReviewed: () => _markReviewed(list[i]),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Text('👀 $_newCount unreviewed',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KbColors.inkSoft)),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  final FeedbackItem f;
  final bool isAdmin;
  final ValueChanged<String> onRespond;
  final VoidCallback onMarkReviewed;
  const _FeedbackCard(
      {required this.f,
      required this.isAdmin,
      required this.onRespond,
      required this.onMarkReviewed});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (f.status == 'new')
                    TextButton.icon(
                      onPressed: widget.onMarkReviewed,
                      style: TextButton.styleFrom(
                          foregroundColor: KbColors.blue,
                          backgroundColor: KbColors.blueBg),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Mark reviewed'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40)),
                    onPressed: () =>
                        widget.onRespond(_reply.text.trim()),
                    child: Text(
                        f.response.isEmpty ? 'Reply' : 'Update reply'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
