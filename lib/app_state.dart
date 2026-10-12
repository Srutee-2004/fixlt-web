import 'package:flutter/foundation.dart';
import 'models.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String fmtDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]}, $h:$m $ap';
}

/// Single in-memory "backend" shared by all three roles.
/// Everything a role does here is visible to the other roles, which lets you
/// demo the full lifecycle: post -> request -> assign -> start -> complete -> rate.
class AppState extends ChangeNotifier {
  static const userShort = 'Nadia I.';

  Role? role;
  String userName = 'Nadia Islam';
  String userPhone = '+880 1XXX-XXXXXX';
  String adminName = 'Admin';
  String adminPhone = '+880 1700-000000';
  final String adminEmail = 'admin@fixit.app';

  final List<Job> jobs = [];
  final List<WorkerProfile> workers = [];
  final List<Dispute> disputes = [];
  final List<ServiceCategory> categories = [];
  final List<Activity> activity = [];
  final Set<String> favorites = {'Mizan I.'};
  final Map<Role, List<AppNotification>> notifications = {
    Role.user: [],
    Role.worker: [],
    Role.admin: [],
  };

  late final WorkerProfile me; // the logged-in demo worker
  int _n = 100;

  AppState() {
    _seed();
  }

  // ---------------------------------------------------------------- session
  void login(Role r) {
    role = r;
    notifyListeners();
  }

  void logout() {
    role = null;
    notifyListeners();
  }

  void refresh() => notifyListeners();

  // ---------------------------------------------------------------- queries
  List<ServiceCategory> get activeCategories => categories.where((c) => c.active).toList();

  List<Job> get myJobs => jobs.where((j) => j.owner == userShort).toList();

  Offer? myOffer(Job j) {
    for (final o in j.offers) {
      if (o.workerName == me.name) return o;
    }
    return null;
  }

  Offer? findOffer(String worker) {
    for (final j in jobs) {
      for (final o in j.offers) {
        if (o.workerName == worker) return o;
      }
    }
    return null;
  }

  List<Job> nearbyFor(String? cat) {
    if (me.verification != Verification.verified) return [];
    final list = jobs
        .where((j) =>
            j.status == JobStatus.pending &&
            me.categories.contains(j.category) &&
            j.distanceKm <= me.radiusKm &&
            myOffer(j) == null &&
            (cat == null || j.category == cat))
        .toList();
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  /// Jobs the worker requested but is NOT assigned to.
  List<Job> get workerRequested =>
      jobs.where((j) => myOffer(j) != null && j.workerName != me.name).toList();

  List<Job> get workerOngoing => jobs
      .where((j) =>
          j.workerName == me.name &&
          (j.status == JobStatus.assigned || j.status == JobStatus.inProgress))
      .toList();

  List<Job> get workerCompleted => jobs
      .where((j) => j.workerName == me.name && j.status == JobStatus.completed)
      .toList()
    ..sort((a, b) => (b.completedAt ?? DateTime(2000)).compareTo(a.completedAt ?? DateTime(2000)));

  /// period: 0 = this week, 1 = this month, 2 = all time
  List<Job> earningsJobs(int period) {
    final now = DateTime.now();
    return workerCompleted.where((j) {
      final d = j.completedAt;
      if (d == null) return false;
      if (period == 0) return now.difference(d).inDays < 7;
      if (period == 1) return now.difference(d).inDays < 30;
      return true;
    }).toList();
  }

  int earned(Job j) => j.agreedWage ?? j.wage;

  bool hasOpenDispute(Job j) => disputes.any((d) => d.job == j && !d.resolved);
  int get openDisputes => disputes.where((d) => !d.resolved).length;
  int get pendingVerifications =>
      workers.where((w) => w.verification == Verification.pending).length;

  // Dashboard figures: seeded baseline + live changes made during the demo.
  int get activeUsers => 342;
  int get verifiedWorkers =>
      117 + workers.where((w) => w.verification == Verification.verified).length;
  int get openJobs => 24 + jobs.where((j) => j.status == JobStatus.pending).length;
  int get ongoingAssignments =>
      9 +
      jobs
          .where((j) => j.status == JobStatus.assigned || j.status == JobStatus.inProgress)
          .length;

  int unread(Role r) => notifications[r]!.where((n) => n.unread).length;

  // ---------------------------------------------------------------- actions
  void _notify(Role r, String title, String body) =>
      notifications[r]!.insert(0, AppNotification(title, body));

  void _log(String text) => activity.insert(0, Activity(text, 'just now'));

  void markAllRead(Role r) {
    for (final n in notifications[r]!) {
      n.unread = false;
    }
    notifyListeners();
  }

  void toggleFavorite(String worker) {
    favorites.contains(worker) ? favorites.remove(worker) : favorites.add(worker);
    notifyListeners();
  }

  // --- User
  void postJob(String category, String description, int wage, String location) {
    final j = Job(
      id: 'j${_n++}',
      owner: userShort,
      title: description.length > 32 ? '${description.substring(0, 32).trim()}…' : description,
      category: category,
      description: description,
      wage: wage,
      location: location,
      distanceKm: 0.8,
    );
    jobs.insert(0, j);
    _log('$userShort posted "${j.title}"');
    notifyListeners();
  }

  void acceptOffer(Job j, Offer o) {
    for (final x in j.offers) {
      x.status = identical(x, o) ? OfferStatus.accepted : OfferStatus.declined;
    }
    j.status = JobStatus.assigned;
    j.workerName = o.workerName;
    j.agreedWage = o.wage;
    if (o.workerName == me.name) {
      _notify(Role.worker, 'Job assigned to you', 'You were selected for ${j.title}');
    } else if (myOffer(j) != null) {
      _notify(Role.worker, 'Offer declined', '${j.owner} chose another worker for ${j.title}');
    }
    _log('${j.owner} assigned ${o.workerName} to "${j.title}"');
    notifyListeners();
  }

  void declineOffer(Job j, Offer o) {
    o.status = OfferStatus.declined;
    if (o.workerName == me.name) {
      _notify(Role.worker, 'Offer declined', '${j.owner} declined your offer for ${j.title}');
    }
    notifyListeners();
  }

  void cancelJob(Job j) {
    j.status = JobStatus.cancelled;
    if (j.workerName == me.name) {
      _notify(Role.worker, 'Job cancelled', '${j.owner} cancelled ${j.title}');
    }
    _log('"${j.title}" was cancelled');
    notifyListeners();
  }

  void rateJob(Job j, int stars, String review) {
    j.rating = stars;
    j.review = review.trim().isEmpty ? null : review.trim();
    if (j.workerName == me.name) {
      me.rating = double.parse(((me.rating * 9 + stars) / 10).toStringAsFixed(1));
      _notify(Role.worker, 'New rating', '${j.owner} rated your work $stars stars');
    }
    notifyListeners();
  }

  void raiseDispute(Job j, String text) {
    disputes.insert(
      0,
      Dispute(
        id: 'd${_n++}',
        job: j,
        raisedBy: j.owner,
        against: j.workerName ?? 'Unassigned',
        description: text,
      ),
    );
    _log('Dispute opened on "${j.title}"');
    notifyListeners();
  }

  // --- Worker
  void sendRequest(Job j, int quote) {
    j.offers.add(Offer(
      workerName: me.name,
      rating: me.rating,
      jobsDone: me.jobsDone,
      distanceKm: j.distanceKm,
      wage: quote,
      counter: quote != j.wage,
    ));
    if (j.owner == userShort) {
      _notify(Role.user, 'New offer received', '${me.name} sent Tk $quote for ${j.title}');
    }
    _log('${me.name} sent a request on "${j.title}"');
    notifyListeners();
  }

  void startJob(Job j) {
    j.status = JobStatus.inProgress;
    if (j.owner == userShort) {
      _notify(Role.user, 'Worker is on site', '${j.workerName} started ${j.title}');
    }
    notifyListeners();
  }

  void completeJob(Job j) {
    j.status = JobStatus.completed;
    j.completedAt = DateTime.now();
    if (j.workerName == me.name) me.jobsDone++;
    if (j.owner == userShort) {
      _notify(Role.user, 'Job completed', 'Please rate ${j.workerName} for ${j.title}');
    }
    _notify(Role.worker, 'Payment received', 'Tk ${earned(j)} (cash) recorded for ${j.title}');
    _log('"${j.title}" marked completed');
    notifyListeners();
  }

  void updateWorkerProfile(List<String> cats, double radius) {
    me.categories = cats;
    me.radiusKm = radius;
    notifyListeners();
  }

  // --- Admin
  void verifyWorker(WorkerProfile w, bool approve) {
    w.verification = approve ? Verification.verified : Verification.rejected;
    _log('${w.name} was ${approve ? 'verified' : 'rejected'}');
    notifyListeners();
  }

  void resolveDispute(Dispute d, String notes) {
    d.resolved = true;
    d.notes = notes;
    _log('Dispute on "${d.job.title}" resolved');
    notifyListeners();
  }

  void addCategory(String name, String desc) {
    categories.add(ServiceCategory(name, desc));
    notifyListeners();
  }

  void updateCategory(ServiceCategory c, String name, String desc, bool active) {
    c.name = name;
    c.description = desc;
    c.active = active;
    notifyListeners();
  }

  void updateProfile(Role r, String name, String phone) {
    if (r == Role.user) {
      userName = name;
      userPhone = phone;
    } else if (r == Role.admin) {
      adminName = name;
      adminPhone = phone;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------- seed
  DateTime _d(int days) => DateTime.now().subtract(Duration(days: days));

  void _seed() {
    categories.addAll([
      ServiceCategory('Plumbing', 'Taps, pipes, drainage'),
      ServiceCategory('Electrical', 'Wiring, fixtures, appliances'),
      ServiceCategory('Carpentry', 'Furniture, doors, fittings'),
      ServiceCategory('Cleaning', 'Home & office cleaning'),
      ServiceCategory('Painting', 'Interior & exterior painting'),
      ServiceCategory('Pest control', 'Discontinued category', active: false),
    ]);

    me = WorkerProfile(
      name: 'Srutee A.',
      phone: '+880 1XX-XXXXXXX',
      categories: ['Plumbing', 'Electrical'],
      radiusKm: 5,
      verification: Verification.verified,
      rating: 4.8,
      jobsDone: 37,
    );
    workers.addAll([
      me,
      WorkerProfile(name: 'Rafiul K.', categories: ['Electrical', 'Plumbing'], radiusKm: 5),
      WorkerProfile(name: 'Shompa D.', categories: ['Cleaning'], radiusKm: 8),
      WorkerProfile(name: 'Imran H.', categories: ['Carpentry'], radiusKm: 3),
    ]);

    jobs.addAll([
      Job(
        id: 'j1',
        owner: userShort,
        title: 'Leaking kitchen tap',
        category: 'Plumbing',
        description:
            'Tap under the kitchen sink has been dripping for two days, getting worse. Needs a look and likely a washer replacement.',
        wage: 500,
        location: 'Zindabazar, Sylhet',
        postedAgo: '2h ago',
        distanceKm: 0.8,
        offers: [
          Offer(workerName: 'Karim R.', rating: 4.8, jobsDone: 41, distanceKm: 1.2, wage: 500),
          Offer(workerName: 'Sohel H.', rating: 4.5, jobsDone: 23, distanceKm: 2.0, wage: 450, counter: true),
          Offer(workerName: 'Mizan I.', rating: 4.9, jobsDone: 57, distanceKm: 0.8, wage: 500),
        ],
      ),
      Job(
        id: 'j2',
        owner: userShort,
        title: 'Ceiling fan not spinning',
        category: 'Electrical',
        description: 'Ceiling fan in the bedroom makes a humming noise but does not spin.',
        wage: 400,
        location: 'Ambarkhana, Sylhet',
        postedAgo: '5h ago',
        distanceKm: 2.1,
        status: JobStatus.assigned,
        workerName: 'Srutee A.',
        agreedWage: 400,
        offers: [
          Offer(workerName: 'Srutee A.', rating: 4.8, jobsDone: 37, distanceKm: 2.1, wage: 400, status: OfferStatus.accepted),
        ],
      ),
      Job(
        id: 'j3',
        owner: userShort,
        title: 'AC gas refill',
        category: 'Electrical',
        description: 'Split AC is not cooling. Needs gas refill and a quick check.',
        wage: 650,
        location: 'Subid Bazar, Sylhet',
        postedAgo: '1d ago',
        distanceKm: 3.4,
        status: JobStatus.assigned,
        workerName: 'Rafiul K.',
        agreedWage: 650,
        offers: [
          Offer(workerName: 'Rafiul K.', rating: 4.6, jobsDone: 19, distanceKm: 3.4, wage: 650, status: OfferStatus.accepted),
        ],
      ),
      Job(
        id: 'j4',
        owner: userShort,
        title: 'Water pump repair',
        category: 'Plumbing',
        wage: 500,
        distanceKm: 0.8,
        status: JobStatus.completed,
        workerName: 'Srutee A.',
        agreedWage: 500,
        rating: 5,
        review: 'Quick and tidy work, fixed it in 20 minutes.',
        completedAt: _d(2),
      ),
      Job(
        id: 'j5',
        owner: 'Tania R.',
        title: 'Switchboard rewiring',
        category: 'Electrical',
        wage: 400,
        distanceKm: 1.9,
        status: JobStatus.completed,
        workerName: 'Srutee A.',
        agreedWage: 400,
        rating: 4,
        review: 'Good work, a little late.',
        completedAt: _d(4),
      ),
      Job(
        id: 'j6',
        owner: 'Farhan A.',
        title: 'Split AC servicing',
        category: 'Electrical',
        wage: 650,
        distanceKm: 2.7,
        status: JobStatus.completed,
        workerName: 'Srutee A.',
        agreedWage: 650,
        rating: 5,
        review: 'Very professional.',
        completedAt: _d(9),
      ),
      Job(
        id: 'j7',
        owner: userShort,
        title: 'Bathroom light wiring',
        category: 'Electrical',
        wage: 300,
        distanceKm: 1.0,
        status: JobStatus.completed,
        workerName: 'Srutee A.',
        agreedWage: 300,
        rating: 5,
        review: 'Neat finish.',
        completedAt: _d(14),
      ),
      Job(
        id: 'j8',
        owner: 'Kamal U.',
        title: 'Geyser repair',
        category: 'Plumbing',
        wage: 800,
        distanceKm: 3.0,
        status: JobStatus.completed,
        workerName: 'Srutee A.',
        agreedWage: 800,
        rating: 4,
        review: 'Fixed, but took a while.',
        completedAt: _d(45),
      ),
      Job(
        id: 'j9',
        owner: 'Tania R.',
        title: 'Clogged bathroom drain',
        category: 'Plumbing',
        description: 'Bathroom floor drain is blocked and water is not draining.',
        wage: 350,
        location: 'Mirabazar, Sylhet',
        postedAgo: '40m ago',
        distanceKm: 1.6,
        offers: [
          Offer(workerName: 'Srutee A.', rating: 4.8, jobsDone: 37, distanceKm: 1.6, wage: 350),
        ],
      ),
      Job(
        id: 'j10',
        owner: 'Farhan A.',
        title: 'Faulty wall socket',
        category: 'Electrical',
        description: 'Wall socket in the study room sparks when plugged in.',
        wage: 300,
        postedAgo: '3h ago',
        distanceKm: 2.4,
        offers: [
          Offer(workerName: 'Srutee A.', rating: 4.8, jobsDone: 37, distanceKm: 2.4, wage: 300, status: OfferStatus.declined),
        ],
      ),
      Job(
        id: 'j11',
        owner: 'Kamal U.',
        title: 'Switchboard sparking',
        category: 'Electrical',
        description: 'Main switchboard sparks when the AC turns on. Urgent.',
        wage: 600,
        postedAgo: '12m ago',
        distanceKm: 2.9,
      ),
      Job(
        id: 'j12',
        owner: 'Kamal U.',
        title: 'Water line extension',
        category: 'Plumbing',
        description: 'Extend a water line to the new rooftop tank.',
        wage: 1200,
        postedAgo: '1h ago',
        distanceKm: 7.5,
      ),
      Job(
        id: 'j13',
        owner: 'Kamal U.',
        title: 'Wall painting job',
        category: 'Painting',
        wage: 2200,
        distanceKm: 4.2,
        status: JobStatus.assigned,
        workerName: 'Imran H.',
        agreedWage: 2200,
      ),
      Job(
        id: 'j14',
        owner: 'Tania R.',
        title: 'AC servicing',
        category: 'Electrical',
        wage: 800,
        distanceKm: 3.1,
        status: JobStatus.cancelled,
        workerName: 'Shompa D.',
      ),
      Job(
        id: 'j15',
        owner: 'Farhan A.',
        title: 'Broken door lock',
        category: 'Carpentry',
        wage: 400,
        distanceKm: 1.4,
        status: JobStatus.completed,
        workerName: 'Rafiul K.',
        agreedWage: 400,
        completedAt: _d(6),
      ),
      Job(
        id: 'j16',
        owner: userShort,
        title: 'Old wall paint touch-up',
        category: 'Painting',
        wage: 1200,
        distanceKm: 0.8,
        status: JobStatus.cancelled,
      ),
    ]);

    Job byId(String id) => jobs.firstWhere((j) => j.id == id);
    disputes.addAll([
      Dispute(
        id: 'd1',
        job: byId('j13'),
        raisedBy: 'Kamal U.',
        against: 'Imran H.',
        description: 'User says the paint job was left unfinished and the worker left the site early without notice.',
      ),
      Dispute(
        id: 'd2',
        job: byId('j14'),
        raisedBy: 'Tania R.',
        against: 'Shompa D.',
        description: 'Worker did not show up at the agreed time and stopped answering calls.',
      ),
      Dispute(
        id: 'd3',
        job: byId('j15'),
        raisedBy: 'Farhan A.',
        against: 'Rafiul K.',
        description: 'Lock was replaced with a different model than agreed.',
        resolved: true,
        notes: 'Worker refunded the price difference. Closed.',
      ),
    ]);

    activity.addAll([
      Activity('Rafiul K. submitted NID for verification', '12 min ago'),
      Activity('Dispute opened on "Wall painting job"', '40 min ago'),
      Activity('"Water pump repair" marked completed', '1 hr ago'),
    ]);

    notifications[Role.user]!.addAll([
      AppNotification('New offer received', 'Mizan I. sent Tk 500 for Leaking kitchen tap'),
      AppNotification('Worker accepted', 'Srutee A. will fix Ceiling fan not spinning', unread: false),
    ]);
    notifications[Role.worker]!.addAll([
      AppNotification('Job assigned to you', 'You were selected for Ceiling fan not spinning'),
      AppNotification('Offer declined', 'Farhan A. declined your offer for Faulty wall socket'),
      AppNotification('Payment received', 'Tk 500 (cash) recorded for Water pump repair', unread: false),
      AppNotification('New rating', 'Nadia rated your work 5 stars', unread: false),
    ]);
  }
}

final AppState app = AppState();
