# Play Store compliance draft — PILAH

> **NOT READY TO PUBLISH.** This is a source-based working draft, not an approved
> privacy policy or a completed Play Console declaration. The app operator must
> verify the open items below against production services, every distributed
> app version, and applicable legal requirements before submission.

## Source-verified data inventory

The following reflects the mobile and backend source inspected for this draft.
It does not establish production SDK configuration, service-provider contracts,
server logs, or actual retention settings.

| Data visible in source | Evidence | Candidate Play Data safety type(s) | Candidate purpose |
| --- | --- | --- | --- |
| Google sign-in ID token; Google name, email, and profile photo URL used in the login/registration flow; backend verifies Google identity and stores Google ID and profile fields | `lib/features/authentication/presentation/widgets/login_button.dart:40-62`; `lib/features/authentication/data/remote/auth_remote_data_sources.dart:52-57`; backend `apps/authentication/services.py:358-405` | Personal info: Name, Email address, User IDs | App functionality; Account management |
| Account/customer name, email, account ID, phone, gender, date of birth, and address | `lib/features/beranda/data/nasabah_repository.dart:20-43,191-212`; backend `apps/authentication/models.py:44-52`, `apps/nasabah/models.py:32-39` | Personal info: Name, Email address, User IDs, Phone number, Address, Other info | App functionality; Account management |
| Bank Sampah name, address/city, PIC phone, organization details, and bank logo/activity photos | backend `apps/bank_sampah/models.py:22-25,38-41`; `apps/bank_sampah/serializers.py:14-18,64-69`; mobile gallery selection in `lib/features/onboarding/presentation/pages/register_bank_sampah_screen.dart:109-118` and `lib/features/profile/presentation/cubit/profile_cubit.dart:103-114` | Personal info: Name, Address, Phone number; Photos and videos: Photos | App functionality |
| Waste deposit history: date, waste type, weight, price, subtotal, transaction value, note, and resulting balance; payout records include amount, method, status, and notes | `lib/features/beranda/data/nasabah_repository.dart:91-130`; backend `apps/ledger/models.py:29-44,76-111` | Financial info: Purchase history is a candidate for transaction history; Other financial info may apply to balances/payout values. Confirm mapping with the operator against the current Play definitions. | App functionality |
| Optional appeal text and transaction notes/free text | `lib/features/bank_sampah_approval/data/datasources/bank_sampah_approval_remote_data_source.dart:9-13,33-39`; backend ledger model noted above | Other user-generated content may apply when free text is collected | App functionality |
| Access and refresh tokens stored locally to restore the signed-in session | `lib/features/authentication/data/local/auth_local_data_sources.dart:37-49,52-60` | Do not assume a Play category from local storage alone; confirm whether any identifiers are transmitted/collected by SDKs | App functionality; Account management |

Google Play’s current data-type definitions include the candidate labels above.
This table is a review aid, **not** a yes/no answer key: collection, sharing,
purposes, whether data is required or optional, encryption, and deletion answers
must be confirmed for the shipped build and its SDK configuration.

## Items not established by source inspection

- **Firebase and SDK behavior:** Production calls `Firebase.initializeApp()`
  (`lib/main_production.dart:30-37`). `pubspec.yaml:47-49` includes Firebase
  Auth and Crashlytics packages. No direct Crashlytics or Analytics calls were
  found in `lib/`, but that does not establish whether native SDK configuration
  or Firebase defaults collect crash logs or identifiers. Verify the production
  Firebase project, Android configuration, and collection settings. The
  `supabase_flutter` dependency is present (`pubspec.yaml:69`); no direct usage
  was found in `lib/`, so confirm whether it is included in the shipped app or
  used by native/transitive code.
- **WhatsApp sharing:** Backend source includes a WhatsApp gateway token/template
  (`apps/bank_sampah/models.py:38-40`), and the mobile profile UI says an
  automatic message can be sent after a transaction. Confirm the provider,
  recipient phone number source, message contents (which may include name,
  transaction amount/items, balance, and date), and whether any third parties
  receive this data before declaring sharing.
- **Photos:** The app selects gallery photos for bank registration/profile. The
  inspected code does not establish whether image metadata such as EXIF is
  stripped before upload or how long original files remain stored.
- **Location:** No device-location API/permission was found in the inspected
  mobile source/manifest. User-entered addresses and bank location text are
  present. Confirm that no production service infers or collects location from
  IP/network data before declaring that no location data is collected.
- **Retention and deletion:** Source inspection found no self-service account
  deletion endpoint or documented retention period. Logout clears local tokens
  and is not account/data deletion. The operator must supply the actual request
  channel, handling process, deletion scope, and retention schedule; do not
  answer that users can request deletion until this is verified and operational.
- **Sharing, encryption, and logs:** Confirm backend hosting/storage providers,
  Google/Firebase processing, any WhatsApp provider, server/access/error logs,
  all data flows and whether all collected/transmitted data is encrypted in
  transit. Source alone does not support a complete declaration.
- **Legal/operator statements:** Confirm the data controller/operator identity,
  public contact, lawful basis/purpose, applicable jurisdictions, and approved
  retention/deletion wording with the responsible operator/legal reviewer.

## Draft Play listing copy (needs product approval)

**Short description**

> Kelola aktivitas bank sampah: setoran, saldo, riwayat, dan jadwal.

**Full description**

> PILAH mendukung kegiatan bank sampah untuk nasabah dan pengelola. Nasabah
> dapat melihat saldo, riwayat setoran, informasi bank sampah, dan jadwal yang
> tersedia. Pengelola dapat mencatat setoran berdasarkan jenis dan berat
> sampah, mengelola harga, mencatat pencairan saldo, serta membuat dan
> mengatur jadwal. Fitur yang tersedia mengikuti peran dan akses akun.
>
> Masuk dengan akun yang didukung dan lengkapi data profil atau keanggotaan
> yang diminta untuk menggunakan fitur sesuai peran Anda.

These descriptions avoid claims about environmental impact, security guarantees,
availability, pricing, or service coverage that were not verified in source.
Product/operator review is still needed before publication.

## Play Console completion checklist — not inspected

No Play Console page or form was inspected for this draft. Complete and verify
the actual app’s fields before submission; do not copy guessed answers:

- Data safety: collected/shared data types, collection required/optional,
  purposes, third-party/service-provider handling, encryption in transit, and
  data deletion-request mechanism. Review the preview against the app.
- Privacy policy: publish an approved policy at a public HTTPS URL and enter
  that exact live URL. No policy page or production URL was verified. The
  existing web deployment could host a static `web/privacy-policy/index.html`
  at `/privacy-policy/`; verify the deployed Cloud Run URL and page accessibility
  before using it.
- Store listing: approved title, short/full descriptions, support contact,
  privacy-policy link, app icon, phone screenshots, and feature graphic. The
  repository audit found app logos/icons, but no approved Play listing
  screenshots, feature graphic, privacy page, or verified public privacy URL.
  Use the exact asset sizes/formats requested by the current Console.
- App content: complete the current content-rating questionnaire, target
  audience/age declaration, ads declaration, and any other applicable app
  content forms from verified product facts.
- App access/review: the current rejection requires a dedicated login that
  works without Google device-bound authentication. In Play Console's App
  access / Sign in details declaration, an authorized operator must enter the
  active reviewer credentials and clear feature-access steps, then verify them
  on a clean device. Do not place credentials in this document, source, issue
  tracker, release notes, or public listing.
- Confirm the package/app identity and production release track/version in
  Console before uploading or promoting a release.

## Evidence references

- [Google Play Console Help — Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- `docs/PLAY_RELEASE.md` describes the repo’s release workflow; it is not proof
  that Play Console forms, listing content, reviewer access, or release approval
  are complete.
