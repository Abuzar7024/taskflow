# TaskFlow

A lightweight, multi-tenant project management app built with Flutter. Users sign in to an
organization and manage its projects and tasks; every screen is scoped to the organization
they authenticated into.

The app runs against a bundled JSON file that stands in for a backend. There is no network
layer, but the repository interfaces are shaped so an HTTP implementation could replace the
mock one without touching the UI or business logic.

---

## Features

**Authentication & session**
- Splash screen that restores a stored session
- Login against the seeded accounts, with inline validation and a demo-account picker
- Registration that creates a local account and signs in
- Access + refresh tokens in secure storage, with transparent refresh and forced logout on expiry

**Projects**
- List, view, create, edit, and delete (admin only, with confirmation)
- Per-project task statistics and completion progress
- Task counts derived from live task rows, so they stay correct after mutations

**Tasks**
- List across the organization or per project
- Create, edit, delete, and change status, priority, assignee, and due date
- Filter by status, priority, assignee (including "Unassigned"), due-date range, and free text
- Sort by priority, due date, recency, or title
- Comments per task

**Platform behaviour**
- Simulated offline mode: cached data stays visible, mutations are blocked, staleness is labelled
- Six reviewer-triggerable error simulations
- Light and dark themes
- Bottom navigation on phones, a navigation rail on tablets

---

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.41+ (Dart 3.11+). Targets Android and iOS.

### Test credentials

All four accounts use the password `Password123!`.

| Email | Organization | Role |
|---|---|---|
| `ava.admin@nimbusdigital.test` | Nimbus Digital | Org admin |
| `marcus.member@nimbusdigital.test` | Nimbus Digital | Member |
| `daniel.admin@harborlightstudios.test` | Harborlight Studios | Org admin |
| `elena.member@harborlightstudios.test` | Harborlight Studios | Member |

The login screen's **Use a demo account** button lists these accounts and fills the form —
they are read from the mock data, never hardcoded in a widget.

Sign in as Ava and then as Daniel to see tenant isolation: the two accounts share no projects,
tasks, or teammates.

---

## Running the tests

```bash
flutter test                      # the full suite
flutter test test/unit            # unit tests only
flutter test test/widget          # widget tests only
flutter test test/integration     # end-to-end flows
flutter analyze                   # static analysis
```

175 tests covering session and token logic, authorization, filtering, validation, repository
behaviour, the loading/empty/error/success states, and end-to-end flows. No test touches a
real network.

> Widget and integration tests use `pump` with explicit durations rather than `pumpAndSettle`.
> The skeleton loaders animate continuously, so the frame loop never goes idle and
> `pumpAndSettle` would time out.

---

## Building a release APK

```bash
flutter build apk --release
```

This works on a fresh clone: with no keystore configured the release build falls back to the
debug signing keys. To sign with a real key, create `android/key.properties` (git-ignored):

```properties
storeFile=/absolute/path/to/keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

R8 code shrinking and resource shrinking are enabled for release builds.

---

## Error simulation

Everything below is reachable from **Profile → Developer tools**. The switches persist across
restarts, so remember to reset them.

| Switch | What to do | What you should see |
|---|---|---|
| **Offline mode** | Turn on, open Tasks or Projects | An offline banner with a "data from …" timestamp, the previously loaded list still visible, and a clear message if you try to save a change |
| **Slow network** | Turn on, pull to refresh | Skeleton loaders stay on screen long enough to inspect |
| **Network timeout** | Select, open Tasks | "The request took too long. Please try again." with a **Try again** button |
| **Server error (500)** | Select, open Tasks | "Something went wrong on our side." with retry |
| **Not found (404)** | Select, open any single task or project | "That task no longer exists." — list screens keep working, so you can navigate back |
| **Validation error** | Select, create or edit a task | The form shows a field-level error and a snackbar; reads still succeed |
| **Unauthorized (401)** | Select, open Tasks | The token-refresh path runs; because the mock refresh also returns 401, you are signed out with "Your session expired." |

To see an **empty state**, sign in as Daniel (Harborlight Studios) and delete its four tasks,
or apply a filter that matches nothing — the task list then offers a **Clear filters** action.

---

## Architecture at a glance

```
UI (widgets)
   ↓ watch / read
Riverpod providers & controllers   ← business logic, authorization, filtering
   ↓
Repositories (domain interfaces)   ← swappable: Mock… → Api…
   ↓
MockDataSource                     ← the bundled JSON, latency + failure simulation
   ↓
assets/data/mock_data.json
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full picture, and
[REQUIREMENTS.md](REQUIREMENTS.md) for the feature checklist.

### Folder structure

```
lib/
  core/
    constants/   dev/error-simulation settings
    errors/      the AppException hierarchy and user-facing messages
    router/      go_router configuration and auth redirects
    storage/     secure storage (tokens) and preferences (cache, settings)
    theme/       design tokens, light/dark themes, semantic colours
    utils/       date formatting, validators
  data/
    datasources/ MockDataSource — the fake backend
    models/      JSON ↔ entity mapping
    repositories/ repository implementations and the offline cache
  domain/
    entities/    Task, Project, Session, permissions, the task filter
    repositories/ repository interfaces
  presentation/
    auth/ dashboard/ projects/ tasks/ profile/ notifications/ shell/ widgets/
  app.dart
  main.dart
```

---

## Technical decisions

**Riverpod** for state management. Business logic lives in providers and controllers;
widgets handle layout, interaction, and rendering state. `main()` overrides the storage
providers, which is also how tests inject in-memory implementations.

**go_router** for navigation, with a single `redirect` that owns the auth rules. Authenticated
routes are unreachable when signed out because the redirect sends you to login — not because a
screen happens to pop.

**Authorization in business logic, not the UI.** `Permissions` holds the rules and the
repositories call its guards before every protected operation. A member calling
`projectRepository.delete(...)` directly is rejected with a `ForbiddenException` even though the
UI never renders the button for them. The same applies to cross-organization reads and to
assigning a user from another organization. This is covered by 22 tests in
`test/unit/authorization_test.dart`.

**Derived task counts.** `project.task_count` exists in the mock data and is consistent with the
seed rows, but it is recomputed from the live tasks at runtime so it stays correct after a task
is created or deleted.

**Extension-based JSON mapping** instead of a parallel set of model classes. The wire shape and
the domain shape are close enough that a second class hierarchy would be ceremony. Unknown enum
values throw a `FormatException` rather than silently defaulting — a backend that starts sending
a new status should fail loudly, not quietly mislabel data. The one exception is notification
type, which is display-only and degrades gracefully.

**A sealed `AppException` hierarchy** carrying user-facing messages. Widgets render
`messageFor(error)` and never see a raw exception string; a test asserts this.

**`MutationResult` rather than exceptions across the UI boundary.** Expected, recoverable
failures (validation, permission, offline) are returned so screens can show them inline without
wrapping every call in try/catch.

**Offline via a per-organization cache.** Successful list reads are written to preferences; when
a read fails the repository serves the cached copy, and the UI labels how old it is. Writes are
rejected outright while offline rather than queued — a sync queue is beyond the assignment's
scope and would need conflict resolution to be honest.

---

## Known limitations

- **Data is not durable.** Mutations live in the `MockDataSource`'s in-memory copy of the seed
  data and reset when the process restarts. Only the offline cache, tokens, and settings persist.
  A real backend would make this moot.
- **Registration always joins the first organization** as a member. The mock data has no
  invitation or org-creation flow to model anything richer.
- **"Manage members" is a permission, not a screen.** The rule is enforced and surfaced in the
  Profile screen, but there is no member-management UI — the mock data has no endpoint for it.
- **Tasks cannot move between projects.** The project field is fixed once a task exists.
- **Avatars are remote URLs** (`i.pravatar.cc`), so they will not load offline. Every avatar
  falls back to the user's initials.
- **The refresh token is a fixed string** in the mock data, so `refresh` accepts exactly that
  value. A real implementation would rotate it.

---

## Verification

`flutter analyze` reports no issues, `flutter test` passes all 175 tests, and
`flutter build apk --release` produces a signed APK.

The application was **not launched on a device or emulator** during development, so on-device
rendering, plugin behaviour at runtime, gesture feel, and real keyboard/rotation handling are
unverified. Widget tests assert that key screens lay out without overflow at several sizes,
which substitutes for — but does not equal — visual inspection. See the "Verification method
and limits" section of [REQUIREMENTS.md](REQUIREMENTS.md).
