<<<<<<< HEAD
# fixlt-web
=======
# FixIt - Flutter Web Demo (User · Worker · Admin)

On-demand, location-aware marketplace connecting Users with verified local Workers.
Built from the FixIt project proposal and the three Screen Design Reports.
Student-friendly demo: **no backend, no extra packages**. All data lives in memory.

## 1. Run it (5 steps)

```bash
# 1) Install Flutter (https://docs.flutter.dev/get-started/install), then check:
flutter doctor
flutter config --enable-web

# 2) Create a web project shell
flutter create fixit_web --platforms web
cd fixit_web

# 3) Remove the default demo code, then copy this project's files in
#    - delete the folder  test/
#    - delete the folder  lib/   (then copy THIS project's lib/ folder in its place)
#    - replace pubspec.yaml with this project's pubspec.yaml

# 4) Fetch packages
flutter pub get

# 5) Run in Chrome
flutter run -d chrome
```

Build for hosting: `flutter build web` (output in `build/web`).

## 2. Project structure

```
lib/
├── main.dart                 App entry, theme, routes
├── theme.dart                Colours + Material 3 theme
├── models.dart               Job, Offer, WorkerProfile, Dispute, Category, ...
├── app_state.dart            In-memory "backend": seed data + all actions
├── router.dart               Builds navigation for each role
├── widgets/
│   ├── common.dart           Cards, tags, stars, timeline, dialogs, notifications
│   └── role_shell.dart       Sidebar (desktop) / bottom bar (mobile) layout
└── screens/
    ├── login_screen.dart     Role picker + sign in
    ├── user_screens.dart     Home, Post job, My jobs, Track & rate, Compare, Offers, Profile...
    ├── worker_screens.dart   Nearby, Job details, My jobs, Current job, Completed, Profile, Earnings
    ├── admin_screens.dart    Dashboard, Verification, Jobs, Disputes, Categories, Profile
    └── shared_screens.dart   Help & support, Settings
```

## 3. Demo script for your supervisor (about 3 minutes)

1. **Admin**: Workers tab -> approve "Rafiul K."; open Disputes -> write notes -> "Mark as resolved"; Categories -> add/retire.
2. **Log out -> Worker (Srutee)**: Nearby -> open "Leaking kitchen tap" -> change quote to Tk 450 (counter-offer) -> Send request.
   My jobs -> Ongoing -> "Ceiling fan not spinning" -> Start job -> Mark as complete.
3. **Log out -> User (Nadia)**: bell shows new offers. My jobs -> "Leaking kitchen tap" -> Compare workers -> Select.
   Open "Ceiling fan" -> rate the worker.
4. **Back to Worker**: notifications show the rating; Earnings history updates.

## 4. Mapping to the proposal

| Proposal feature | Where |
|---|---|
| Post job (category, photo, wage, GPS) | User -> Post a job |
| Compare workers by rating / jobs / distance | User -> Compare workers |
| Counter-offer | Worker -> Job details -> quote field |
| Pending -> Assigned -> In progress -> Completed | Track screen + Current job |
| Mandatory rating + feedback | User -> Track & rate |
| NID verification queue | Admin -> Workers |
| Category management (retire, not delete) | Admin -> Categories |
| Dispute resolution | Admin -> Disputes |
| Live platform counts | Admin -> Dashboard |

## 5. Next steps toward the real system (Supabase)

1. Create tables: profiles, worker_profiles, categories, job_posts, job_requests, assignments, ratings, disputes.
2. Add `supabase_flutter`, replace `AppState` methods with Supabase queries (keep the same method names).
3. Auth (email/phone OTP) + Row Level Security per role.
4. Real GPS (`geolocator`) and distance filtering with PostGIS.
5. Image upload for job photos and NID (Supabase Storage).
>>>>>>> 04cfab0 (fixit initial commit)
