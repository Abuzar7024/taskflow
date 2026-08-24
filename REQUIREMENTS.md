# TaskFlow — Requirements & Completion Checklist

Derived from the TaskFlow technical assignment and `assets/data/mock_data.json`.
This document is the completion checklist for the project.

Status legend: `[x]` implemented and code-reviewed · `[ ]` not done · `[~]` partial

---

## 1. Product Overview

TaskFlow is a lightweight, multi-tenant project-management mobile app. A user logs in,
lands in an organization, and manages projects and tasks belonging to that organization.
Every user sees only the data of the organization they authenticated into.

The app runs against a bundled JSON file acting as a fake backend. There is no real
network layer, but the repository interfaces are shaped so an HTTP implementation could
replace the mock one without touching business logic or UI.

---

## 2. Data Model (from mock data — verified, not assumed)

| Entity | Count | Key fields |
|---|---|---|
| `organizations` | 2 | `id`, `name`, `created_at` |
| `users` | 5 | `id`, `name`, `email`, `avatar_url` |
| `org_members` | 5 | `org_id`, `user_id`, `role` |
| `projects` | 3 | `id`, `org_id`, `name`, `description`, `task_count`, `status`, `created_at` |
| `tasks` | 15 | `id`, `project_id`, `title`, `description`, `status`, `priority`, `assignee_id` (nullable), `due_date`, `created_at` |
| `comments` | 4 | `id`, `task_id`, `author_id`, `body`, `created_at` |
| `notifications` | 3 | `id`, `user_id`, `type`, `task_id`, `message`, `read`, `created_at` |
| `auth_mock` | — | `test_credentials[]`, `mock_login_response` |

Enumerations present in the data:

- Task status: `todo`, `in_progress`, `review`, `done`
- Task priority: `low`, `medium`, `high`, `urgent`
- Project status: `active` (only value present; `archived` supported by the model)
- Role: `org_admin`, `member`

Relationships: `project.org_id → organization.id`, `task.project_id → project.id`,
`task.assignee_id → user.id` (nullable), `comment.task_id → task.id`,
`comment.author_id → user.id`, `notification.user_id → user.id`.

`project.task_count` is consistent with the actual task rows in the seed data, but is
treated as **derived** at runtime so it stays correct after task create/delete.

### Data requirements

- [x] Mock JSON is bundled as a Flutter asset and loaded once, then cached in memory
- [x] JSON is never read or parsed from a widget
- [x] Models parse every field present in the mock data, including nullable `assignee_id`
- [x] `task_count` recomputed from tasks rather than trusted blindly
- [x] Unknown/malformed enum values fail loudly at parse time rather than silently defaulting

---

## 3. User Roles & Authorization

Two roles, resolved from `org_members` for the authenticated user's organization.

| Capability | `org_admin` | `member` |
|---|---|---|
| View projects / tasks in own org | yes | yes |
| Create project | yes | yes |
| Edit project | yes | yes |
| **Delete project** | yes | **no** |
| **Manage members** | yes | **no** |
| Create / edit / delete task | yes | yes |
| Change task status / priority | yes | yes |
| Assign / unassign users | yes | yes |

Requirements:

- [x] Authorization is enforced in business logic, not by hiding buttons
- [x] A direct call to an admin-only operation by a `member` is rejected with a typed failure
- [x] Cross-organization access is rejected in business logic (not just filtered from lists)
- [x] Assigning a user outside the current organization is rejected by business logic
- [x] UI additionally hides actions the current user cannot perform (defence in depth)
- [x] A 401 on a read (not just a write) triggers refresh and, on failure, signs the user out

---

## 4. Authentication & Session

- [x] Splash screen checks for an existing valid session and routes accordingly
- [x] Login authenticates against `auth_mock.test_credentials` (email + password)
- [x] Credentials are never hardcoded in widgets — they live in the mock data source
- [x] Register simulates a successful local account creation and signs the user in
- [x] Register rejects an email that already exists in the mock data
- [x] Access token + refresh token stored in secure storage
- [x] Access token expiry honoured (`900s` from mock response)
- [x] Refresh token expiry honoured (`604800s`)
- [x] Expired access token triggers a refresh transparently before a repository call
- [x] Expired/invalid refresh token forces logout and returns to login
- [x] Logout clears session, tokens and cached org-scoped data
- [x] Authenticated routes are unreachable after logout (router redirect, not just pop)
- [x] Passwords are never persisted
- [x] Tokens are never written to logs

---

## 5. Screens

| # | Screen | Requirements | Status |
|---|---|---|---|
| 1 | Splash | Branded, session check, routes to login or dashboard | [x] |
| 2 | Login | Email + password, inline validation, loading, error, submit lock | [x] |
| 3 | Register | Name/email/password/confirm, validation, duplicate-email error | [x] |
| 4 | Dashboard | Welcome, project count, task summary by status, overdue count, recent tasks, quick actions | [x] |
| 5 | Projects | Name, description, derived task count, loading/empty/error, pull-to-refresh | [x] |
| 6 | Project Details | Project info, task statistics, task list, edit/delete entry points | [x] |
| 7 | Task List | Title, priority, status, assignee, due date; filters | [x] |
| 8 | Task Details | All fields, comments, status/priority/assignee actions, delete | [x] |
| 9 | Create / Edit Task | Clean validated form, meaningful field errors | [x] |
| 10 | Create / Edit Project | Clean validated form | [x] |
| 11 | Profile / Settings | User info, org info, role, theme mode, developer tools, logout | [x] |
| 12 | Notifications | Per-user notifications from mock data, read/unread, deep-link to task | [x] |

---

## 6. Project Functionality

- [x] List projects for the current organization only
- [x] Project details with task statistics
- [x] Create project
- [x] Edit project
- [x] Delete project (admin only, confirmation dialog, cascades its tasks)
- [x] Lists refresh after every mutation
- [x] Destructive actions require confirmation

---

## 7. Task Functionality

- [x] List tasks (per project and across the org)
- [x] View task details
- [x] Create task
- [x] Edit task
- [x] Delete task (confirmation)
- [x] Update status (inline, from list and detail)
- [x] Update priority
- [x] Assign user
- [x] Unassign user
- [x] Due date set/clear via date picker
- [x] Refresh after every mutation

### Filtering

- [x] By status (multi-select)
- [x] By priority (multi-select)
- [x] By assignee (including "Unassigned")
- [x] By due-date range
- [x] Free-text search on title/description
- [x] Filter logic lives in a pure, separately unit-tested function — not in a widget
- [x] Active filter count surfaced in UI, with clear-all

---

## 8. Assignment Rules

- [x] Assignable users derived from `users` + `org_members` for the current org
- [x] Business logic validates the assignee belongs to the current organization
- [x] Assigning an out-of-org user returns a typed failure, even if called directly
- [x] Unassign supported (sets `assignee_id` to null)

---

## 9. State Management

- [x] Riverpod as the single state solution
- [x] Business logic in providers/controllers/services, not widgets
- [x] Explicit states: initial / loading / success / empty / error
- [x] No `setState` for business state (local-only UI state excepted)
- [x] Async mutations expose in-flight state so buttons can lock

---

## 10. Local Storage & Offline

- [x] Secure storage for tokens
- [x] SharedPreferences for cached data and settings
- [x] Last successfully loaded projects/tasks persisted per organization
- [x] Offline mode: cached data stays visible, no crash
- [x] Offline indicator banner
- [x] Stale-data indication with last-updated time
- [x] Retry action available from offline/error states
- [x] Mutations blocked while offline with a clear message
- [x] Cache cleared on logout

---

## 11. Error Simulation (reviewer-triggerable)

A developer panel in Profile → Developer Tools toggles simulated failures.

- [x] Network timeout
- [x] Server error (500)
- [x] Task not found (404)
- [x] Validation error from "server"
- [x] Unauthorized (401) — forces token refresh path
- [x] Offline mode toggle
- [x] Slow network toggle (extended artificial delay)
- [x] Every simulated error is documented in README with exact steps

---

## 12. UI/UX

- [x] Defined design system: colour palette, typography, spacing, radii
- [x] Consistent cards, buttons, inputs, chips, app bars
- [x] Light and dark theme
- [x] Skeleton loaders (not bare spinners) for list/detail loads
- [x] Reusable empty-state widget with actionable copy
- [x] Reusable error-state widget with retry
- [x] Human-readable error messages, never raw exception text
- [x] Destructive actions confirmed
- [x] Every action gives feedback (snackbar/inline)
- [x] Forms disable duplicate submission and show progress
- [x] Bottom navigation for primary sections

---

## 13. Responsive Design

- [x] Layouts adapt across small/large phones and tablets
- [x] No fixed screen widths or fragile fixed heights
- [x] Scroll-safe forms when the keyboard opens
- [x] Landscape supported on key screens
- [x] Long text truncates gracefully instead of overflowing
- [x] Safe-area respected

---

## 14. Navigation

- [x] Declarative router (go_router)
- [x] Auth-driven redirects (unauthenticated → login, authenticated → dashboard)
- [x] Full route hierarchy: dashboard → projects → project → tasks → task detail → edit
- [x] Deep-linkable, typed route helpers
- [x] Back navigation behaves correctly from every screen
- [x] Authenticated routes unreachable after logout

---

## 15. Testing

Tests must use mock data and must not touch a real network.

### Unit
- [x] Session/token logic: expiry, refresh, forced logout
- [x] Login success and failure paths
- [x] Task filtering (all filter dimensions and combinations)
- [x] Form validators
- [x] Authorization rules (admin-only delete, cross-org rejection, assignment validation)
- [x] Repository behaviour against the mock data source
- [x] Derived statistics (dashboard/project stats)

### Widget
- [x] Login form validation errors
- [x] Task list loading state
- [x] Task list empty state
- [x] Task list error state + retry
- [x] Task list success state
- [x] Task status update from the UI

### Integration
- [x] Login → dashboard flow
- [x] Project listing
- [x] Task listing
- [x] Create / update task
- [x] Task assignment
- [x] Logout returns to login and blocks authenticated routes
- [x] A stored session restores straight to the dashboard

**Result: 176 tests, all passing.** They found and led to fixes for three real defects:
a `RenderFlex` overflow on the login screen at narrow widths; a null-session crash when
signing out; and a 401 on a read leaving the user signed in on a dead error screen.

---

## 16. Documentation

- [x] `README.md` — overview, features, architecture, folder structure, state management,
      data layer, auth flow, storage, offline behaviour, error simulation, run/test/build
      commands, test credentials, known limitations, technical decisions
- [x] `ARCHITECTURE.md` — architecture, data flow, repository pattern, mock data source,
      state management, auth + token lifecycle, storage, navigation, authorization,
      error handling, offline handling, testing strategy, diagram
- [x] `REQUIREMENTS.md` — this checklist, kept current

---

## 17. Build & Release Readiness

- [x] `flutter analyze` clean (0 issues)
- [x] `flutter test` passing (176 tests)
- [x] Release signing config that falls back to debug keys when no keystore is present,
      so `flutter build apk --release` works on a fresh clone
- [x] Application ID and app label set (`com.taskflow`, "TaskFlow")
- [x] ProGuard/R8 shrinking enabled for release
- [x] No secrets committed
- [x] No unused dependencies

---

## 18. Acceptance Criteria

1. [x] A user can log in with each of the four seeded accounts and sees only their org's data.
2. [x] Session survives an app restart; logout makes authenticated routes unreachable.
3. [x] An expired access token is refreshed transparently; an expired refresh token forces logout.
4. [x] Projects and tasks can be created, edited and deleted, with lists refreshing after each.
5. [x] A `member` calling project-delete is rejected by business logic, not just by a hidden button.
6. [x] Assigning a user from the other organization is rejected by business logic.
7. [x] All filter dimensions work and are covered by unit tests.
8. [x] Every list has a real loading, empty and error state with retry.
9. [x] With offline mode enabled, cached data remains visible, a banner shows, mutations are blocked.
10. [x] Every simulated error can be triggered from the developer panel per the README.
11. [x] `flutter analyze` reports no issues and the full test suite passes (176 tests).
12. [x] No dead code, debug prints, TODOs, or unused dependencies remain.

---

## 19. Verification Method & Limits

Per the operating constraint for this build, **the application was never launched** — no
`flutter run`, emulator or simulator. Verification was performed by:

- `flutter analyze` (static analysis, 0 issues)
- `flutter test` — 176 tests (unit + widget + integration-style, via `flutter_test`)
- `flutter build apk --release` (compile + packaging)
- Direct source review against this checklist

Consequently the following are **not** verified and are stated as unverified:

- Real on-device rendering, pixel-level layout and font metrics
- Actual runtime behaviour of platform plugins (`flutter_secure_storage`,
  `shared_preferences`) on a physical Android/iOS device — these are exercised in tests
  through in-memory/mock implementations
- Gesture, scroll-physics and animation feel
- Genuine device rotation and keyboard-inset behaviour

Widget tests assert layout has no overflow at several representative screen sizes, which
substitutes for — but does not equal — visual inspection on a device.
