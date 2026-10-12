import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

// ------------------------------------------------------------------ helpers
Color statusColor(JobStatus s) => switch (s) {
      JobStatus.pending => C.amber,
      JobStatus.assigned || JobStatus.inProgress => C.blue,
      JobStatus.completed => C.green,
      JobStatus.cancelled => C.grey,
    };

Widget jobTag(Job j) {
  if (j.status == JobStatus.pending && j.pendingOffers > 0) {
    return StatusTag('${j.pendingOffers} offers', C.blue);
  }
  return StatusTag(statusLabel(j.status), statusColor(j.status));
}

String jobSubtitle(Job j) => switch (j.status) {
      JobStatus.pending => 'Posted ${j.postedAgo}',
      JobStatus.assigned => '${j.workerName} accepted',
      JobStatus.inProgress => 'Worker on site',
      JobStatus.completed => 'Completed',
      JobStatus.cancelled => 'Cancelled',
    };

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ));
}

/// Rebuilds whenever the shared app state changes.
class Live extends StatelessWidget {
  final WidgetBuilder builder;
  const Live(this.builder, {super.key});
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: app, builder: (c, _) => builder(c));
}

// ------------------------------------------------------------------ layout
class PageFrame extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Role? bellFor;
  final Widget? trailing;
  final List<Widget> children;

  const PageFrame({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.bellFor,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              children: [
                Row(
                  children: [
                    if (canPop)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null)
                            Text(eyebrow!, style: const TextStyle(color: C.muted, fontSize: 14)),
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800, color: C.navy)),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(subtitle!, style: const TextStyle(color: C.muted)),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                    if (bellFor != null) BellButton(role: bellFor!),
                  ],
                ),
                const SizedBox(height: 20),
                for (final c in children) ...[c, const SizedBox(height: 16)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double spacing;
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minWidth = 300,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      int cols = ((box.maxWidth + spacing) / (minWidth + spacing)).floor();
      if (cols < 1) cols = 1;
      if (cols > 6) cols = 6;
      final w = (box.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    });
  }
}

// ------------------------------------------------------------------ atoms
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? C.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DarkCard extends StatelessWidget {
  final Widget child;
  const DarkCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

class StatusTag extends StatelessWidget {
  final String text;
  final Color color;
  const StatusTag(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class SoftTag extends StatelessWidget {
  final String text;
  const SoftTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: C.softBlue, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(color: C.blue, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class Avatar extends StatelessWidget {
  final String name;
  final double radius;
  const Avatar(this.name, {super.key, this.radius = 22});
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: C.softBlue,
      child: Text(initials,
          style: TextStyle(color: C.blue, fontWeight: FontWeight.w800, fontSize: radius * 0.7)),
    );
  }
}

class StarRow extends StatelessWidget {
  final double value;
  final double size;
  const StarRow(this.value, {super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 5; i++)
            Icon(i < value.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size, color: i < value.round() ? C.star : const Color(0xFFCBD0D8)),
        ],
      );
}

class StarInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarInput({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= 5; i++)
            InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38, color: i <= value ? C.star : const Color(0xFFCBD0D8)),
              ),
            ),
        ],
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.navy)),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, this.icon = Icons.inbox_outlined, required this.text});
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: C.grey),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = C.blue,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: C.navy)),
                  Text(label, style: const TextStyle(color: C.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}

class MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const MenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: danger ? C.red : C.navy, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: danger ? C.red : C.navy)),
            ),
            if (!danger) const Icon(Icons.chevron_right_rounded, color: C.grey),
          ],
        ),
      );
}

class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PillTabs({super.key, required this.labels, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < labels.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: i == index ? C.navy : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: i == index ? C.navy : C.border),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: i == index ? Colors.white : C.muted)),
              ),
            ),
        ],
      );
}

// ------------------------------------------------------------------ timeline
class TimelineStep {
  final String title;
  final String sub;
  final int state; // 0 todo, 1 current, 2 done
  const TimelineStep(this.title, this.sub, this.state);
}

class StatusTimeline extends StatelessWidget {
  final List<TimelineStep> steps;
  const StatusTimeline(this.steps, {super.key});

  Widget _dot(int state, int n) {
    if (state == 2) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
      );
    }
    if (state == 1) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: C.blue, shape: BoxShape.circle),
        child: Text('$n',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: C.border, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 26,
                  child: Column(
                    children: [
                      _dot(steps[i].state, i + 1),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: steps[i].state == 2 ? C.green : C.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: steps[i].state == 0 ? C.grey : C.navy)),
                        Text(steps[i].sub,
                            style: const TextStyle(color: C.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ dialogs
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Confirm',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: danger ? C.red : C.navy, minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askTextDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String action = 'Submit',
}) {
  return showDialog<String>(
    context: context,
    builder: (c) => _TextDialog(title: title, hint: hint, action: action),
  );
}

class _TextDialog extends StatefulWidget {
  final String title, hint, action;
  const _TextDialog({required this.title, required this.hint, required this.action});
  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 420,
          child: TextField(
              controller: _c, maxLines: 4, decoration: InputDecoration(hintText: widget.hint)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () {
              final t = _c.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(context, t);
            },
            child: Text(widget.action),
          ),
        ],
      );
}

Future<void> editProfileDialog(BuildContext context, Role role, String name, String phone) {
  return showDialog<void>(
    context: context,
    builder: (c) => _EditProfileDialog(role: role, name: name, phone: phone),
  );
}

class _EditProfileDialog extends StatefulWidget {
  final Role role;
  final String name, phone;
  const _EditProfileDialog({required this.role, required this.name, required this.phone});
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _n = TextEditingController(text: widget.name);
  late final _p = TextEditingController(text: widget.phone);
  @override
  void dispose() {
    _n.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _n, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _p, decoration: const InputDecoration(labelText: 'Phone')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () {
              if (_n.text.trim().isNotEmpty) {
                app.updateProfile(widget.role, _n.text.trim(), _p.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
}

// ------------------------------------------------------------------ notifications
class BellButton extends StatelessWidget {
  final Role role;
  const BellButton({super.key, required this.role});
  @override
  Widget build(BuildContext context) => Live((context) {
        final n = app.unread(role);
        return Stack(
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NotificationsScreen(role: role))),
              icon: const Icon(Icons.notifications_none_rounded, size: 28, color: C.navy),
            ),
            if (n > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: C.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5)),
                ),
              ),
          ],
        );
      });
}

class NotificationsScreen extends StatelessWidget {
  final Role role;
  const NotificationsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) => Live((context) {
        final list = app.notifications[role]!;
        return PageFrame(
          title: 'Notifications',
          subtitle: '${app.unread(role)} unread',
          trailing: TextButton(
              onPressed: () => app.markAllRead(role), child: const Text('Mark all read')),
          children: [
            if (list.isEmpty)
              const EmptyState(icon: Icons.notifications_off_outlined, text: 'No notifications yet')
            else
              for (final n in list)
                AppCard(
                  color: n.unread ? C.softBlue : Colors.white,
                  borderColor: n.unread ? const Color(0xFFCFDDF6) : C.border,
                  onTap: () {
                    n.unread = false;
                    app.refresh();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: C.navy)),
                            const SizedBox(height: 2),
                            Text(n.body, style: const TextStyle(color: C.muted)),
                          ],
                        ),
                      ),
                      if (n.unread)
                        const Icon(Icons.circle, size: 10, color: C.red),
                    ],
                  ),
                ),
          ],
        );
      });
}
