# TaskFlow

**Modern project & task management for teams.**

A multi-tenant Flutter application where users sign in to an organization and manage its
projects and tasks. Every screen is scoped to the organization the user authenticated into.

The app runs against a bundled JSON file that stands in for a backend. There is no network
layer, but the repository interfaces are shaped so an HTTP implementation could replace the
mock one without touching the UI or the business logic.

---

## Features

**Authentication & session**
- Splash screen that restores a stored session
- Login against the seeded accounts, with inline validation and a demo-account picker
- Registration that creates a local account and signs in
- Access + refresh tokens in secure storage, with transparent refresh and forced logout on expiry

**Projects**
- List, view, create, edit, and delete (admin only, with confirmation)
- Search and sort; per-project statistics, progress and member avatars
- Task counts derived from live task rows, so they stay correct after mutations

**Tasks**
- List across the organization or per project
- Create, edit, delete, and change status, priority, assignee, and due date
- Filter by status, priority, assignee (including "Unassigned"), due-date range, and free text
- Comments per task

**Workspace**
- Dashboard with an overview, assigned work, recent projects and upcoming deadlines
- Notifications inbox with unread badge, deep-linking to the relevant task
- Profile with grouped Account, Workspace, Preferences and Security sections
- Members directory showing each teammate's role

**Platform behaviour**
- Simulated offline mode: cached data stays visible, mutations are blocked, staleness is labelled
- Six reviewer-triggerable error simulations
- Light and dark themes that follow the device, with a manual override
- Bottom navigation on phones; an adaptive rail on tablets

---

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.41 · Dart 3.11 |
| State management | Riverpod |
| Navigation | go_router |
| Secure storage | flutter_secure_storage (tokens, session) |
| Local storage | shared_preferences (cache, settings) |
| Value equality | equatable |
| Dates | intl |

---

## Architecture

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

The presentation layer depends only on the repository interfaces, so the mock implementations
could be swapped for HTTP-backed ones without touching the UI or the business logic.

### Project structure

```
lib/
  core/
    constants/   dev/error-simulation settings
    errors/      the AppException hierarchy and user-facing messages
    router/      go_router configuration and auth redirects
    storage/     secure storage (tokens) and preferences (cache, settings)
    theme/       app_colors, app_typography, app_spacing, app_radius, app_theme
    utils/       date formatting, validators
  data/
    datasources/ MockDataSource — the fake backend
    models/      JSON ↔ entity mapping
    repositories/ repository implementations and the offline cache
  domain/
    entities/    Task, Project, Session, permissions, the task filter
    repositories/ repository interfaces
  presentation/
    auth/ dashboard/ projects/ tasks/ notifications/ profile/ shell/ widgets/
  app.dart
  main.dart
```

---

## Theme system

A blue + cream identity with **no gradients** — flat, deliberate colour.

Light and dark palettes are authored independently rather than one being an inversion of the
other, so contrast, surfaces and hierarchy stay intentional in both. Widgets never check
brightness: they read semantic roles through a `ThemeExtension`.

```dart
final c = Theme.of(context).c;   // canvas, surface, border, text, primary, success…
Container(color: c.surface, child: Text('Hi', style: theme.textTheme.titleMedium));
```

| Token file | Holds |
|---|---|
| `app_colors.dart` | Palette + `AppColorRoles` theme extension |
| `app_typography.dart` | The type scale |
| `app_spacing.dart` | An 8px spacing scale |
| `app_radius.dart` | Corner radii |
| `app_theme.dart` | Light and dark `ThemeData`, component themes, motion |

The app defaults to `ThemeMode.system`, so it follows the device; Profile → Theme overrides it.

### Component system

`AppCard`, `AppChip`, `AppAvatar`, `AppAvatarStack`, `AppProgressBar`, `AppSectionHeader`,
`AppIconTile`, `AppSection`, `AppSettingsTile`, `AppChoiceTile`, `AppBottomNav`, `AppNavRail`,
`EmptyState`, `ErrorStateView`, `SkeletonCard`/`SkeletonList`, `AppIllustration`.

Illustrations are drawn on canvas rather than shipped as image assets, so they scale cleanly,
follow the theme, and add nothing to the bundle.

---

## Setup

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

These are fixtures for a mock backend, not real credentials. The login screen's **Use a demo
account** button lists them and fills the form — they are read from the mock data, never
hardcoded in a widget.

Sign in as Ava and then as Daniel to see tenant isolation: the two accounts share no projects,
tasks, or teammates.

---

## Testing

```bash
flutter test                      # the full suite
flutter test test/unit            # unit tests only
flutter test test/widget          # widget tests only
flutter test test/integration     # end-to-end flows
flutter analyze                   # static analysis
```

203 tests covering session and token logic, authorization and tenant isolation, filtering,
search, validation, repository behaviour, the loading/empty/error/success states, and
end-to-end flows, plus responsive checks that assert no overflow on a small phone, a large
phone, a tablet and in landscape. No test touches a real network.

> Widget and integration tests use `pump` with explicit durations rather than `pumpAndSettle`.
> The skeleton loaders animate continuously, so the frame loop never goes idle and
> `pumpAndSettle` would time out.

---

## Building an APK

```bash
flutter build apk --release
```

This works on a fresh clone: with no keystore configured the release build falls back to the
debug signing keys. To sign with a real key, create `android/key.properties` — git-ignored, and
never committed:

```properties
storeFile=/absolute/path/to/keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

R8 code shrinking and resource shrinking are enabled for release builds.

---

## Mock data

`assets/data/mock_data.json` is the fake backend: 2 organizations, 5 users, 3 projects,
15 tasks, comments, notifications and the auth fixtures. It is loaded once as a Flutter asset
and parsed in the data layer — never read from a widget.

`MockDataSource` holds the parsed data in memory and applies mutations to it, so changes
survive navigation for the life of the process. Every call passes through one `_simulate`
helper that applies artificial latency and any failure the reviewer has switched on.

### Error simulation

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
or search for a project that does not exist.

---

## Technical decisions

**Riverpod** for state management. Business logic lives in providers and controllers; widgets
handle layout, interaction, and rendering state. `main()` overrides the storage providers,
which is also how tests inject in-memory implementations.

**go_router** with a single `redirect` that owns the auth rules. Authenticated routes are
unreachable when signed out because the redirect sends you to login — not because a screen
happens to pop.

**Authorization in business logic, not the UI.** `Permissions` holds the rules and the
repositories call its guards before every protected operation. A member calling
`projectRepository.delete(...)` directly is rejected with a `ForbiddenException` even though
the UI never renders the button for them. The same applies to cross-organization reads and to
assigning a user from another organization.

**Derived task counts.** `project.task_count` exists in the mock data, but is recomputed from
the live tasks at runtime so it stays correct after a task is created or deleted.

**A sealed `AppException` hierarchy** carrying user-facing messages. Widgets render
`messageFor(error)` and never see a raw exception string; a test asserts this.

**`MutationResult` rather than exceptions across the UI boundary.** Expected, recoverable
failures (validation, permission, offline) are returned so screens can show them inline.

**Offline via a per-organization cache.** Successful list reads are written to preferences;
when a read fails the repository serves the cached copy and the UI labels how old it is.
Writes are rejected outright while offline rather than queued — a sync queue is beyond scope
and would need conflict resolution to be honest.

---

## Known limitations

- **Data is not durable.** Mutations live in `MockDataSource`'s in-memory copy of the seed data
  and reset when the process restarts. Only the offline cache, tokens and settings persist.
- **Profile details are read-only.** The mock backend has no update endpoint, so the account
  screen states that rather than offering a field that cannot save.
- **Registration always joins the first organization** as a member; the mock data has no
  invitation flow.
- **Tasks cannot move between projects.** The project is fixed once a task exists.
- **Avatars are remote URLs** (`i.pravatar.cc`) and will not load offline; every avatar falls
  back to the user's initials.
- **Seed dates are in the past**, so most open tasks legitimately report as overdue.

---

## Verification

`flutter analyze` reports no issues, `flutter test` passes all 203 tests, and
`flutter build apk --release` produces an APK.

The app has been run on a physical device (Samsung Galaxy S24, Android 16): login, session
restore, dashboard, project and task lists, task detail and the profile/settings screens all
render and resolve correctly, with no runtime exceptions in logcat.

Not verified on real hardware: tablet and landscape layouts, iOS, and the full matrix of
simulated error states. Layout at those sizes is asserted by the responsive test suite rather
than by manual device testing.
