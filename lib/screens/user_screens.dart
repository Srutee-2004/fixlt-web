import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_shell.dart';
import 'shared_screens.dart';

// ============================================================ Home
class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) => Live((context) {
        final mine = app.myJobs;
        final active = mine
            .where((j) =>
                j.status == JobStatus.pending ||
                j.status == JobStatus.assigned ||
                j.status == JobStatus.inProgress)
            .toList();
        final offers = mine
            .where((j) => j.status == JobStatus.pending)
            .fold<int>(0, (a, j) => a + j.pendingOffers);
        final done = mine.where((j) => j.status == JobStatus.completed).length;

        return PageFrame(
          eyebrow: 'Hi, ${app.userName.split(' ').first}',
          title: 'Need something fixed?',
          bellFor: Role.user,
          children: [
            const _PostCta(),
            AdaptiveGrid(minWidth: 240, children: [
              StatCard(label: 'Active jobs', value: '${active.length}', icon: Icons.work_outline),
              StatCard(
                  label: 'Offers waiting',
                  value: '$offers',
                  icon: Icons.local_offer_outlined,
                  color: C.amber),
              StatCard(
                  label: 'Completed',
                  value: '$done',
                  icon: Icons.check_circle_outline,
                  color: C.green),
            ]),
            const SectionTitle('Your active jobs'),
            if (active.isEmpty)
              const EmptyState(text: 'No active jobs yet. Post your first job!')
            else
              AdaptiveGrid(
                  minWidth: 400, children: [for (final j in active) UserJobCard(job: j)]),
          ],
        );
      });
}

class _PostCta extends StatelessWidget {
  const _PostCta();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [C.navy, Color(0xFF2B4A8B)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          spacing: 16,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Get it fixed today',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Post a job and receive offers from verified workers nearby.',
                    style: TextStyle(color: C.onDarkMuted)),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.navy),
              onPressed: () => ShellScope.of(context).goTo(1),
              icon: const Icon(Icons.add),
              label: const Text('Post a job'),
            ),
          ],
        ),
      );
}

class UserJobCard extends StatelessWidget {
  final Job job;
  const UserJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => JobStatusScreen(job: job))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
              ),
              jobTag(job),
            ]),
            const SizedBox(height: 6),
            Text('${job.category} · ${jobSubtitle(job)}',
                style: const TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(children: [
              Text('Tk ${job.agreedWage ?? job.wage}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
              const Spacer(),
              const Text('View details ›',
                  style: TextStyle(color: C.blue, fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      );
}

// ============================================================ Post a job
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _form = GlobalKey<FormState>();
  String? category;
  final desc = TextEditingController();
  final wage = TextEditingController(text: '500');
  final loc = TextEditingController();
  bool photo = false;

  @override
  void dispose() {
    desc.dispose();
    wage.dispose();
    loc.dispose();
    super.dispose();
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
      );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    app.postJob(
      category!,
      desc.text.trim(),
      int.parse(wage.text),
      loc.text.trim().isEmpty ? 'Sylhet (GPS)' : loc.text.trim(),
    );
    desc.clear();
    loc.clear();
    wage.text = '500';
    setState(() => photo = false);
    toast(context, 'Job posted. Nearby workers can now send offers.');
    ShellScope.of(context).goTo(2);
  }

  @override
  Widget build(BuildContext context) => Live((context) {
        final cats = app.activeCategories;
        if (cats.isEmpty) {
          return const PageFrame(
              title: 'Post a job',
              children: [EmptyState(text: 'No service categories are available right now.')]);
        }
        if (category == null || !cats.any((c) => c.name == category)) {
          category = cats.first.name;
        }
        return PageFrame(
          title: 'Post a job',
          subtitle: 'Tell workers what needs fixing',
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Category'),
                        DropdownButtonFormField<String>(
                          value: category,
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(value: c.name, child: Text(c.name)),
                          ],
                          onChanged: (v) => setState(() => category = v),
                        ),
                        _label('Description'),
                        TextFormField(
                          controller: desc,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'What needs fixing?'),
                          validator: (v) => (v == null || v.trim().length < 5)
                              ? 'Please describe the problem (min 5 characters)'
                              : null,
                        ),
                        _label('Photo (optional)'),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => photo = !photo),
                          child: Container(
                            height: 90,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: photo ? C.softBlue : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: photo ? C.blue : C.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(photo ? Icons.image_rounded : Icons.add_a_photo_outlined,
                                    color: photo ? C.blue : C.grey),
                                const SizedBox(height: 6),
                                Text(photo ? 'photo_1.jpg attached (tap to remove)' : 'Add a photo',
                                    style: const TextStyle(color: C.muted)),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Offered wage'),
                                  TextFormField(
                                    controller: wage,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(prefixText: 'Tk '),
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      return (n == null || n <= 0) ? 'Enter a valid wage' : null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Location'),
                                  TextFormField(
                                    controller: loc,
                                    decoration: InputDecoration(
                                      hintText: 'Address or use GPS',
                                      suffixIcon: IconButton(
                                        tooltip: 'Use GPS',
                                        icon: const Icon(Icons.my_location_rounded),
                                        onPressed: () =>
                                            loc.text = 'Zindabazar, Sylhet (GPS)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(onPressed: _submit, child: const Text('Post job')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      });
}

// ============================================================ My jobs
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});
  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Live((context) {
        final mine = app.myJobs;
        final list = mine.where((j) {
          switch (tab) {
            case 0:
              return j.status == JobStatus.pending ||
                  j.status == JobStatus.assigned ||
                  j.status == JobStatus.inProgress;
            case 1:
              return j.status == JobStatus.completed;
            default:
              return j.status == JobStatus.cancelled;
          }
        }).toList();
        return PageFrame(
          title: 'My jobs',
          subtitle: 'Everything you have posted',
          bellFor: Role.user,
          children: [
            PillTabs(
                labels: const ['Ongoing', 'Completed', 'Cancelled'],
                index: tab,
                onChanged: (i) => setState(() => tab = i)),
            if (list.isEmpty)
              const EmptyState(text: 'Nothing here yet')
            else
              AdaptiveGrid(
                  minWidth: 400, children: [for (final j in list) UserJobCard(job: j)]),
          ],
        );
      });
}

// ============================================================ Track & rate
class JobStatusScreen extends StatelessWidget {
  final Job job;
  const JobStatusScreen({super.key, required this.job});

  List<TimelineStep> _steps() {
    final cur = switch (job.status) {
      JobStatus.pending => 0,
      JobStatus.assigned => 1,
      JobStatus.inProgress => 2,
      JobStatus.completed => 3,
      JobStatus.cancelled => 0,
    };
    int st(int i) => job.status == JobStatus.completed ? 2 : (i < cur ? 2 : (i == cur ? 1 : 0));
    return [
      TimelineStep('Pending', 'Job posted', st(0)),
      TimelineStep('Assigned',
          job.workerName == null ? 'Waiting for a worker' : '${job.workerName} accepted the job', st(1)),
      TimelineStep('In progress', 'Worker is on site', st(2)),
      TimelineStep('Completed', 'Job finished', st(3)),
    ];
  }

  @override
  Widget build(BuildContext context) => Live((context) {
        final cancelled = job.status == JobStatus.cancelled;
        return PageFrame(
          title: 'Job status',
          subtitle: job.title,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(job.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: C.navy)),
                    ),
                    jobTag(job),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                      '${job.category} · ${job.workerName ?? 'No worker yet'} · Tk ${job.agreedWage ?? job.wage}',
                      style: const TextStyle(color: C.muted)),
                  if (job.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(job.description),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 16, color: C.grey),
                    const SizedBox(width: 4),
                    Text(job.location, style: const TextStyle(color: C.muted, fontSize: 13)),
                  ]),
                ],
              ),
            ),
            if (cancelled)
              const EmptyState(icon: Icons.cancel_outlined, text: 'This job was cancelled.')
            else
              AppCard(child: StatusTimeline(_steps())),
            if (job.status == JobStatus.pending)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${job.pendingOffers} offers received',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
                    const SizedBox(height: 4),
                    Text(
                        job.pendingOffers == 0
                            ? 'Waiting for nearby workers to send offers.'
                            : 'Review each worker and pick the best fit.',
                        style: const TextStyle(color: C.muted)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      FilledButton(
                        onPressed: job.pendingOffers == 0
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => OffersScreen(job: job))),
                        child: const Text('View offers'),
                      ),
                      OutlinedButton(
                        onPressed: job.pendingOffers == 0
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CompareWorkersScreen(job: job))),
                        child: const Text('Compare workers'),
                      ),
                    ]),
                  ],
                ),
              ),
            if (!cancelled) _RateBox(job: job),
            Wrap(spacing: 12, runSpacing: 12, children: [
                if (job.status == JobStatus.pending || job.status == JobStatus.assigned)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: C.red, side: const BorderSide(color: C.red)),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel job'),
                    onPressed: () async {
                      final ok = await confirmDialog(context,
                          title: 'Cancel this job?',
                          message: 'Workers will be notified and the job moves to Cancelled.',
                          action: 'Cancel job',
                          danger: true);
                      if (ok && context.mounted) {
                        app.cancelJob(job);
                        toast(context, 'Job cancelled');
                      }
                    },
                  ),
                if (job.workerName != null && job.status != JobStatus.cancelled)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report a problem'),
                    onPressed: () async {
                      final t = await askTextDialog(context,
                          title: 'Report a problem',
                          hint: 'Describe what went wrong…',
                          action: 'Send to admin');
                      if (t != null && context.mounted) {
                        app.raiseDispute(job, t);
                        toast(context, 'Dispute sent. An admin will review it.');
                      }
                    },
                  ),
              ]),
          ],
        );
      });
}

class _RateBox extends StatefulWidget {
  final Job job;
  const _RateBox({required this.job});
  @override
  State<_RateBox> createState() => _RateBoxState();
}

class _RateBoxState extends State<_RateBox> {
  int stars = 0;
  final review = TextEditingController();

  @override
  void dispose() {
    review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    if (j.rating != null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your rating',
                style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
            const SizedBox(height: 8),
            StarRow(j.rating!.toDouble(), size: 26),
            if (j.review != null) ...[
              const SizedBox(height: 8),
              Text('"${j.review}"', style: const TextStyle(color: C.muted)),
            ],
          ],
        ),
      );
    }
    final ready = j.status == JobStatus.completed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ready ? 'Rate ${j.workerName}' : 'Rate this job once it\'s done',
              style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
          const SizedBox(height: 8),
          Opacity(
            opacity: ready ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !ready,
              child: StarInput(value: stars, onChanged: (v) => setState(() => stars = v)),
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            TextField(
              controller: review,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Leave a short review (optional)'),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            child: FilledButton(
              onPressed: (ready && stars > 0)
                  ? () {
                      app.rateJob(j, stars, review.text);
                      toast(context, 'Thanks! Your rating was submitted.');
                    }
                  : null,
              child: const Text('Submit rating'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Compare workers
class CompareWorkersScreen extends StatefulWidget {
  final Job job;
  const CompareWorkersScreen({super.key, required this.job});
  @override
  State<CompareWorkersScreen> createState() => _CompareWorkersScreenState();
}

class _CompareWorkersScreenState extends State<CompareWorkersScreen> {
  int sort = 0;

  Future<void> _select(Offer o) async {
    final ok = await confirmDialog(context,
        title: 'Hire ${o.workerName}?',
        message: 'The job will be assigned to ${o.workerName} for Tk ${o.wage}.',
        action: 'Select');
    if (ok && mounted) {
      app.acceptOffer(widget.job, o);
      toast(context, '${o.workerName} has been assigned.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => Live((context) {
        final offers =
            widget.job.offers.where((o) => o.status == OfferStatus.pending).toList();
        offers.sort((a, b) => switch (sort) {
              0 => b.rating.compareTo(a.rating),
              1 => a.distanceKm.compareTo(b.distanceKm),
              _ => a.wage.compareTo(b.wage),
            });
        return PageFrame(
          title: 'Choose a worker',
          subtitle: '${widget.job.title} · ${offers.length} offers',
          children: [
            PillTabs(
                labels: const ['Best rated', 'Nearest', 'Lowest price'],
                index: sort,
                onChanged: (i) => setState(() => sort = i)),
            if (offers.isEmpty)
              const EmptyState(text: 'No pending offers for this job.')
            else
              AdaptiveGrid(minWidth: 300, children: [
                for (final o in offers)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Avatar(o.workerName, radius: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.workerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, color: C.navy, fontSize: 16)),
                                Row(children: [
                                  StarRow(o.rating, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${o.rating}',
                                      style: const TextStyle(color: C.muted, fontSize: 13)),
                                ]),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Favorite',
                            onPressed: () => app.toggleFavorite(o.workerName),
                            icon: Icon(
                                app.favorites.contains(o.workerName)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: C.red),
                          ),
                        ]),
                        const Divider(height: 24),
                        _kv('Completed jobs', '${o.jobsDone}'),
                        _kv('Distance', '${o.distanceKm} km'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            const Text('Quoted wage', style: TextStyle(color: C.muted)),
                            const Spacer(),
                            if (o.counter) ...[const SoftTag('counter'), const SizedBox(width: 8)],
                            Text('Tk ${o.wage}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, color: C.navy)),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () => _select(o), child: const Text('Select')),
                        ),
                      ],
                    ),
                  ),
              ]),
          ],
        );
      });

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(k, style: const TextStyle(color: C.muted)),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
        ]),
      );
}

// ============================================================ Offers received
class OffersScreen extends StatelessWidget {
  final Job job;
  const OffersScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) => Live((context) {
        final offers = job.offers.where((o) => o.status == OfferStatus.pending).toList();
        return PageFrame(
          title: 'Offers received',
          subtitle: job.title,
          trailing: TextButton.icon(
            onPressed: offers.isEmpty
                ? null
                : () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => CompareWorkersScreen(job: job))),
            icon: const Icon(Icons.compare_arrows_rounded),
            label: const Text('Compare'),
          ),
          children: [
            if (offers.isEmpty)
              const EmptyState(text: 'No pending offers for this job.')
            else
              for (final o in offers)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Avatar(o.workerName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.workerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, color: C.navy)),
                              Text('★ ${o.rating} · ${o.distanceKm} km',
                                  style: const TextStyle(color: C.muted, fontSize: 13)),
                              Text('Offer: Tk ${o.wage}${o.counter ? ' (counter)' : ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: C.navy)),
                            ],
                          ),
                        ),
                        Wrap(spacing: 8, children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () {
                              app.declineOffer(job, o);
                              toast(context, 'Offer declined');
                            },
                            child: const Text('Decline'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () {
                              app.acceptOffer(job, o);
                              toast(context, '${o.workerName} has been assigned.');
                              Navigator.of(context).pop();
                            },
                            child: const Text('Accept'),
                          ),
                        ]),
                      ]),
                    ],
                  ),
                ),
          ],
        );
      });
}

// ============================================================ Profile
class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) => Live((context) => PageFrame(
        title: 'Profile',
        bellFor: Role.user,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Avatar(app.userName, radius: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.userName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
                    Text(app.userPhone, style: const TextStyle(color: C.muted)),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40), foregroundColor: C.blue,
                    side: const BorderSide(color: C.blue)),
                onPressed: () => editProfileDialog(context, Role.user, app.userName, app.userPhone),
                child: const Text('Edit profile'),
              ),
            ]),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(children: [
                MenuTile(
                    icon: Icons.work_outline,
                    label: 'My jobs',
                    onTap: () => ShellScope.of(context).goTo(2)),
                const SizedBox(height: 10),
                MenuTile(
                    icon: Icons.payments_outlined,
                    label: 'Payment history',
                    onTap: () => _push(context, const PaymentHistoryScreen())),
                const SizedBox(height: 10),
                MenuTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => _push(context, const NotificationsScreen(role: Role.user))),
                const SizedBox(height: 10),
                MenuTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorite workers',
                    onTap: () => _push(context, const FavoritesScreen())),
                const SizedBox(height: 10),
                MenuTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _push(context, const SettingsScreen())),
                const SizedBox(height: 10),
                MenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & support',
                    onTap: () => _push(context, const HelpScreen(role: Role.user))),
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
      ));
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Live((context) {
        final paid = app.myJobs.where((j) => j.status == JobStatus.completed).toList();
        final total = paid.fold<int>(0, (a, j) => a + app.earned(j));
        return PageFrame(
          title: 'Payment history',
          subtitle: 'Cash payments on completion',
          children: [
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total spent', style: TextStyle(color: C.onDarkMuted)),
                  Text('Tk $total',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('${paid.length} completed jobs',
                      style: const TextStyle(color: C.onDarkMuted)),
                ],
              ),
            ),
            if (paid.isEmpty)
              const EmptyState(text: 'No payments yet')
            else
              for (final j in paid)
                AppCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(j.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: C.navy)),
                          Text(
                              '${j.completedAt == null ? '' : '${fmtDate(j.completedAt!)} · '}${j.workerName} · Cash',
                              style: const TextStyle(color: C.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('Tk ${app.earned(j)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
                  ]),
                ),
          ],
        );
      });
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => Live((context) {
        final favs = app.favorites.toList();
        return PageFrame(
          title: 'Favorite workers',
          subtitle: 'Workers you trust',
          children: [
            if (favs.isEmpty)
              const EmptyState(
                  icon: Icons.favorite_border_rounded,
                  text: 'Tap the heart on a worker while comparing offers to save them here.')
            else
              for (final n in favs)
                AppCard(
                  child: Row(children: [
                    Avatar(n),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: C.navy)),
                          if (app.findOffer(n) != null)
                            Text(
                                '★ ${app.findOffer(n)!.rating} · ${app.findOffer(n)!.jobsDone} jobs',
                                style: const TextStyle(color: C.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => app.toggleFavorite(n),
                      icon: const Icon(Icons.favorite_rounded, color: C.red),
                    ),
                  ]),
                ),
          ],
        );
      });
}
