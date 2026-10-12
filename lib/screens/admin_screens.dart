import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_shell.dart';
import 'shared_screens.dart';

void _open(BuildContext c, Widget w) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

// ============================================================ Dashboard
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) => Live((context) {
        final go = ShellScope.of(context).goTo;
        return PageFrame(
          eyebrow: 'Hi, ${app.adminName}',
          title: 'Platform overview',
          children: [
            AdaptiveGrid(minWidth: 230, children: [
              StatCard(
                  label: 'Active users',
                  value: '${app.activeUsers}',
                  icon: Icons.people_outline_rounded),
              StatCard(
                  label: 'Verified workers',
                  value: '${app.verifiedWorkers}',
                  icon: Icons.verified_user_outlined,
                  color: C.green,
                  onTap: () => go(1)),
              StatCard(
                  label: 'Open jobs',
                  value: '${app.openJobs}',
                  icon: Icons.work_outline,
                  color: C.amber,
                  onTap: () => go(2)),
              StatCard(
                  label: 'Ongoing assignments',
                  value: '${app.ongoingAssignments}',
                  icon: Icons.sync_rounded,
                  onTap: () => go(2)),
            ]),
            const SectionTitle('Needs attention'),
            AdaptiveGrid(minWidth: 400, children: [
              AppCard(
                child: Row(children: [
                  const Icon(Icons.circle, size: 14, color: C.blue),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('${app.pendingVerifications} workers awaiting verification',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy))),
                  TextButton(onPressed: () => go(1), child: const Text('Review')),
                ]),
              ),
              AppCard(
                child: Row(children: [
                  const Icon(Icons.circle, size: 14, color: C.red),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('${app.openDisputes} disputes open',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy))),
                  TextButton(onPressed: () => go(3), child: const Text('Resolve')),
                ]),
              ),
            ]),
            const SectionTitle('Recent activity'),
            AppCard(
              child: Column(children: [
                for (int i = 0; i < app.activity.length && i < 8; i++) ...[
                  if (i > 0) const Divider(height: 22),
                  Row(children: [
                    const Icon(Icons.circle, size: 8, color: C.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text(app.activity[i].text)),
                    Text(app.activity[i].ago,
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                  ]),
                ],
              ]),
            ),
          ],
        );
      });
}

// ============================================================ Worker verification
class AdminWorkers extends StatefulWidget {
  const AdminWorkers({super.key});
  @override
  State<AdminWorkers> createState() => _AdminWorkersState();
}

class _AdminWorkersState extends State<AdminWorkers> {
  int tab = 0;
  static const _states = [Verification.pending, Verification.verified, Verification.rejected];

  @override
  Widget build(BuildContext context) => Live((context) {
        final list = app.workers.where((w) => w.verification == _states[tab]).toList();
        return PageFrame(
          title: 'Worker verification',
          subtitle: '${app.pendingVerifications} workers awaiting verification',
          children: [
            PillTabs(
                labels: const ['Pending', 'Verified', 'Rejected'],
                index: tab,
                onChanged: (i) => setState(() => tab = i)),
            if (list.isEmpty)
              const EmptyState(icon: Icons.verified_user_outlined, text: 'No workers in this list')
            else
              AdaptiveGrid(minWidth: 400, children: [
                for (final w in list) _card(context, w),
              ]),
          ],
        );
      });

  Widget _card(BuildContext context, WorkerProfile w) {
    final (label, color) = switch (w.verification) {
      Verification.pending => ('Pending', C.amber),
      Verification.verified => ('Verified', C.green),
      Verification.rejected => ('Rejected', C.red),
    };
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(w.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
              Text('${w.categories.join(', ')} · ${w.radiusKm.round()} km radius',
                  style: const TextStyle(color: C.muted, fontSize: 13)),
            ]),
          ),
          StatusTag(label, color),
        ]),
        const SizedBox(height: 14),
        const Text('NID document', style: TextStyle(color: C.muted, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(w.nidFile),
                content: const SizedBox(
                  width: 360,
                  height: 180,
                  child: Center(
                      child: Icon(Icons.badge_outlined, size: 80, color: C.grey)),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: C.bg, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.description_outlined, size: 16, color: C.blue),
                const SizedBox(width: 6),
                Text(w.nidFile, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          if (w.verification == Verification.pending) ...[
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
              onPressed: () {
                app.verifyWorker(w, true);
                toast(context, '${w.name} approved');
              },
              child: const Text('Approve'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
              onPressed: () {
                app.verifyWorker(w, false);
                toast(context, '${w.name} rejected');
              },
              child: const Text('Reject'),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ============================================================ Job monitoring
class AdminJobs extends StatefulWidget {
  const AdminJobs({super.key});
  @override
  State<AdminJobs> createState() => _AdminJobsState();
}

class _AdminJobsState extends State<AdminJobs> {
  String q = '';

  @override
  Widget build(BuildContext context) => Live((context) {
        final query = q.toLowerCase();
        final list = app.jobs
            .where((j) =>
                j.title.toLowerCase().contains(query) || j.category.toLowerCase().contains(query))
            .toList();
        return PageFrame(
          title: 'Job monitoring',
          subtitle: 'All job posts across the platform',
          children: [
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                  hintText: 'Search by job or category', prefixIcon: Icon(Icons.search_rounded)),
            ),
            if (list.isEmpty)
              const EmptyState(text: 'No jobs match your search')
            else
              AdaptiveGrid(minWidth: 400, children: [
                for (final j in list)
                  AppCard(
                    onTap: () {
                      final d = app.disputes.where((d) => d.job == j && !d.resolved).toList();
                      if (d.isNotEmpty) {
                        _open(context, DisputeDetailScreen(dispute: d.first));
                      } else {
                        _details(context, j);
                      }
                    },
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Flexible(
                              child: Text(j.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: C.navy)),
                            ),
                            if (app.hasOpenDispute(j)) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.error_rounded, color: C.red, size: 18),
                            ],
                          ]),
                          const SizedBox(height: 2),
                          Text('${j.category} · Tk ${j.wage} · ${j.owner}',
                              style: const TextStyle(color: C.muted, fontSize: 13)),
                        ]),
                      ),
                      StatusTag(statusLabel(j.status), statusColor(j.status)),
                    ]),
                  ),
              ]),
            const Text('A red icon marks jobs with an open dispute.',
                style: TextStyle(color: C.muted, fontSize: 12)),
          ],
        );
      });

  void _details(BuildContext context, Job j) => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(j.title),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Category: ${j.category}'),
              Text('Posted by: ${j.owner}'),
              Text('Worker: ${j.workerName ?? 'Not assigned'}'),
              Text('Wage: Tk ${j.agreedWage ?? j.wage}'),
              Text('Status: ${statusLabel(j.status)}'),
              Text('Offers: ${j.offers.length}'),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      );
}

// ============================================================ Disputes
class AdminDisputes extends StatelessWidget {
  const AdminDisputes({super.key});

  @override
  Widget build(BuildContext context) => Live((context) => PageFrame(
        title: 'Disputes queue',
        subtitle: '${app.openDisputes} open disputes',
        children: [
          if (app.disputes.isEmpty)
            const EmptyState(icon: Icons.gavel_outlined, text: 'No disputes')
          else
            AdaptiveGrid(minWidth: 400, children: [
              for (final d in app.disputes)
                AppCard(
                  onTap: () => _open(context, DisputeDetailScreen(dispute: d)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(d.job.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
                      ),
                      StatusTag(d.resolved ? 'Resolved' : 'Open', d.resolved ? C.green : C.red),
                    ]),
                    const SizedBox(height: 4),
                    Text('Raised by ${d.raisedBy} against ${d.against}',
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                    const SizedBox(height: 10),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text('View ›',
                            style: TextStyle(color: C.blue, fontWeight: FontWeight.w600))),
                  ]),
                ),
            ]),
        ],
      ));
}

class DisputeDetailScreen extends StatefulWidget {
  final Dispute dispute;
  const DisputeDetailScreen({super.key, required this.dispute});
  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  late final notes = TextEditingController(text: widget.dispute.notes);

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Live((context) {
        final d = widget.dispute;
        return PageFrame(
          title: 'Dispute detail',
          children: [
            AppCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.job.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: C.navy)),
                    const SizedBox(height: 4),
                    Text('Raised by ${d.raisedBy} (User)',
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                    Text('Against ${d.against} (Worker)',
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                  ]),
                ),
                StatusTag(d.resolved ? 'Resolved' : 'Open', d.resolved ? C.green : C.red),
              ]),
            ),
            const SectionTitle('Description'),
            AppCard(child: Text(d.description)),
            const SectionTitle('Resolution notes'),
            TextField(
              controller: notes,
              enabled: !d.resolved,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Add notes on how this was resolved…'),
            ),
            if (!d.resolved)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (notes.text.trim().isEmpty) {
                      toast(context, 'Please add resolution notes first');
                      return;
                    }
                    app.resolveDispute(d, notes.text.trim());
                    toast(context, 'Dispute marked as resolved');
                  },
                  child: const Text('Mark as resolved'),
                ),
              ),
          ],
        );
      });
}

// ============================================================ Categories
class AdminCategories extends StatelessWidget {
  const AdminCategories({super.key});

  @override
  Widget build(BuildContext context) => Live((context) => PageFrame(
        title: 'Manage categories',
        subtitle: 'Add, edit, or retire service categories',
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
          onPressed: () => showDialog<void>(
              context: context, builder: (_) => const _CategoryDialog()),
          icon: const Icon(Icons.add),
          label: const Text('Add category'),
        ),
        children: [
          AdaptiveGrid(minWidth: 400, children: [
            for (final c in app.categories)
              AppCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16, color: C.navy)),
                      Text(c.description,
                          style: const TextStyle(color: C.muted, fontSize: 13)),
                      const SizedBox(height: 8),
                      StatusTag(c.active ? 'Active' : 'Retired', c.active ? C.green : C.grey),
                    ]),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                        context: context, builder: (_) => _CategoryDialog(category: c)),
                    child: const Text('Edit ›'),
                  ),
                ]),
              ),
          ]),
          const Text(
              'Retiring a category keeps historical jobs intact. It only hides it from new jobs.',
              style: TextStyle(color: C.muted, fontSize: 12)),
        ],
      ));
}

class _CategoryDialog extends StatefulWidget {
  final ServiceCategory? category;
  const _CategoryDialog({this.category});
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final name = TextEditingController(text: widget.category?.name ?? '');
  late final desc = TextEditingController(text: widget.category?.description ?? '');
  late bool active = widget.category?.active ?? true;

  @override
  void dispose() {
    name.dispose();
    desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    return AlertDialog(
      title: Text(editing ? 'Edit category' : 'Add category'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
              controller: desc, decoration: const InputDecoration(labelText: 'Description')),
          if (editing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Turn off to retire this category'),
              value: active,
              onChanged: (v) => setState(() => active = v),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            final n = name.text.trim();
            if (n.isEmpty) return;
            if (editing) {
              app.updateCategory(widget.category!, n, desc.text.trim(), active);
            } else {
              app.addCategory(n, desc.text.trim());
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================ Profile
class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  @override
  Widget build(BuildContext context) => Live((context) {
        final go = ShellScope.of(context).goTo;
        return PageFrame(
          title: 'Profile',
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Avatar(app.adminName, radius: 34),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.adminName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
                    Text(app.adminPhone, style: const TextStyle(color: C.muted)),
                    Text(app.adminEmail, style: const TextStyle(color: C.muted)),
                  ]),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () =>
                      editProfileDialog(context, Role.admin, app.adminName, app.adminPhone),
                  child: const Text('Edit'),
                ),
              ]),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(children: [
                  MenuTile(
                      icon: Icons.category_outlined,
                      label: 'Manage categories',
                      onTap: () => go(4)),
                  const SizedBox(height: 10),
                  MenuTile(
                      icon: Icons.gavel_outlined, label: 'Disputes queue', onTap: () => go(3)),
                  const SizedBox(height: 10),
                  MenuTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Worker verification',
                      onTap: () => go(1)),
                  const SizedBox(height: 10),
                  MenuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () => _open(context, const HelpScreen(role: Role.admin))),
                  const SizedBox(height: 10),
                  MenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    danger: true,
                    onTap: () {
                      app.logout();
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                    },
                  ),
                ]),
              ),
            ),
          ],
        );
      });
}
