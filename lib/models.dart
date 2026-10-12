enum Role { user, worker, admin }

enum JobStatus { pending, assigned, inProgress, completed, cancelled }

enum OfferStatus { pending, accepted, declined }

enum Verification { pending, verified, rejected }

String statusLabel(JobStatus s) => switch (s) {
      JobStatus.pending => 'Pending',
      JobStatus.assigned => 'Assigned',
      JobStatus.inProgress => 'In progress',
      JobStatus.completed => 'Completed',
      JobStatus.cancelled => 'Cancelled',
    };

/// A worker's request / counter-offer on a job.
class Offer {
  final String workerName;
  final double rating;
  final int jobsDone;
  final double distanceKm;
  final int wage;
  final bool counter;
  OfferStatus status;

  Offer({
    required this.workerName,
    required this.rating,
    required this.jobsDone,
    required this.distanceKm,
    required this.wage,
    this.counter = false,
    this.status = OfferStatus.pending,
  });
}

/// A job post (job_posts table in the proposal's schema).
class Job {
  final String id;
  final String owner;
  String title;
  String category;
  String description;
  String location;
  String postedAgo;
  int wage;
  double distanceKm;
  JobStatus status;
  final List<Offer> offers;
  String? workerName;
  int? agreedWage;
  int? rating;
  String? review;
  DateTime? completedAt;

  Job({
    required this.id,
    required this.owner,
    required this.title,
    required this.category,
    this.description = '',
    required this.wage,
    this.location = 'Sylhet',
    this.postedAgo = 'just now',
    this.distanceKm = 1.0,
    this.status = JobStatus.pending,
    List<Offer>? offers,
    this.workerName,
    this.agreedWage,
    this.rating,
    this.review,
    this.completedAt,
  }) : offers = offers ?? [];

  int get pendingOffers =>
      offers.where((o) => o.status == OfferStatus.pending).length;
}

/// worker_profiles table.
class WorkerProfile {
  final String name;
  String phone;
  List<String> categories;
  double radiusKm;
  Verification verification;
  double rating;
  int jobsDone;
  final String nidFile;

  WorkerProfile({
    required this.name,
    this.phone = '+880 1XX-XXXXXXX',
    required this.categories,
    required this.radiusKm,
    this.verification = Verification.pending,
    this.rating = 0,
    this.jobsDone = 0,
    this.nidFile = 'national_id.pdf',
  });
}

class Dispute {
  final String id;
  final Job job;
  final String raisedBy;
  final String against;
  final String description;
  bool resolved;
  String notes;

  Dispute({
    required this.id,
    required this.job,
    required this.raisedBy,
    required this.against,
    required this.description,
    this.resolved = false,
    this.notes = '',
  });
}

class ServiceCategory {
  String name;
  String description;
  bool active;
  ServiceCategory(this.name, this.description, {this.active = true});
}

class AppNotification {
  final String title;
  final String body;
  bool unread;
  AppNotification(this.title, this.body, {this.unread = true});
}

class Activity {
  final String text;
  final String ago;
  Activity(this.text, this.ago);
}
