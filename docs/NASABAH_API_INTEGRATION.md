# PIL-225 / PIL-226 backend refactors and mobile integration

## Backend commits

- PIL-225: `31afd08` on `feature/pil-225`.
- PIL-226: `dd12ba3` on `feature/pil-226`.

`api/permissions.py` now defines `IsActiveNasabah`. Use
`permission_classes = [IsActiveNasabah]` on nasabah views. It checks authentication,
active account status, and the nasabah role, without requiring bank membership.

`api/nasabah_home.py` defines `MembershipService`. Call
`MembershipService.get_active_membership(request)` to obtain an eligible membership
owned by the current user. It separates explicit selection, default selection,
and active membership/bank validation into named methods. Missing selection is
allowed only when exactly one membership is eligible. Empty or malformed UUIDs
remain invalid. All four home endpoints use this service.

`api/nasabah_profile.py` returns the current user's read-only identity and uses
`IsActiveNasabah`. Profile access intentionally does not depend on bank membership.

The main SOLID principle is Single Responsibility: access policy, membership
rules, and HTTP responses have separate responsibilities. Sharing the permission
also follows DRY. Naming boolean conditions is a readability refactor, not an
additional SOLID principle.

## Mobile modules

- `lib/features/beranda/data/nasabah_repository.dart`: typed API responses and
  authenticated calls through the existing `NetworkService`. Registered in
  `lib/services/di.dart`. Use `di<NasabahRepository>()`; do not construct a second
  unauthenticated HTTP client.
- `lib/features/beranda/presentation/widgets/nasabah_resource.dart`: request state,
  loading indicator, retry/refresh, membership options, currency/date display,
  and activity list. Re-key requests when their session or selection changes.
- `lib/features/beranda/presentation/pages/beranda_nasabah_page.dart`: API-backed
  balance, bank information, recent activity, membership selection and paginated
  history. The API is authoritative for membership eligibility.
- PIL-226's `lib/features/profile/presentation/pages/profil_nasabah_page.dart`:
  fetches profile identity rather than relying on the login snapshot.
- `lib/core/router/auth_routing.dart`: recognizes `nasabah_dashboard`.
- `lib/preview/preview_nasabah_repository.dart`: explicit offline fixture used only
  by the visual preview entrypoint and tests, never registered by the real app.

Example calls:

```dart
final api = di<NasabahRepository>();
final home = await api.home(); // May request membership selection.
final selected = await api.home(membershipId: membershipId);
final balance = await api.balance(selected.membershipId);
final bank = await api.bank(selected.membershipId);
final history = await api.history(selected.membershipId, page: 2);
final profile = await api.profile(); // No membership required.
```

## Run against the backend

1. Use a backend checkout containing both feature implementations for the combined
   mobile experience. The two backend branches are independent; neither contains
   the other's endpoint automatically.
2. Install backend requirements, run migrations, and start Django. Use an active
   nasabah account linked to an approved, active membership and active bank for
   home access. Profile only needs the active nasabah account.
3. Configure the normal app's `.env` `BASE_URL_DEV` / `BASE_URL_PROD` to the backend
   origin, without `/api/v1` (the repository includes that prefix). Use an address
   reachable from the device; Android emulator localhost is normally `10.0.2.2`.
4. Run `flutter pub get`, then
   `dart run build_runner build --delete-conflicting-outputs` when generated
   authentication serializers are missing. Start the normal app entrypoint and
   sign in. `lib/main_beranda_preview.dart` deliberately remains offline.
5. When several memberships are eligible, choose the bank offered by the API.
   Details and every history page retain that membership ID. Use refresh to fetch
   newer values, or choose the bank again to change membership.

## Validation and limitations

Backend refactor validation: PIL-225 67 tests; PIL-226 60 tests; lint and typing passed.
Mobile validation: PIL-225 241 tests passed; PIL-226 248 tests passed. Flutter analysis
reports no issues on either branch. One opt-in live test is skipped in each normal
suite and was run separately against Django successfully.

Mobile unit/widget tests cover payloads, errors, decimal display, membership choice,
pagination, retry, stale session responses, API profile identity and routing.
Opt-in `nasabah_live_api_test.dart` also exercised the real authenticated HTTP client
against disposable local Django databases: home, details, 20+1 history pagination,
profile, and unauthorized access. It is skipped in normal tests unless supplied
`--dart-define=PILAH_SMOKE_FIXTURE=<fixture-json>` (and
`--dart-define=PILAH_SMOKE_PROFILE=true` for the profile backend).

Potential issues / remaining delivery work:

- No deployment, push, or merge was performed. Hosted/mobile-device connectivity,
  CORS and production sign-in were not exercised by the local HTTP checks.
- PIL-225 mobile integration lives on `codex/pil-225-api-integration`, based on the
  existing home feature. PIL-226 also includes the shared home integration so it
  can run both screens. Reconcile shared files when combining the feature branches.
- History currently contains the deposit transaction model supported by these
  backend branches; withdrawal integration remains separate.
- Expired sessions show a sign-in message. This work does not add automatic token
  refresh or a new logout flow. Membership selection is in memory, not persisted.
- Page-number history can shift if new transactions arrive between requests.
- Existing debug network logging prints request headers and response data. Avoid
  sharing such logs; redact credentials and personal data before wider use.
- Existing code generation emits analyzer-version and json_annotation constraint
  warnings. Generation succeeds; dependency modernization is separate work.
