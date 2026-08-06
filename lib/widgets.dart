import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

String npr(num v) => 'रू ${v.toStringAsFixed(0)}';

/// Centers content and caps its width so cards don't stretch huge on web/desktop.
class KbWidth extends StatelessWidget {
  final Widget child;
  const KbWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: child,
      ),
    );
  }
}

/// Gradient hero header used at the top of every dashboard.
class DashboardHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? footer;
  const DashboardHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.footer,
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
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: KbColors.orange200, fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Section title with an orange accent bar.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: KbColors.orange500,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: KbColors.orange700),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 11, color: KbColors.inkSoft)),
          ],
        ),
      ],
    );
  }
}

String kbRef(int id) => '#KB${id.toString().padLeft(4, '0')}';

void showSnack(BuildContext context, String msg,
    {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? KbColors.red : KbColors.ink,
  ));
}

class KbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  const KbAppBar({super.key, required this.title, this.subtitle, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: KbColors.inkSoft,
                    fontWeight: FontWeight.w400)),
        ],
      ),
      actions: actions,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  const StatusBadge(this.text, {super.key});

  Color get color {
    switch (text.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'confirmed':
      case 'responded':
      case 'available':
        return KbColors.green;
      case 'pending':
      case 'read':
        return KbColors.blue;
      case 'cancelled':
      case 'sold out':
      case 'failed':
        return KbColors.red;
      case 'completed':
      case 'unpaid':
      case 'refund':
      case 'new':
      case 'unavailable':
      default:
        return KbColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  final int rating;
  const StarRow(this.rating, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: KbColors.orange500,
          size: 18,
        );
      }),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? bg;
  const StatTile(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      this.bg});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg ?? KbColors.orange200,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  size: 20,
                  color: bg == null
                      ? KbColors.orange700
                      : (bg == KbColors.redBg
                          ? KbColors.red
                          : bg == KbColors.amberBg
                              ? KbColors.amber
                              : KbColors.green)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: KbColors.ink)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: KbColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String text;
  const EmptyState({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 46)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KbColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class FutureListView<T> extends StatefulWidget {
  final Future<List<T>> Function() loader;
  final Widget Function(BuildContext, T) itemBuilder;
  const FutureListView(
      {super.key, required this.loader, required this.itemBuilder});

  @override
  State<FutureListView<T>> createState() => _FutureListViewState<T>();
}

class _FutureListViewState<T> extends State<FutureListView<T>> {
  late Future<List<T>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void reload() => setState(() => _future = widget.loader());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: KbColors.orange600),
          ));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('😕', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: KbColors.red)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: reload, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
              emoji: '🍽️', text: 'Nothing here yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (c, i) => widget.itemBuilder(c, items[i]),
        );
      },
    );
  }
}

Future<T> runWithLoading<T>(BuildContext context, Future<T> Function() fn) async {
  try {
    return await fn();
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    rethrow;
  }
}
