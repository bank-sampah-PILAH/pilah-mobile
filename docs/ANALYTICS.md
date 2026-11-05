# Usage analytics

PILAH sends a small number of events to PostHog so the team can see where
pengurus slow down, give up, or run into errors. **On the web no screen is
recorded. In the Android and iOS apps it is, with every text and image hidden**
(see "Screen recording" below). Events say *what* a pengurus did (which step, how long, how many, what went
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
after its route pattern (`nasabah/:id`, never the real id). Each `$screen` event
says which screen the user came from (`layar_sebelumnya`) and how many seconds
they stayed there (`durasi_layar_sebelumnya_detik`). `app_dibuka` is sent once
when analytics starts. Do not send those yourself.

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
by `environment`. On the web, recording, automatic capture and heatmaps are switched off in the
client; only load time is measured automatically.

## Screen recording (Android and iOS only)

The mobile apps also record the screen (PIL-473), so the team can open the
session of a pengurus who got stuck and see what went wrong. The recording is
masked: `maskAllTexts` and `maskAllImages` are on, so every text, icon and image
is a black block and only layout and where the finger touched are visible. No
name, balance, address, photo, email or phone number can be read in it. Do not
turn those off.

Three things are shown on purpose, so a viewer can tell which screen and which
step it is: field captions (`AppFieldLabel`), page and sheet titles
(`AppPageHeader`, `BottomSheetHeader`) and button labels (`AppButton`). They are
wrapped in `RevealInReplay` (`lib/core/analytics/replay_masks.dart`). Before you
reveal anything else, or pass a dynamic value to one of these widgets, check it
can never hold what a pengurus typed or what the server sent (a name, an
address, an amount, a note). The charts of the dashboard are drawn on a canvas
that the masks do not reach, so they are wrapped in `HideInReplay`; do the same
for anything new that draws figures itself.

- It starts and stops together with analytics: after the pengurus agrees, never
  for a nasabah or a Super Admin, and not after they withdraw.
- Agreements given before recording existed are not honoured for it: the
  pengurus is asked again with the new text (`AnalyticsConsentStore.read(screen:
  true)`). A refusal stays a refusal.
- The web does not record. Flutter web draws on one canvas, so the browser
  library has nothing to replay, and recording the canvas was rejected
  (PIL-415, PIL-465).
- The recorder (`PostHogWidget`) is put around the app by
  `AnalyticsRecordingRoot` once analytics has started. The app is kept under a
  global key, so adding the recorder does not rebuild it.

## Who an event belongs to

After a pengurus agrees, analytics is told their **id from the backend**
(`AuthEntity.id`), never a name, email address or phone number, and their role.
Every event after that belongs to that id, which is what lets funnels and
retention count people instead of clicks. Withdrawing, or signing out, forgets
the user (`reset`), so whoever uses the device next is not tied to them.

Every event also carries `environment` (`staging` or `production`, which share
one PostHog project), `platform` (`web`) and `kelas_layar` (`ponsel`, `tablet`
or `desktop`, from the screen width). Filter by `environment` in every insight.

**This id is personal data.** We can link it to a real person through our own
database, so it is pseudonymous, not anonymous. Treat it that way: it is sent
only with the pengurus's consent, nothing else that names them is sent with it,
and the privacy policy must say what is noted, why, who processes it (PostHog,
servers in the US), how long it is kept, and how to refuse or withdraw. Whether
this meets UU PDP, including sending data abroad, has not been checked by a
lawyer.

### Deleting one person's analytics data

When a pengurus asks for their data to be deleted:

1. Find their id: it is the user id the backend holds for their account, so the
   person who handles the request looks it up there.
2. In PostHog, open **Persons**, search for that id, open the person and choose
   **Delete person** (delete their events too).
3. Record the request and the date, and tell the pengurus it is done.

PostHog keeps no name or email for them, so the id is the only way to find the
person. Withdrawing consent in Profil stops new events at once but does not
delete earlier ones; that needs the steps above.

## Reading the results

The dashboard guide, and how to build funnels and retention from these events,
is in PIL-456 and PIL-466.
