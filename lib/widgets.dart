import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

String npr(num v) => v.toStringAsFixed(0);

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
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? KbColors.red : KbColors.ink,
    ));
}

/// In-your-eyes toast that slides in at the top-center instead of the bottom.
/// Auto-dismisses quickly and can be tapped to dismiss. Uses [Overlay] so it
/// shows above snapping bottom sheets and modals.
void showTopToast(BuildContext context, String msg,
    {bool error = false, IconData? icon, Color? color,
    int durationMs = 2500}) {
  final overlay = Overlay.of(context);
  final bg = color ??
      (error ? KbColors.red : KbColors.ink);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      msg: msg,
      icon: icon ?? (error ? Icons.error_outline : Icons.info_outline),
      color: bg,
      onDone: () => entry.remove(),
      durationMs: durationMs,
    ),
  );
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  final String msg;
  final IconData icon;
  final Color color;
  final VoidCallback onDone;
  final int durationMs;
  const _TopToast(
      {required this.msg, required this.icon, required this.color,
      required this.onDone, required this.durationMs});

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 240));
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, -1.2), end: Offset.zero)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  late final Animation<double> _fade = CurvedAnimation(
      parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(Duration(milliseconds: widget.durationMs), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _c.reverse().then((_) {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: mq.padding.top + 10,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: _c.isAnimating,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon,
                              color: Colors.white, size: 17),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(widget.msg,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a message in an [AlertDialog] so it is always in the foreground,
/// even when a modal bottom sheet is open (snack bars render behind sheets).
Future<void> showAppError(BuildContext context, String msg,
    {bool error = true}) {
  final color = error ? KbColors.red : KbColors.green;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(error ? Icons.error_outline : Icons.check_circle_outline,
          color: color, size: 34),
      title: Text(error ? 'Something went wrong' : 'Done',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: KbColors.inkSoft)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
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

/// Blinking "LIVE" dot used next to live queue/prep timings.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, this.color = KbColors.red, this.size = 9});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Comfy 3-stat timing strip for orders — queue / prep / total as separate
/// columns so it reads at a glance instead of one crammed line. The pulsing
/// dot + "ESTIMATED" header quietly signals that it refreshes live.
class LiveTimingChip extends StatelessWidget {
  final int queueWait;
  final int prepTime;
  final int totalTime;
  final bool compact;

  /// Booked/created at time used to compute a friendly "ready ~" time.
  final DateTime? start;
  const LiveTimingChip({
    super.key,
    required this.queueWait,
    required this.prepTime,
    required this.totalTime,
    this.compact = false,
    this.start,
  });

  String _fmt(DateTime dt, {required Duration add}) {
    final t = dt.add(add);
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    final active = totalTime > 0;
    final eta = start != null && active
        ? _fmt(start!, add: Duration(minutes: totalTime))
        : null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: KbColors.ivory100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active ? KbColors.orange200 : KbColors.ivory200),
      ),
      child: active
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PulsingDot(color: KbColors.orange600, size: compact ? 7 : 8),
                    const SizedBox(width: 6),
                    const Text('ESTIMATED',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: KbColors.inkSoft)),
                    const Spacer(),
                    if (eta != null)
                      Text('ready ~$eta',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: KbColors.orange700)),
                  ],
                ),
                SizedBox(height: compact ? 7 : 9),
                Row(
                  children: [
                    _TimingStat(
                        label: 'QUEUE', value: '~$queueWait min',
                        muted: queueWait <= 0, compact: compact),
                    _timingDiv(compact: compact),
                    _TimingStat(
                        label: 'PREP', value: '$prepTime min',
                        compact: compact),
                    _timingDiv(compact: compact),
                    _TimingStat(
                        label: 'TOTAL', value: '~$totalTime min',
                        highlight: true, compact: compact),
                  ],
                ),
              ],
            )
          : Text('No queue — order starts right away',
              style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: KbColors.inkSoft)),
    );
  }
}

Widget _timingDiv({bool compact = false}) {
  return Container(
    width: 1,
    height: compact ? 26 : 30,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: KbColors.orange200,
  );
}

class _TimingStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool muted;
  final bool compact;
  const _TimingStat(
      {required this.label, required this.value,
      this.highlight = false, this.muted = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final valColor = muted
        ? KbColors.inkFaint
        : highlight ? KbColors.orange700 : KbColors.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: KbColors.inkFaint)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: compact ? 12.5 : 14,
                fontWeight: FontWeight.w800,
                color: valColor)),
      ],
    );
  }
}

/// Emoji thumbnails + qty for the items in a booking, read from `itemsJson`.
/// Falls back to the plain summary text if the JSON is empty/unparseable.
class BookingItemThumbs extends StatelessWidget {
  final String itemsJson;
  final String fallback;
  final double thumbSize;
  const BookingItemThumbs(
      {super.key, required this.itemsJson,
      this.fallback = '', this.thumbSize = 34});

  static List<Map<String, dynamic>> _parse(String json) {
    try {
      final d = jsonDecode(json);
      if (d is List) {
        return d.whereType<Map>().cast<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _parse(itemsJson);
    if (items.isEmpty && fallback.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KbColors.ivory100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(fallback,
            style: const TextStyle(fontSize: 12.5, height: 1.4)),
      );
    }
    final shown = items.take(4).toList();
    final more = items.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final it in shown) _thumb(it, context),
            if (more > 0)
              Container(
                width: thumbSize,
                height: thumbSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KbColors.ivory200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+$more',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thumb(Map<String, dynamic> it, BuildContext context) {
    final qty = it['qty'] as int? ?? 1;
    final name = (it['name'] ?? '') as String;
    final emoji = (it['image'] ?? '🍽️') as String;
    return Tooltip(
      message: name,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: thumbSize,
            height: thumbSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KbColors.orange200.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: TextStyle(fontSize: thumbSize * 0.5)),
          ),
          if (qty > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: KbColors.orange700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('×$qty',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
