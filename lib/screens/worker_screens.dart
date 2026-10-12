import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shared_screens.dart';

void _open(BuildContext c, Widget w) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

// ============================================================ Nearby jobs
class WorkerNearby extends StatefulWidget {
  const WorkerNearby({super.key});
  @override
  State<WorkerNearby> createState() => _WorkerNearbyState();
}

class _WorkerNearbyState extends State<WorkerNearby> {
  int chip = 0;

  @override
  Widget build(BuildContext context) => Live((context) {
        final me = app.me;
        if (chip > me.categories.length) chip = 0;
        final cat = chip == 0 ? null : me.categories[chip - 1];
        final jobs = app.nearbyFor(cat);
        return PageFrame(
          eyebrow: 'Hi, ${me.name.split(' ').first}',
          title: 'Jobs near you',
          subtitle: '${me.categories.join(', ')} · within ${me.radiusKm.round()} km',
          bellFor: Role.worker,
          children: [
            if (me.verification != Verification.verified)
              const AppCard(
                color: Color(0xFFFFF6E5),
                borderColor: C.amber,
                child: Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: C.amber),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Your account is not verified yet. Jobs appear once an Admin approves your NID.')),
                ]),
              ),
            PillTabs(
                labels: ['All', ...me.categories],
                index: chip,
                onChanged: (i) => setState(() => chip = i)),
            if (jobs.isEmpty)
              const EmptyState(
                  icon: Icons.search_off_rounded,
                  text: 'No new jobs in your area right now. Check back soon.')
            else
              AdaptiveGrid(minWidth: 320, children: [
                for (final j in jobs)
                  AppCard(
                    onTap: () => _open(context, WorkerJobDetails(job: j)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(j.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
                          ),
                          SoftTag('${j.distanceKm} km'),
                        ]),
                        const SizedBox(height: 4),
                        Text('${j.category} · Posted ${j.postedAgo}',
                            style: const TextStyle(color: C.muted, fontSize: 13)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Text('Tk ${j.wage} offered',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: C.navy)),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                            onPressed: () => _open(context, WorkerJobDetails(job: j)),
                            child: const Text('View'),
                          ),
                        ]),
                      ],
                    ),
                  ),
              ]),
          ],
        );
      });
}

// ============================================================ Job details
class WorkerJobDetails extends StatefulWidget {
  final Job job;
  const WorkerJobDetails({super.key, required this.job});
  @override
  State<WorkerJobDetails> createState() => _WorkerJobDetailsState();
}

class _WorkerJobDetailsState extends State<WorkerJobDetails> {
  late final quote = TextEditingController(text: '${widget.job.wage}');

  @override
  void dispose() {
    quote.dispose();
    super.dispose();
  }

  void _send() {
    final q = int.tryParse(quote.text);
    if (q == null || q <= 0) {
      toast(context, 'Enter a valid quote');
      return;
    }
    app.sendRequest(widget.job, q);
    toast(context, q == widget.job.wage
        ? 'Request sent'
        : 'Counter-offer of Tk $q sent');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Live((context) {
        final j = widget.job;
        final mine = app.myOffer(j);
        return PageFrame(
          title: 'Job details',
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF4), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.image_outlined, size: 44, color: C.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(j.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: C.navy)),
                  const SizedBox(height: 4),
                  Text('${j.category} · ${j.distanceKm} km · Posted ${j.postedAgo}',
                      style: const TextStyle(color: C.muted)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 16, color: C.grey),
                    const SizedBox(width: 4),
                    Text(j.location, style: const TextStyle(color: C.muted)),
                  ]),
                  const SizedBox(height: 12),
                  Text(j.description.isEmpty ? 'No description provided.' : j.description),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Row(children: [
                      const Text("User's offered wage", style: TextStyle(color: C.muted)),
                      const Spacer(),
                      Text('Tk ${j.wage}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (mine != null)
                    AppCard(
                      color: C.softBlue,
                      borderColor: const Color(0xFFCFDDF6),
                      child: Text(
                          'You already sent a request for Tk ${mine.wage}. Status: ${mine.status.name}.',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
                    )
                  else ...[
                    const Text('Your quote (optional counter-offer)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: quote,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(prefixText: 'Tk '),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: j.status == JobStatus.pending ? _send : null,
                          child: const Text('Send request')),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        );
      });
}

// ============================================================ My jobs
class WorkerMyJobs extends StatefulWidget {
  const WorkerMyJobs({super.key});
  @override
  State<WorkerMyJobs> createState() => _WorkerMyJobsState();
}

class _WorkerMyJobsState extends State<WorkerMyJobs> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Live((context) {
        final list = switch (tab) {
          0 => app.workerRequested,
          1 => app.workerOngoing,
          _ => app.workerCompleted,
        };
        return PageFrame(
          title: 'My jobs',
          subtitle: 'Requests and job history',
          bellFor: Role.worker,
          children: [
            PillTabs(
                labels: const ['Requested', 'Ongoing', 'Completed'],
                index: tab,
                onChanged: (i) => setState(() => tab = i)),
            if (list.isEmpty)
              const EmptyState(text: 'Nothing here yet')
            else
              AdaptiveGrid(minWidth: 400, children: [
                for (final j in list) _row(context, j),
              ]),
          ],
        );
      });

  Widget _row(BuildContext context, Job j) {
    final o = app.myOffer(j);
    Widget tag;
    String sub;
    VoidCallback tap;
    if (tab == 0) {
      final declined = o?.status == OfferStatus.declined || j.workerName != null;
      tag = declined ? const StatusTag('Declined', C.red) : const StatusTag('Awaiting reply', C.amber);
      sub = '${j.category} · Tk ${o?.wage ?? j.wage} quoted';
      tap = () => _open(context, WorkerJobDetails(job: j));
    } else if (tab == 1) {
      tag = StatusTag(statusLabel(j.status), statusColor(j.status));
      sub = '${j.category} · ${j.owner} · Tk ${app.earned(j)}';
      tap = () => _open(context, CurrentJobScreen(job: j));
    } else {
      tag = const StatusTag('Completed', C.green);
      sub = '${j.category} · Tk ${app.earned(j)}';
      tap = () => _open(context, CompletedJobScreen(job: j));
    }
    return AppCard(
      onTap: tap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(j.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
          ),
          tag,
        ]),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: C.muted, fontSize: 13)),
      ]),
    );
  }
}

// ============================================================ Current job
class CurrentJobScreen extends StatelessWidget {
  final Job job;
  const CurrentJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) => Live((context) {
        final st = job.status;
        int s(int i) {
          final cur = st == JobStatus.assigned ? 0 : (st == JobStatus.inProgress ? 1 : 2);
          if (st == JobStatus.completed) return 2;
          return i < cur ? 2 : (i == cur ? 1 : 0);
        }

        return PageFrame(
          title: 'Current job',
          subtitle: job.title,
          children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: C.navy)),
                const SizedBox(height: 4),
                Text('${job.owner} · Tk ${app.earned(job)} · ${job.distanceKm} km',
                    style: const TextStyle(color: C.muted)),
                const SizedBox(height: 4),
                Text(job.location, style: const TextStyle(color: C.muted, fontSize: 13)),
              ]),
            ),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => toast(context, 'Opening maps to ${job.location}…'),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => toast(context, 'Calling ${job.owner}…'),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call user'),
                ),
              ),
            ]),
            AppCard(
              child: StatusTimeline([
                TimelineStep('Assigned', 'You accepted this job', s(0)),
                TimelineStep('In progress', 'Tap when you arrive on site', s(1)),
                TimelineStep('Completed', 'Mark the job done', s(2)),
              ]),
            ),
            if (st == JobStatus.assigned)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: C.blue),
                  onPressed: () {
                    app.startJob(job);
                    toast(context, 'Job started. The user can see you are on site.');
                  },
                  child: const Text("I've arrived: start job"),
                ),
              )
            else if (st == JobStatus.inProgress)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: C.blue),
                  onPressed: () async {
                    final ok = await confirmDialog(context,
                        title: 'Mark as complete?',
                        message: 'The user will be asked to rate your work.',
                        action: 'Mark complete');
                    if (ok && context.mounted) {
                      app.completeJob(job);
                      toast(context, 'Job completed. Earnings recorded.');
                    }
                  },
                  child: const Text('Mark as complete'),
                ),
              )
            else
              AppCard(
                color: const Color(0xFFEAF6F0),
                borderColor: C.green,
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: C.green),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Job completed. Find it under My jobs > Completed.')),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => CompletedJobScreen(job: job))),
                    child: const Text('View summary'),
                  ),
                ]),
              ),
          ],
        );
      });
}

// ============================================================ Completed job
class CompletedJobScreen extends StatelessWidget {
  final Job job;
  const CompletedJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) => Live((context) => PageFrame(
        title: 'Completed job',
        bellFor: Role.worker,
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: C.navy)),
              const SizedBox(height: 4),
              Text('${job.owner} · ${job.category}', style: const TextStyle(color: C.muted)),
              if (job.completedAt != null)
                Text('Completed · ${fmtDateTime(job.completedAt!)}',
                    style: const TextStyle(color: C.muted)),
            ]),
          ),
          DarkCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('You earned', style: TextStyle(color: C.onDarkMuted)),
              Text('Tk ${app.earned(job)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rating from ${job.owner.split(' ').first}',
                  style: const TextStyle(color: C.muted)),
              const SizedBox(height: 8),
              if (job.rating == null)
                const Text('Not rated yet', style: TextStyle(fontWeight: FontWeight.w600))
              else ...[
                StarRow(job.rating!.toDouble(), size: 28),
                if (job.review != null) ...[
                  const SizedBox(height: 8),
                  Text('"${job.review}"', style: const TextStyle(color: C.navy)),
                ],
              ],
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Job summary',
                  style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
              const SizedBox(height: 6),
              Text('Category: ${job.category}  ·  Distance: ${job.distanceKm} km',
                  style: const TextStyle(color: C.muted)),
            ]),
          ),
        ],
      ));
}

// ============================================================ Profile
class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Live((context) {
        final me = app.me;
        final (label, color) = switch (me.verification) {
          Verification.verified => ('Verified worker', C.green),
          Verification.pending => ('Verification pending', C.amber),
          Verification.rejected => ('Verification rejected', C.red),
        };
        return PageFrame(
          title: 'Profile',
          bellFor: Role.worker,
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Avatar(me.name, radius: 34),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(me.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
                      Text(me.phone, style: const TextStyle(color: C.muted)),
                      const SizedBox(height: 6),
                      StatusTag(label, color),
                    ]),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        foregroundColor: C.blue,
                        side: const BorderSide(color: C.blue)),
                    onPressed: () => showDialog<void>(
                        context: context, builder: (_) => const _WorkerEditDialog()),
                    child: const Text('Edit profile'),
                  ),
                ]),
              ]),
            ),
            AdaptiveGrid(minWidth: 240, children: [
              StatCard(
                  label: 'Average rating',
                  value: '${me.rating} ★',
                  icon: Icons.star_outline_rounded,
                  color: C.star),
              StatCard(
                  label: 'Jobs done',
                  value: '${me.jobsDone}',
                  icon: Icons.task_alt_rounded,
                  color: C.green),
              StatCard(
                  label: 'Service radius',
                  value: '${me.radiusKm.round()} km',
                  icon: Icons.radar_rounded),
            ]),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Expertise',
                    style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in me.categories)
                    Chip(
                        label: Text(c),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: C.border)),
                ]),
              ]),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(children: [
                  MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Earnings history',
                      onTap: () => _open(context, const EarningsScreen())),
                  const SizedBox(height: 10),
                  MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () => _open(context, const NotificationsScreen(role: Role.worker))),
                  const SizedBox(height: 10),
                  MenuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () => _open(context, const HelpScreen(role: Role.worker))),
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

class _WorkerEditDialog extends StatefulWidget {
  const _WorkerEditDialog();
  @override
  State<_WorkerEditDialog> createState() => _WorkerEditDialogState();
}

class _WorkerEditDialogState extends State<_WorkerEditDialog> {
  late final Set<String> cats = {...app.me.categories};
  late double radius = app.me.radiusKm;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Service categories', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in app.activeCategories)
                FilterChip(
                  label: Text(c.name),
                  selected: cats.contains(c.name),
                  onSelected: (v) => setState(() => v ? cats.add(c.name) : cats.remove(c.name)),
                ),
            ]),
            const SizedBox(height: 18),
            Text('Service radius: ${radius.round()} km',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              min: 1,
              max: 15,
              divisions: 14,
              value: radius,
              label: '${radius.round()} km',
              onChanged: (v) => setState(() => radius = v),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: cats.isEmpty
                ? null
                : () {
                    app.updateWorkerProfile(cats.toList(), radius);
                    Navigator.pop(context);
                  },
            child: const Text('Save'),
          ),
        ],
      );
}

// ============================================================ Earnings
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int tab = 1;

  @override
  Widget build(BuildContext context) => Live((context) {
        final list = app.earningsJobs(tab);
        final total = list.fold<int>(0, (a, j) => a + app.earned(j));
        const names = ['This week', 'This month', 'All time'];
        return PageFrame(
          title: 'Earnings history',
          bellFor: Role.worker,
          children: [
            DarkCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(names[tab], style: const TextStyle(color: C.onDarkMuted)),
                Text('Tk $total',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                Text('${list.length} jobs completed',
                    style: const TextStyle(color: C.onDarkMuted)),
              ]),
            ),
            PillTabs(labels: names, index: tab, onChanged: (i) => setState(() => tab = i)),
            if (list.isEmpty)
              const EmptyState(text: 'No earnings in this period')
            else
              for (final j in list)
                AppCard(
                  onTap: () => _open(context, CompletedJobScreen(job: j)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(j.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: C.navy)),
                        Text('${j.completedAt == null ? '' : '${fmtDate(j.completedAt!)} · '}${j.category}',
                            style: const TextStyle(color: C.muted, fontSize: 13)),
                      ]),
                    ),
                    Text('+ Tk ${app.earned(j)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: C.green)),
                  ]),
                ),
          ],
        );
      });
}
