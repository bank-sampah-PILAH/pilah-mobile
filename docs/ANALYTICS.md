# Usage analytics

PILAH sends a small number of events to PostHog so the team can see where
pengurus slow down, give up, or run into errors. **No screen is recorded.**
Events say *what* a pengurus did (which step, how long, how many, what went
wrong), never *who* they are or what was on their screen.

Nothing is sent until a pengurus has agreed in the consent dialog, and nothing
is sent for a nasabah or a signed-out user. A pengurus can withdraw in Profil.
Login, registration and onboarding are not recorded.

## Sending an event

```dart
ref.read(analyticsClientProvider).capture('setoran_disimpan', {
  'jumlah_item': request.items.length,
});
```

`capture` does nothing before the user agrees or after they withdraw, so call it
without checking. See `transaksi_baru_page.dart` for a real one.

Screens are reported automatically: `AnalyticsScreenTracker` names each screen
after its route pattern (`nasabah/:id`, never the real id) and sends
`layar_ditinggalkan` with `durasi_detik` when the user leaves it. `app_dibuka`
is sent once when analytics starts. Do not send those yourself.

## Naming

* `snake_case`, Indonesian, past tense: `<objek>_<aksi>`, such as
  `setoran_disimpan` or `jadwal_dibuat`.
* One event for one thing that happened. Put variations in properties, not in
  new event names.
* Keep each feature's event names in a file of its own, such as
  `lib/features/transaksi/analytics/transaksi_events.dart`, so features do not
  conflict when worked on together.

## Properties

Only the names in `AnalyticsProps.allowed` (`lib/core/analytics/analytics_props.dart`)
may be sent. Anything else fails an assertion in debug builds and tests, and is
quietly left out of a release build. To send something new, add its name to that
list after checking it holds **none** of these:

* a name, email address, phone number, address or id of a person;
* a money amount, price, balance or total;
* text somebody typed, including search words;
* an address with real values in it (use the route pattern);
* a raw error message (use `error_code`, `jenis_error`, `http_status`).

Good properties are counts (`jumlah_item`), durations in seconds
(`durasi_detik`), steps (`langkah`), outcomes (`berhasil`), error codes, and
names from a fixed set (`jenis_filter`, `masalah`). Text that looks like an email
address or phone number is refused even under an allowed name.

## Testing

Use `FakeAnalyticsClient` from `test/support/fake_analytics_client.dart`. It
runs every event through the same property check, so a test that sends a
property that is not allowed fails right there.

```dart
final analytics = FakeAnalyticsClient();
// override analyticsClientProvider with analytics, then:
expect(analytics.events.single.name, 'setoran_disimpan');
expect(analytics.events.single.properties, {'jumlah_item': 1});
```

## How it is switched on

`ENABLE_POSTHOG`, `POSTHOG_API_KEY`, `POSTHOG_HOST` and `POSTHOG_ENVIRONMENT`
in the web `.env` (see `.env.example` and `docs/DASHBOARD_DEPLOYMENT.md`).
Staging and production share one PostHog project, so every event can be filtered
by `environment`. Recording, automatic capture and heatmaps are switched off in
the client; only load time is measured automatically.

The native Android app does not send events yet (PIL-416).

## Reading the results

The dashboard guide, and how to build funnels and retention from these events,
is in PIL-456 and PIL-466.
