import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/setoran_sheet_provider.dart';

/// Membuka formulir setoran sebagaimana jendela ini seharusnya menampilkannya.
///
/// Satu-satunya jalan masuk ke formulir setoran. Tombol di dashboard, menu
/// Tambah Transaksi di rail web, dan jalan masuk lain memanggil ini alih-alih
/// memilih sendiri, supaya ketiganya tidak menjawab pertanyaan yang sama
/// dengan tiga cara berbeda.
///
/// Pada jendela sempit dan di aplikasi, formulir tetap sebuah halaman penuh
/// pada route-nya yang sudah ada: di lebar itu tidak ada ruang untuk
/// menyisakan halaman di belakangnya, dan route itu sudah bekerja. Dari
/// breakpoint medium ke atas ia menjadi panel di tepi kanan, dengan halaman
/// yang sedang dibuka tetap terlihat di belakangnya.
Future<void> openSetoranBaru(BuildContext context) async {
  final presentation = SideSheetPresentation.resolve(
    width: MediaQuery.sizeOf(context).width,
  );

  if (presentation == SideSheetPresentation.fullScreen) {
    await context.push(TransaksiBaruPage.route);
    return;
  }

  final formKey = GlobalKey<SetoranFormViewState>();
  // Dibaca dari container, bukan lewat WidgetRef: pemanggilnya bisa saja widget
  // biasa, dan jalan masuk ini tidak perlu memaksa semuanya menjadi Consumer.
  final sheet = ProviderScope.containerOf(context, listen: false).read(
    setoranSheetProvider.notifier,
  );

  sheet.opened();
  try {
    await _showSetoranSheet(context, formKey);
  } finally {
    // finally, bukan setelah await: panel dapat tertutup lewat barrier, Esc,
    // tombol kembali peramban, atau simpan yang berhasil, dan sorotan rail
    // harus mati pada semuanya — termasuk bila isinya melempar.
    sheet.closed();
  }
}

Future<void> _showSetoranSheet(
  BuildContext context,
  GlobalKey<SetoranFormViewState> formKey,
) async {
  await showSideSheet<void>(
    context: context,
    // Ditarik pada saat panel hendak ditutup, jadi yang terbaca adalah keadaan
    // formulir saat itu dan bukan saat panel dibuka — yang selalu kosong.
    hasUnsavedInput: () => formKey.currentState?.hasUnsavedInput ?? false,
    builder: (sheetContext) => SetoranFormView(
      key: formKey,
      header: AppPanelHeader(
        title: 'Transaksi Baru',
        // maybePop, bukan pop: lewat jalan ini penjaga isian yang belum
        // tersimpan ikut bertanya, karena hanya maybePop yang menghormati
        // PopScope. Tombol tutup adalah jalan keluar yang bisa tidak sengaja.
        onClose: () => Navigator.of(sheetContext).maybePop(),
      ),
      // pop, bukan maybePop: jalan ini hanya dilalui setelah setoran berhasil
      // tersimpan. Di sana memang tidak ada lagi yang perlu diselamatkan, dan
      // bertanya justru akan menahan penutupan yang pengguna sudah minta.
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}
