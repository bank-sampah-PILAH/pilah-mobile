# PILAH Mobile design guide

How the app should look and how to build UI so it stays consistent across developers.
Read this before adding or changing a screen. Each rule is marked **in code** (enforced by the theme or a shared piece today) or **proposed** (agreed direction, not yet in code).

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
| Danger | none | `#DC2626` | proposed token; also `#C62828` in use |
| Warning | none | amber family, 10+ shades in use | proposed: one pair (text + tint) |

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
| Confirm dialog | `showAppConfirmDialog` (`core/bases/widgets`) | Answers `true` only on confirm. Used by logout, leaving onboarding and Jadwal cancel/complete. |
| Empty state | `EmptyView` | |
| Loading list | `SkeletonListItem` | Avoid a bare spinner for lists. |
| Loading / empty / error / content in one | `PageStateView` (`design/layout`) | New; adopt on new pages. |
| Pull to refresh | `AppRefreshIndicator` | |
| Feedback after an action | `AppNotification.showSuccess` / `showError` / `showWarning` | Do not use `SnackBar` (only `jadwal` does). |
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

Still open: a few local tint colors next to it (for example the mint `#F0FDF4` behind status badges and the saldo block) are not tokens yet. Pick one tint, `AppColors.greenLight` (`#EAF5EC`) or the mint, and move it into `AppColors`.

### 5.3 Accessibility baseline: WCAG 2.1 AA (decided)

The app follows WCAG 2.1 AA for color: 4.5:1 for normal-size text and for white text on a fill, 3:1 for large text and UI components. The primary emerald `#006D44` is 6.4:1 on white and clears 4.5:1 on the card off-white, `greenLight` and the mint tint. (The earlier sage `#5D8E6C` was 3.78:1; a darkened sage `#4D765A` passed but looked olive next to the logo.) `test/design/contrast_test.dart` checks these pairs and runs Flutter's `textContrastGuideline` on themed buttons. A new color pair used for text should be added to that test.

Known gaps against this baseline, not yet audited screen by screen: light grey hint and caption text (`Colors.grey[400]` and similar), touch targets under 48 dp, and missing semantics labels on bare `GestureDetector`s.

## 6. Content and formatting rules

- **Rupiah** with a dot as thousands separator and `Rp ` prefix: `Rp 41.250`, never `Rp 3500`. Use `CurrencyFormatter.formatRupiah`.
- **Weight** in kg with a decimal comma and no trailing zeros: `3 kg`, `1,5 kg`. Never `3.000 kg` (reads as three thousand). Use `WeightFormatter.formatKg`.
- **Dates** `dd/MM/yyyy`; Indonesian month names in long form.
- **Role names**: Pengurus for the bank-sampah operator, Nasabah for the customer, Pengelola Induk, Superadmin. Do not show "Pengelola" for a Pengurus account.
- **Language**: all user-visible text is Indonesian, including Material widgets such as the date picker (`locale: id` with `flutter_localizations` in `lib/app.dart`).
- **Destructive actions** (logout, delete, cancel) ask for confirmation with `showAppConfirmDialog` (`destructive: true` paints the confirm button red). Do not build an `AlertDialog` per screen.

## 7. Checklist for a new screen

- [ ] Colors and text from tokens, no new literals. `test/design/hardcoded_styles_test.dart` fails on any new raw `Color(0x…)` or `fontSize:` outside `lib/design/`; after removing some, lower its baseline with `UPDATE_BASELINE=1 flutter test test/design/hardcoded_styles_test.dart`.
- [ ] Stock widgets left alone, so the theme applies.
- [ ] Sheets use `BottomSheetHeader`.
- [ ] Loading, empty and error states handled.
- [ ] Amounts and weights go through the formatters.
- [ ] Feedback through `AppNotification`.
- [ ] Checked at a narrow phone width and, for web roles, a wide one.
- [ ] Long names truncate with an ellipsis and do not collide with amounts.
