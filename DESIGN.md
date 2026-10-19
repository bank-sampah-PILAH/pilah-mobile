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
| Danger (errors, destructive actions) | `AppColors.danger`, tint `AppColors.dangerLight` | `#C62828`, `#FEF2F2` | in code; WCAG AA (5.6:1 on white, 5.1:1 on the tint) |
| Warning (pending, draft, caution) | `AppColors.warning`, tint `AppColors.warningLight` | `#976200`, `#FEF3C7` | in code; WCAG AA (5.2:1 on white, 4.6:1 on the tint) |
| Page / card background | `AppColors.surface` | `#F9FAFB` | in code |
| Chips, inputs, badges | `AppColors.fill` | `#F3F4F6` | in code |
| Dividers and outlines | `AppColors.border` | `#E5E7EB` | in code |
| Strong secondary text | `AppColors.inkSoft` | `#374151` | in code; 10:1 on white |

Avatars are the one place that keeps several hues on purpose. The list avatars (`core/utils/avatar_style.dart`) are light tints with dark initials, six pairs, guarded in `test/core/utils/avatar_style_contrast_test.dart`. The profile header avatar picks from `AppColors.avatarFills` (dark fills behind white initials), guarded in `test/design/contrast_test.dart`. The gender icons in the profile form are neutral (`AppColors.inkSoft`), not blue and pink.

Retired colors: the greys, ambers, green tints and reds that used to be copied into screens are listed in `test/design/retired_palette_test.dart`, which fails if one comes back. If a screen needs a new color, add a token here and a contrast pair in `test/design/contrast_test.dart` instead of a literal.

Flutter's stock palette is guarded too: `Colors.grey`, `Colors.black87`, `Colors.red` and the like are not the app's colours (`Colors.grey` is `#9E9E9E`, 2.7:1 on white, below WCAG AA for text). `test/design/hardcoded_material_colors_test.dart` fails on a new one outside `lib/design/`; the existing ones are in its baseline and can only go down. `Colors.white` and `Colors.transparent` are fine.

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
| Radius | 8 (chips, small tiles), 12 (inputs, buttons), 16 (cards, dialogs), 24 (sheets, hero cards) | **in code**: `AppRadius.sm`, `md`, `lg`, `xl` (`lib/design/constants/radius.dart`). A bare number in `BorderRadius.circular(...)` fails `test/design/hardcoded_radius_test.dart`; the 44 off-scale ones left (10, 18, 20 and so on) are in its baseline and can only go down. |
| Spacing | 4, 8, 12, 16, 24, 32 | **in code**: `AppSpacing.xs` … `xxl` (`lib/design/constants/spacing.dart`), plus `webGutter` and `webTop` for the web shell. Existing screens still use bare numbers; move them over as you touch them. |
| Content width | 600 max on nasabah pages (`NasabahStyle.maxWidth`, `ContentBounds`) | in code |

### Surfaces (**in code**, `lib/design/theme/app_theme.dart`)

- Dialogs: white, 16 radius, no Material tint.
- Bottom sheets: white, 24 top radius, no tint.
- Pages: a `Scaffold` with no background of its own is white (`AppTheme.scaffoldBackgroundColor`); the Material default was a green-tinted off-white that made a screen unlike the rest.
- App bars: white, no scroll tint, 18/w600 Poppins title.
- Web shell (browser, wide): the navigation rail is a white panel with a 1 px `AppColors.border` on its right edge; pages sit on white, the same as on the phone, and their cards stay white with a 1 px border. A page that paints its own `Scaffold` background must not hard-code a colour: call `WebContentSurface.pageColor(context, phone: …)`, which gives white inside the web shell and the phone colour everywhere else.
- Web page header (**in code**, `AppPageHeader`): every tab page in the web shell starts the same way. The body has `AppSpacing.webGutter` (32) left and right and `AppSpacing.webTop` (24) above the title. Title (`headline1`), optional subtitle, a 360 wide search and the page actions share one row on an expanded window; below that the search drops under the title. Do not build a page title, search placement or `AppBar` per page. Lists of records follow the same split: on a wide window Daftar Nasabah (`NasabahTable`) and Jenis Sampah & Harga (`HargaTable`) are tables with a header row, hover and a tinted selected row, and on a phone they are cards. Tapping a jenis sampah opens its detail (`HargaDetailSheet`: a bottom sheet on a phone, a dialog on a wide window) with two actions, Edit and Riwayat harga; editing is never the direct result of a tap. On an expanded window that detail, the edit form and the price history (`RiwayatHargaContent`, a timeline with the change from the version before) take turns in one side panel beside the table (`HargaDetailFlow`), so the table stays visible; below it they are a bottom sheet. The panel and the pair around it reach the right edge of the window: the shell no longer centres the body, `MasterDetailLayout` bounds the list to the content width only while no panel is open. Jadwal Kegiatan puts the month calendar (400 wide, always the whole month) beside the agenda when the list is at least 900 wide, and stacks them, with the week or month toggle, below that or while the form panel is open. Rail labels are 12 (`AppTextStyle.small`) in both the expanded and the narrow rail, in `AppColors.inkSoft`; the selected item uses `greenDark` on a `greenLight` indicator.
- Profile page (**in code**, `ProfilePage`): in the browser it is a destination of the shell, opened with `goBranch` from the rail profile tile, so the rail stays and no menu item is marked; it has the web page header and gutter and no back button. The account card is white with an outline in both the browser and the app: identity (avatar, name, role badge, email), with **Keluar** on its right in the browser and as the last item of the page in the app. **Simpan** is not on the page until a field changes; then a bar appears with "Perubahan belum disimpan" and goes away once saved.
- Menus (**in code**, `AppTheme`): a dropdown's list and a `PopupMenuButton` are white, not the seed-tinted canvas; hovered and focused rows are the soft green of a hovered table row (`greenLight` at 45%). A popup menu has a 12 radius and an `AppColors.border` outline. A `DropdownButton` takes its radius from a parameter, so pass `borderRadius: BorderRadius.circular(AppRadius.md)`; the framework gives it a shadow rather than an outline.
- Cards: white, flat, 16 radius, a 1 dp `AppColors.border` outline, no tint and no margin (put the margin where the card sits). A stock `Card(...)` needs no `color`, `shape` or `elevation`.

## 3. Components

Use these instead of building another one.

| Need | Use | Notes |
|---|---|---|
| Sheet header (title + close) | `BottomSheetHeader`, `AppSheetHandle` (`design/widgets`) | `BottomSheetHeader` already draws the drag handle. A sheet that lays out its own header uses `AppSheetHandle`; do not hand-build the bar. |
| Panel of a bottom sheet | `AppSheetContainer` (`design/widgets`) | White, 24 rounded top, rises above the keyboard, clears the system bar and scrolls. Put the sheet's own `Column` (or a `Form`) inside. |
| Label and value line of a detail | `AppDetailRow` (`design/widgets`) | `Metode  Tunai`: muted 13 label left, 13 medium value right; a long value wraps. Used by the pencairan and setoran sheets and the revisi page. |
| Header of a full Pengurus page | `AppBackHeader` (`design/widgets`) | Grey back button ("Kembali", 48 dp), a 20 bold title and optional `actions`. Without `onBack` it uses `maybePop`, so a `PopScope` is asked. Do not build a stock `AppBar`: `test/design/hardcoded_app_bars_test.dart` fails on a new one. |
| Caption above a form field | `AppFieldLabel` (`design/widgets`) | `NAMA LENGKAP`: small bold capitals in `AppColors.grey100`, hint inside the field. Do not use a floating `labelText`. |
| Button | `AppButton` (`design/widgets`) | Variants `primary`, `outlined`, `neutral` (cancel, back), `destructive`, `destructiveOutlined`, `warning`, `warningOutlined`, `tonal` (soft green, beside a primary) and `text` (a bare link inside a line of content). `size: AppButtonSize.compact` is 40 high with a 12 label and a 16 icon, for an action inside a card or a row; the regular size is 48 high, radius 12, 14 semibold label. Optional leading or trailing icon, `isLoading` and `expand`. A plain `ElevatedButton`, `FilledButton` or `OutlinedButton` already gets the same look from `AppTheme`, so do not write `styleFrom` per screen: `test/design/hardcoded_button_styles_test.dart` fails on a new one. |
| Search | `CustomSearchField` | On a web tab page put it in `AppPageHeader`'s `search` slot, which sets the 360 width and the place. |
| Header of a side panel or sheet view | `AppPanelHeader` (`design/widgets`) | The only header of a panel view: back at the left (only in a view inside another view, always to its parent), title and a subtitle, close at the right (not in a sheet, which is dragged away). Fixed 56 high so the content under it does not jump between views; back and close are the same 40 dp ghost icon button. |
| Header of a web tab page | `AppPageHeader` (`design/layout`) | Title, optional subtitle, search and `actions` on one row in an expanded window, search under the title below it. Pair with `AppSpacing.webGutter` and `webTop` padding. Used by Daftar Nasabah, Jenis Sampah & Harga, Riwayat Aktivitas and Jadwal Kegiatan. |
| Status chip | `CustomStatusBadge` | |
| Filter / tab pill | `AppChip` (`design/widgets`) | Announced to screen readers as a selected or unselected button, ripple, 48 dp hit area, optional icon and count. Used by the nasabah, harga, aktivitas and pencairan filters and the metode of both pencairan forms; `PencairanChip` wraps it. `test/design/single_chip_test.dart` fails on a stock `ChoiceChip(` or `FilterChip(`. |
| Tappable icon, link or field | `AppTapTarget` (`design/widgets`) | Button role, optional `label` for icon-only controls, ripple, 48 dp hit area, optional selected state for options in a group. Use instead of a bare `GestureDetector`. |
| Tappable white card | `AppTappableCard` (`design/widgets`) | Button role that reads the card's own text, ripple on top of the fill. Used by the nasabah, harga and membership cards. A card that also holds its own actions (the Jadwal card with Batalkan and Terbitkan) wraps the whole card, action row included, in one `InkWell` with the soft green `hoverColor`, so the hover and ripple reach the rounded edge; `AppTappableCard` is not used there because it merges the buttons into one semantics node. |
| Confirm dialog | `showAppConfirmDialog` (`core/bases/widgets`) | A plain yes or no; answers `true` only on confirm. Built on `AppDialog`. Used by logout, leaving onboarding, Jadwal, pencairan and superadmin approvals. |
| Dialog with a form | `AppDialog` (`design/widgets`) | Title, a message or any `content` (a text field, for instance), a quiet cancel and a confirm `AppButton`; `destructive` paints confirm red. |
| Decision about a person or an item | `AppIconDialog` (`design/widgets`) | An icon in a tinted circle (`AppDialogTone.positive`, `warning`, `danger`), a centred title, a message with spans so a name can be bold, and two equal buttons. `isLoading` locks both while the action runs. Used to activate or deactivate a nasabah or a jenis sampah. `test/design/hardcoded_dialogs_test.dart` fails on a new `AlertDialog(` or `Dialog(` in a screen. |
| Empty state | `EmptyView` | |
| Loading list | `SkeletonListItem` | Avoid a bare spinner for lists. |
| Loading / empty / error / content in one | `PageStateView` (`design/layout`) | New; adopt on new pages. |
| Pull to refresh | `AppRefreshIndicator` | |
| Feedback after an action | `AppNotification.showSuccess` / `showError` / `showWarning` | Do not use `SnackBar`. |
| Form field look | `appInputDecoration`, `appInputStyle` (`design/constants/form_style.dart`) | White, 12 rounded, green focus, `AppColors.danger` on error. Takes `hintText`, `errorText`, `prefixText`, `prefixIcon`, `suffixIcon`, `hasError` and `focusColor` (seven at most, which SonarCloud allows); add a `labelText` or `helperText` with `copyWith` on the result; use `PhonePrefix` for the "+62" of a phone field. Text-field borders are intentionally not in the theme, so build the decoration through these functions: `test/design/hardcoded_input_decoration_test.dart` fails on a new raw `InputDecoration(`. |
| Search field, value inside a card | `appSearchDecoration`, `appBorderlessInputDecoration` (same file) | Soft fill with no outline and a search icon; no border at all. `CustomSearchField` and `NasabahSearchBar` use the first. |
| Labelled text field with a password toggle | `AppTextField` (`design/widgets/atom`) | Built on `appInputDecoration`. |
| Nasabah cards and app bar | `NasabahCard`, `NasabahPageAppBar` | `NasabahPageAppBar(showBack: true)` for a Nasabah page reached from another one (approval, bank detail, PDF preview). |
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
- [ ] Loading, empty and error states handled.
- [ ] Amounts and weights go through the formatters.
- [ ] Feedback through `AppNotification`.
- [ ] Checked at a narrow phone width and, for web roles, a wide one.
- [ ] Long names truncate with an ellipsis and do not collide with amounts.
