# PILAH Mobile design guide

How the app should look and how to build UI so it stays consistent across developers.
Read this before adding or changing a screen. Each rule is marked **in code** (enforced by the theme or a shared piece today) or **proposed** (agreed direction, not yet in code).

## 1. Principles

1. **Use the theme before styling.** A stock Material widget (`AlertDialog`, `AppBar`, `TextButton`, bottom sheet, plain `Text`) already looks right through `AppTheme`. Do not restyle it per screen; only override what is genuinely different.
2. **Tokens, not literals.** Colors come from `AppColors`, text from `AppTextStyle` or `NasabahStyle`. No new `Color(0xFF…)` or `fontSize:` in a feature.
3. **Money first.** On any screen with an amount, the amount is the most prominent element.
4. **Two audiences, one system.** Nasabah screens and Pengurus screens may differ in density and card style. They share the same palette, type, radii, and component behavior.
5. **Every list has loading, empty, and error states.**

## 2. Foundations

### Color (`lib/design/constants/colors.dart`)

| Role | Token | Value | Status |
|---|---|---|---|
| Primary action (buttons, FAB, nav, hero cards, links) | `AppColors.greenDark` | `#5D8E6C` | in code; also `colorScheme.primary` |
| Primary tint (avatars, soft backgrounds) | `AppColors.greenLight` | `#EAF5EC` | in code |
| Text | `AppColors.black` | `#04021D` | in code |
| Secondary text | `AppColors.grey100` | `#686777` | in code |
| Border | `AppColors.grey200` | `#686777` at 38% | in code |
| Card off-white | `AppColors.cardOffWhite` | `#FAFAFA` | in code |
| Brand emerald (selected filter chips, money in detail sheets) | none | `#006D44` | **undecided**, see 5.1 |
| Danger | none | `#DC2626` | proposed token; also `#C62828` in use |
| Warning | none | amber family, 10+ shades in use | proposed: one pair (text + tint) |

`AppColors.primary` (`#2B637B`, teal-blue) is **not** the app's accent. It was the Material seed until this theme change and still leaks into the browser tab color in `lib/app.dart`. Do not use it for new UI.

### Typography (`lib/design/constants/text_style.dart`)

Font: **Poppins**. `AppTheme` sets it as the default text font, so a bare `Text` is Poppins.

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

### 5.1 One green or two

The app uses two greens: sage `#5D8E6C` (buttons, FAB, nav, hero cards) and emerald `#006D44` (selected filter chips in Nasabah and Harga, money in transaction detail). They sit side by side on the Nasabah tab. Pick one for "selected/primary", or define emerald as a deliberate "money/positive" color and use it only for amounts. Until decided, `AppTheme` uses sage because that is what most controls use.

### 5.2 Text-field borders in the theme

`AppTheme` does not set `inputDecorationTheme`. A theme-level `enabledBorder`/`focusedBorder` overrides a screen's own `border: InputBorder.none`, which would draw outlines on fields that have none today. Doing it safely needs a `WidgetStateInputBorder` and a pass over the borderless fields. Use `appInputDecoration` for now.

## 6. Content and formatting rules

- **Rupiah** with a dot as thousands separator and `Rp ` prefix: `Rp 41.250`, never `Rp 3500`. Use `CurrencyFormatter.formatRupiah`.
- **Weight** in kg with a decimal comma and no trailing zeros: `3 kg`, `1,5 kg`. Never `3.000 kg` (reads as three thousand). Use `WeightFormatter.formatKg`.
- **Dates** `dd/MM/yyyy`; Indonesian month names in long form.
- **Role names**: Pengurus for the bank-sampah operator, Nasabah for the customer, Pengelola Induk, Superadmin. Do not show "Pengelola" for a Pengurus account.
- **Language**: all user-visible text is Indonesian. The Material date picker is still English until `flutter_localizations` is added (**proposed**).
- **Destructive actions** (logout, delete, cancel) ask for confirmation, using the app dialog style.

## 7. Checklist for a new screen

- [ ] Colors and text from tokens, no new literals.
- [ ] Stock widgets left alone, so the theme applies.
- [ ] Sheets use `BottomSheetHeader`.
- [ ] Loading, empty and error states handled.
- [ ] Amounts and weights go through the formatters.
- [ ] Feedback through `AppNotification`.
- [ ] Checked at a narrow phone width and, for web roles, a wide one.
- [ ] Long names truncate with an ellipsis and do not collide with amounts.
