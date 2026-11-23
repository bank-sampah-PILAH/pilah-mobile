/// Icons in `lib/` whose glyph is not a literal `Icons.x`, counted per file
/// (path below `lib/`).
///
/// The screen recording shows every icon (see `replayTextMask`), so an icon
/// chosen from what a person or a bank sampah *is* (a gender, an approval
/// status) would be readable in it. Such an icon must be wrapped in
/// `HideInReplay`. The icons below were judged when this list was made, by
/// what decides them: the UI (expanded or not, sorted up or down), the catalog
/// (a jenis sampah), a fixed destination, or a caller. An icon passed in by a
/// caller was not traced to every caller, so a caller that passes an icon from
/// data must wrap it itself.
///
/// The list is a ratchet: a new non-literal icon fails the test until it is
/// either wrapped in `HideInReplay` or added here, and a file that lost one
/// must lower its number. Do not raise a number to make the test pass without
/// reading where the icon comes from.
const replayIconBaseline = <String, int>{
  'core/bases/widgets/empty_view.dart': 1,
  'core/bases/widgets/proof_image_dialog.dart': 1,
  'core/notifications/notifications_page.dart': 1,
  'design/widgets/app_button.dart': 2,
  'design/widgets/app_chip.dart': 2,
  'design/widgets/app_dialog.dart': 1,
  'design/widgets/app_icon_button.dart': 1,
  'design/widgets/app_panel_header.dart': 1,
  'design/widgets/atom/app_text_field.dart': 1,
  'design/widgets/nasabah_activity_card.dart': 1,
  'features/authentication/presentation/pages/role_selection_page.dart': 2,
  'features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart':
      2,
  'features/beranda/presentation/widgets/nasabah_bank_detail.dart': 1,
  'features/dashboard/presentation/widgets/dashboard_report_widgets.dart': 1,
  'features/dashboard/presentation/widgets/stat_card.dart': 1,
  'features/dashboard/presentation/widgets/transaksi_chooser_sheet.dart': 1,
  'features/draft_pencairan/presentation/pages/draft_list_page.dart': 1,
  'features/draft_pencairan/presentation/widgets/editor_summary_panel.dart': 1,
  'features/draft_pencairan/presentation/widgets/export_menu_button.dart': 1,
  'features/draft_pencairan/presentation/widgets/pencairan_konfirmasi_sheet.dart':
      1,
  'features/draft_pencairan/presentation/widgets/pencairan_sort_button.dart': 1,
  'features/draft_pencairan/presentation/widgets/pencairan_ui.dart': 1,
  'features/draft_pencairan/presentation/widgets/saldo_min_sheet.dart': 1,
  'features/harga/presentation/pages/harga_page.dart': 1,
  'features/harga/presentation/widgets/harga_detail_sheet.dart': 1,
  'features/harga/presentation/widgets/harga_table.dart': 1,
  'features/harga/presentation/widgets/jenis_sampah_form.dart': 1,
  'features/jadwal/presentation/pages/jadwal_page.dart': 1,
  'features/jadwal/presentation/widgets/jadwal_calendar.dart': 1,
  'features/cari_bank/presentation/pages/cari_bank_page.dart': 2,
  'features/legal/presentation/pages/legal_information_page.dart': 1,
  'features/map/presentation/pages/map_picker_page.dart': 1,
  'features/main/presentation/widgets/role_navigation_bar.dart': 1,
  'features/main/presentation/widgets/role_navigation_drawer.dart': 1,
  'features/main/presentation/widgets/role_navigation_rail.dart': 1,
  'features/main/presentation/widgets/role_transaction_menu.dart': 2,
  'features/onboarding/presentation/pages/role_handoff_page.dart': 1,
  'features/profile/presentation/pages/profil_nasabah_page.dart': 1,
  'features/profile/presentation/pages/profile_page.dart': 1,
  'features/superadmin/presentation/pages/superadmin_dashboard_screen.dart': 1,
  'features/transaksi/presentation/widgets/aktivitas_list_view.dart': 1,
  'features/transaksi/presentation/widgets/aktivitas_table.dart': 1,
  'features/transaksi/presentation/widgets/item_setoran_card.dart': 1,
  'features/transaksi/presentation/widgets/periode_picker_sheet.dart': 1,
  'features/transaksi/presentation/widgets/pilih_jenis_sampah_picker.dart': 1,
};
