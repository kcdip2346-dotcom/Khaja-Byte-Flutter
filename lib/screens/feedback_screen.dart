import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late Future<List<FeedbackItem>> _mine;
  int _rating = 0;
  final _comment = TextEditingController();
  bool _hygiene = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _mine = Api.getMyFeedback();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      showSnack(context, 'Please select a star rating.', error: true);
      return;
    }
    if (_comment.text.trim().isEmpty) {
      showSnack(context, 'Please write a short comment.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await Api.postFeedback(
          _rating, _comment.text.trim(), _hygiene);
      if (!mounted) return;
      showSnack(context, 'Thank you! Your feedback helps keep Khājā Byte clean & fair.');
      setState(() {
        _mine = Api.getMyFeedback();
        _rating = 0;
        _comment.clear();
        _hygiene = false;
      });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(
        title: 'Feedback 💬',
        subtitle: 'Your voice keeps the canteen clean & fair',
      ),
      body: KbWidth(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Share your experience',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () => setState(() => _rating = i + 1),
                        icon: Icon(
                          i < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: KbColors.orange500,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'How was the food, hygiene, pricing and service today?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _hygiene,
                    onChanged: (v) => setState(() => _hygiene = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      '🧼 This visit had a hygiene issue (flagged straight to admin)',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Submit Feedback'),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Your past feedback',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          FutureBuilder<List<FeedbackItem>>(
            future: _mine,
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
                    emoji: '📝', text: 'No feedback yet — be the first!');
              }
              return Column(
                children: list
                    .map((f) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    StarRow(f.rating),
                                    const SizedBox(width: 8),
                                    StatusBadge(f.hygieneIssue
                                        ? '🧼 Hygiene flagged'
                                        : 'General feedback'),
                                    const Spacer(),
                                    StatusBadge(f.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(f.comment,
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.5)),
                                const SizedBox(height: 6),
                                Text(f.createdAt,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: KbColors.inkFaint)),
                                if (f.response.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: KbColors.ivory100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: const Border(
                                        left: BorderSide(
                                            color: KbColors.orange500,
                                            width: 3),
                                      ),
                                    ),
                                    child: Text(
                                      'Admin reply: ${f.response}',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: KbColors.inkSoft),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}
