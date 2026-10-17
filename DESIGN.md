# PILAH Mobile design guide

How the app should look and how to build UI so it stays consistent across developers.
Read this before adding or changing a screen. Each rule is marked **in code** (enforced by the theme or a shared piece today) or **proposed** (agreed direction, not yet in code).

The visual counterpart of this guide is the Figma design kit, see [section 8](#8-figma-design-kit).

## 1. Principles

1. **Use the theme before styling.** A stock Material widget (`AlertDialog`, `AppBar`, `TextButton`, bottom sheet, plain `Text`) already looks right through `AppTheme`. Do not restyle it per screen; only override what is genuinely different.
2. **Tokens, not literals.** Colors come from `AppColors`, text from `AppTextStyle` or `NasabahStyle`. No new `Color(0xFF…)` or `fontSize:` in a feature.
3. **Money first.** On any screen with an amount, the amount is the most prominent element.
4. **Two audiences, one system.** Nasabah screens and Pengurus screens may differ in density and card style. They share the same palette, type, radii, and component behavior.
5. **Every list has loading, empty, and error states.**
6. **WCAG 2.1 AA is the accessibility baseline** (see 5.3).

## 2. Foundations

### Color (`lib/design/constants/colors.dart`)

| Role | Token | Value | Status |
|---|---|---|---|
| Primary action (buttons, FAB, nav, hero cards, links) | `AppColors.greenDark` | `#006D44` | in code; also `colorScheme.primary`; the logo's emerald; WCAG AA (6.4:1 on white) |
| Primary tint (avatars, soft backgrounds) | `AppColors.greenLight` | `#EAF5EC` | in code |
| Text | `AppColors.black` | `#04021D` | in code |
| Secondary text | `AppColors.grey100` | `#686777` | in code |
| Border | `AppColors.grey200` | `#686777` at 38% | in code |
| Card off-white | `AppColors.cardOffWhite` | `#FAFAFA` | in code |
| Danger (errors, destructive actions) | `AppColors.danger`, tint `AppColors.dangerLight` | `#C62828`, `#FEF2F2` | in code; WCAG AA (5.6:1 on white, 5.1:1 on the tint) |
| Warning (pending, draft, caution) | `AppColors.warning`, tint `AppColors.warningLight` | `#976200`, `#FEF3C7` | in code; WCAG AA (5.2:1 on white, 4.6:1 on the tint) |
| Page / card background | `AppColors.surface` | `#F9FAFB` | in code |
| Chips, inputs, badges | `AppColors.fill` | `#F3F4F6` | in code |
| Dividers and outlines | `AppColors.border` | `#E5E7EB` | in code |
| Strong secondary text | `AppColors.inkSoft` | `#374151` | in code; 10:1 on white |

Avatars are the one place that keeps several hues on purpose. The list avatars (`core/utils/avatar_style.dart`) are light tints with dark initials, six pairs, guarded in `test/core/utils/avatar_style_contrast_test.dart`. The profile header avatar picks from `AppColors.avatarFills` (dark fills behind white initials), guarded in `test/design/contrast_test.dart`. The gender icons in the profile form are neutral (`AppColors.inkSoft`), not blue and pink.

Retired colors: the greys, ambers, green tints and reds that used to be copied into screens are listed in `test/design/retired_palette_test.dart`, which fails if one comes back. If a screen needs a new color, add a token here and a contrast pair in `test/design/contrast_test.dart` instead of a literal.

`AppColors.primary` (`#2B637B`, teal-blue) is **not** the app's accent. It was the Material seed until this theme change and still leaks into the browser tab color in `lib/app.dart`. Do not use it for new UI.

### Typography (`lib/design/constants/text_style.dart`)

Font: **Poppins**, bundled in `assets/fonts` (regular, medium, semibold, bold). `AppTheme` sets it as the default text font, so a bare `Text` is Poppins and `fontWeight` picks the real face. `AppTextStyle` still loads Poppins through `google_fonts` at runtime; both look the same.

| Style | Size / weight | Use |
|---|---|---|
| `AppTextStyle.headline1` | 24 / w600 | Page titles |
| `AppTextStyle.title1`, `appBar` | 18 / w600 | Section titles, app bar titles |
| `AppTextStyle.headline3` | 16 / w500 | Emphasized body |
| `AppTextStyle.small` | 12 | Body, captions |
| `AppTextStyle.extraSmall` | 10 | Meta text, nav labels |

`NasabahStyle.text(size, …)` exists for nasabah screens. Prefer sizes from the table above; sizes 11, 13, 15, 17, 22 and 26 appear in the code today and should be moved onto the scale over time (**proposed**).

### Shape and spacing

| | Scale | Status |
|---|---|---|
| Radius | 8 (chips, small tiles), 12 (inputs, buttons), 16 (cards, dialogs), 24 (sheets, hero cards) | dialogs 16 and sheets 24 in code via `AppTheme`; the rest proposed. 12 and 16 already account for about 70% of usages. |
| Spacing | 4, 8, 12, 16, 24, 32 | proposed; no token yet |
| Content width | 600 max on nasabah pages (`NasabahStyle.maxWidth`, `ContentBounds`) | in code |

### Surfaces (**in code**, `lib/design/theme/app_theme.dart`)

- Dialogs: white, 16 radius, no Material tint.
- Bottom sheets: white, 24 top radius, no tint.
- App bars: white, no scroll tint, 18/w600 Poppins title.

## 3. Components

Use these instead of building another one.

| Need | Use | Notes |
|---|---|---|
| Sheet header (title + close) | `BottomSheetHeader` | Do not hand-build the drag handle (about 17 copies exist today). |
| Primary / secondary button | `CustomPrimaryButton`, `CustomOutlinedButton`, `design/widgets/atom/primary_button.dart` | Plain `FilledButton`/`TextButton` pick up the theme color. |
| Search | `CustomSearchField` | |
| Status chip | `CustomStatusBadge` | |
| Filter / tab pill | `AppChip` (`design/widgets`) | Announced to screen readers as a selected or unselected button, ripple, 48 dp hit area, optional icon and count. Used by the nasabah, harga, aktivitas and pencairan filters; `PencairanChip` wraps it. |
| Tappable icon, link or field | `AppTapTarget` (`design/widgets`) | Button role, optional `label` for icon-only controls, ripple, 48 dp hit area, optional selected state for options in a group. Use instead of a bare `GestureDetector`. |
| Tappable white card | `AppTappableCard` (`design/widgets`) | Button role that reads the card's own text, ripple on top of the fill. Used by the nasabah, harga and membership cards. |
| Confirm dialog | `showAppConfirmDialog` (`core/bases/widgets`) | Answers `true` only on confirm. Used by logout, leaving onboarding and Jadwal cancel/complete. |
| Empty state | `EmptyView` | |
| Loading list | `SkeletonListItem` | Avoid a bare spinner for lists. |
| Loading / empty / error / content in one | `PageStateView` (`design/layout`) | New; adopt on new pages. |
| Pull to refresh | `AppRefreshIndicator` | |
| Feedback after an action | `AppNotification.showSuccess` / `showError` / `showWarning` | Do not use `SnackBar`. |
| Form field look | `appInputDecoration`, `appInputStyle` (`design/constants/form_style.dart`) | Text-field borders are intentionally not in the theme, see 5.2. |
| Nasabah cards and app bar | `NasabahCard`, `NasabahPageAppBar` | |
| Nasabah data screens | `NasabahResource` | One load/error/retry/reload shape. |

## 4. Patterns worth repeating

These came out of the audit as the strongest existing screens.

- **Label over value** rows with a leading icon and a divider (nasabah profile).
- **Amount hero**: one large number on a green card, secondary info under it (dashboard, beranda, tabungan).
- **Detail sheet**: title + status chip, an identity block, a tabular breakdown with a bold total, then a highlighted balance block (`DetailTransaksiBottomSheet`).
- **Forms**: uppercase small label above each field, inline error under the field with a red border, a sticky primary action at the bottom.
- **Confirm dialogs** state the consequence ("Saldo nasabah … akan dihitung ulang"), not just "Are you sure?".

## 5. Open decisions

### 5.1 One green (decided)

`AppColors.greenDark` (`#006D44`) is the only primary green: buttons, FAB, nav, hero cards, links, selected filter chips and amounts. It is the emerald of the logo (the logo's main green is about `#04845C`). The earlier muted sage `#5D8E6C` was a different color family and failed contrast, so it is gone; `test/design/single_primary_green_test.dart` pins the value and fails if a screen defines its own copy. `NasabahStyle.emerald` and `emeraldDark` are aliases of the same green.

The mint tint that used to sit next to it is gone; badges and the saldo block use `AppColors.greenLight`.

### 5.3 Accessibility baseline: WCAG 2.1 AA (decided)

The app follows WCAG 2.1 AA for color: 4.5:1 for normal-size text and for white text on a fill, 3:1 for large text and UI components. The primary emerald `#006D44` is 6.4:1 on white and clears 4.5:1 on the card off-white, `greenLight` and the mint tint. (The earlier sage `#5D8E6C` was 3.78:1; a darkened sage `#4D765A` passed but looked olive next to the logo.) `test/design/contrast_test.dart` checks these pairs and runs Flutter's `textContrastGuideline` on themed buttons. A new color pair used for text should be added to that test.

Known gaps against this baseline, not yet audited screen by screen: light grey hint and caption text (`Colors.grey[400]` and similar), touch targets under 48 dp, and the one remaining `GestureDetector`, the payment summary header, which needs its swipe gesture and is given button and expanded semantics by hand.

## 6. Content and formatting rules

- **Rupiah** with a dot as thousands separator and `Rp ` prefix: `Rp 41.250`, never `Rp 3500`. Use `CurrencyFormatter` (`formatRupiah`, `formatNumber` without the prefix, `formatRupiahValue` for backend values); `test/design/single_rupiah_formatter_test.dart` fails if a file groups digits by hand.
- **Weight** in kg with a decimal comma and no trailing zeros: `3 kg`, `1,5 kg`. Never `3.000 kg` (reads as three thousand). Use `WeightFormatter.formatKg`.
- **Dates** `dd/MM/yyyy`; Indonesian month names in long form.
- **Role names**: Pengurus is the operator of a bank sampah unit (role key `pengelola`); Pengelola is reserved for the induk (parent) organisation (`pengelola_induk`, a later feature); Nasabah is the customer; Superadmin. Never show "Pengelola" for a bank sampah unit.
- **Navigation**: the tab is called Aktivitas and opens the screen titled Riwayat Aktivitas.
- **Language**: all user-visible text is Indonesian, including Material widgets such as the date picker (`locale: id` with `flutter_localizations` in `lib/app.dart`).
- **Destructive actions** (logout, delete, cancel) ask for confirmation with `showAppConfirmDialog` (`destructive: true` paints the confirm button red). Do not build an `AlertDialog` per screen.

## 7. Checklist for a new screen

- [ ] Colors and text from tokens, no new literals. `test/design/hardcoded_styles_test.dart` fails on any new raw `Color(0x…)` or `fontSize:` outside `lib/design/`; after removing some, lower its baseline with `UPDATE_BASELINE=1 flutter test test/design/hardcoded_styles_test.dart`.
- [ ] Stock widgets left alone, so the theme applies.
- [ ] Sheets use `BottomSheetHeader`.
- [ ] The screen or overlay has a counterpart in the Figma kit, built from its components. If you introduce a new pattern, add it to Figma and to the mapping table in section 8.
- [ ] Loading, empty and error states handled.
- [ ] Amounts and weights go through the formatters.
- [ ] Feedback through `AppNotification`.
- [ ] Checked at a narrow phone width and, for web roles, a wide one.
- [ ] Long names truncate with an ellipsis and do not collide with amounts.

## 8. Figma design kit

The design kit is the visual twin of this guide: the same tokens, the same components, and a mirror of the screens and overlays that exist in the app for **Pengurus** and **Nasabah**.

- **File:** [PILAH 2.0](https://www.figma.com/design/VF8jKsBUS0K8jIG8ZEaIad), in the **PILAH 2.0** Figma team. The link only opens for team members; ask a team admin for access.
- **Source of truth:** the code. Figma copies values from Flutter (`colors.dart`, `text_style.dart`, `app_theme.dart` and the shared widgets), not the other way round. When Figma and the code disagree, the code wins and Figma gets fixed. A few values in Figma deliberately follow the code where the code is off the scale (see 8.5).

### 8.1 What is on each page

| Page | Contents | Use it for |
|---|---|---|
| **Components** | Variables (colors, radius, spacing), text styles `AppText/*`, and every component listed in 8.3 | Building any new screen or overlay |
| **Mobile Screens** | Pengurus (dashboard, nasabah, harga, aktivitas, jadwal, profil, pencairan), Superadmin, auth, and the **Nasabah (mobile)** section (beranda, tabungan, jadwal, profil, approval, onboarding) | Reference for layout and hierarchy |
| **Mobile Overlays** | Bottom sheets, dialogs, date and time pickers, popup menus, drawer, toast, and a few extra pages, each on top of its base screen with the 54% scrim. Grouped by role and type | Reference for anything that opens over a screen |
| **Dashboard Web** | The Pengurus dashboard at desktop width | Web layout reference |
| **Existing UI** | Raw screenshots of the running app (mobile, web, overlays) | **Archive only.** Compare against it, never build from it |

Frames are 390 wide. The real app is shown at 486 in the screenshots, so text looks about 25% larger in Figma at the same proportions. This is expected.

### 8.2 Tokens

Figma variable and style names mirror the Flutter tokens:

| Figma | Flutter |
|---|---|
| `brand/greenDark`, `brand/greenLight` | `AppColors.greenDark`, `AppColors.greenLight` |
| `text/black`, `text/grey100`, `text/inkSoft` | `AppColors.black`, `grey100`, `inkSoft` |
| `surface/surface`, `surface/cardOffWhite`, `surface/fill` | `AppColors.surface`, `cardOffWhite`, `fill` |
| `border/border`, `border/grey200` | `AppColors.border`, `grey200` |
| `danger/danger`, `danger/dangerLight` | `AppColors.danger`, `dangerLight` |
| `warning/warning`, `warning/warningLight` | `AppColors.warning`, `warningLight` |
| `radius/sm…xl` (8, 12, 16, 24), `spacing/xs…2xl` (4, 8, 12, 16, 24, 32) | the scales in section 2 |
| `AppText/Headline 1`, `Title 1`, `Headline 3`, `Body Small`, `Extra Small` | `AppTextStyle.headline1`, `title1`, `headline3`, `small`, `extraSmall` |

Apply a variable or style instead of typing a color or size. A literal in Figma is the same mistake as a `Color(0xFF…)` in Dart.

### 8.3 Component to widget map

Find the component in Figma, then use the Flutter widget on the right. **No shared widget** means the Flutter side still builds it inline; do not invent a second copy, reuse the existing pattern or extract a shared widget first.

| Figma component | Flutter | Notes |
|---|---|---|
| `Button` (Primary, Outlined, Destructive) | `CustomPrimaryButton`, `CustomOutlinedButton` | 48 high, radius 16 |
| `Chip` | `AppChip` | |
| `Card` | `AppTappableCard`, `NasabahCard` | |
| `Sheet Header` | `BottomSheetHeader` | Grabber, 20 bold title, 36 close button |
| `Status Badge` | `CustomStatusBadge` | Aktif, Nonaktif, Menunggu |
| `App Bar`, `Page Header`, `Section Header` | `NasabahPageAppBar`, theme app bar | |
| `Text Field`, `Field/Select`, `Field/Date`, `Field/Area`, `Field/Phone`, `Field/Money` | `appInputDecoration`, `appInputStyle` | Label above the field, uppercase |
| `Search Field` | `CustomSearchField` | |
| `FAB` | `FloatingActionButton` (theme) | 56, radius 16 |
| `Stat Card`, `Total Kas Card`, `KPI Card` | `StatCard`, `TotalKasCard` | |
| `Nasabah List Item`, `List Row`, `Activity Item` | `NasabahListItem`, `ActivityItem` | |
| `Bottom Nav`, `Bottom Nav (Nasabah)`, `Nav Item` | `RoleNavigationBar`, `RoleNavigationRail`, `RoleNavigationDrawer` | Bar on phones, rail and drawer on web |
| `Dialog/Confirm` (Destructive true or false) | `showAppConfirmDialog` | |
| `Dialog/Icon Confirm` (Warning, Success) | `HargaConfirmationDialog`; the Nasabah deactivate dialog is built inline | Candidate for one shared widget |
| `Toast` (Success, Error, Warning) | `AppNotification.showSuccess`, `showError`, `showWarning` | Appears at the top |
| `Menu Item` | `PopupMenuButton` items | |
| `Checkbox` | `Checkbox` (theme) | |
| `Notice`, `Detail Row`, `Option Card` | **no shared widget** | Used in detail sheets, edit forms and the Transaksi Baru chooser |
| Date picker, time picker (frames in *Mobile Overlays*) | Material `showDatePicker`, `showTimePicker` | Not components; the time picker is an approximation |
| `Icon/*` | Material icons of the same name | Redrawn as vectors; swap by instance, do not paste an image |

### 8.4 How to use it

**Designing or changing a screen** (when you ship UI work, the `ship` skill runs this design-first loop for you)
1. Start from the components on the *Components* page. Do not detach instances to tweak them; if a variant is missing, add it to the component.
2. Bind colors, radii and text to variables and styles (8.2).
3. Put overlays on top of their base screen with the same scrim as the app (54% black), as in *Mobile Overlays*.
4. Add the new screen or overlay to *Mobile Screens* or *Mobile Overlays* in the same change that ships it in Flutter.

**Building a screen in Flutter**
1. Find the screen or overlay that is closest in Figma and read which components it uses (8.3).
2. Use the widgets in the right-hand column. If a row says no shared widget, follow the nearest existing implementation and mention it in the PR.
3. Check the result against the frame: hierarchy, spacing and which component is used matter more than exact pixels.

**Changing a token or a shared component**
1. Change the code first (`colors.dart`, `text_style.dart`, `app_theme.dart` or the widget).
2. In the same PR, update the matching variable, style or component in Figma and mention it in the PR description.
3. Update the tables in this section when a component is added, renamed or gets a shared widget.

**Do not**
- Build from *Existing UI*; it is a dated capture of the app, not a design.
- Copy hex values out of Figma into Dart. Use the token.
- Edit the file from a view-only seat and expect it to save; ask a team admin for an edit seat.

### 8.5 Known gaps

- Some values follow the code where the code is off the scale: the total-kas card uses radius and padding 20, list avatars are 50, and several texts use 14, 15 and 16. Figma leaves those unbound until the code is moved onto the scale (see section 2).
- Pages that are not rebuilt from components yet: the PDF preview, and the web desktop screens other than the dashboard. They exist only as screenshots in *Existing UI*.
- The Superadmin and Pengurus Induk screens are only partly mirrored. The proof-image dialog and the approval message dialog are not.
- Nasabah has no web version; its frames are phone-only.
