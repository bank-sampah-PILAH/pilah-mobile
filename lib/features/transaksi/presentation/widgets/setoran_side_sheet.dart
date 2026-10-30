import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/setoran_sheet_provider.dart';

/// Route panel setoran, di atas halaman yang sedang terbuka.
///
/// Panel ini **punya route sendiri** dan bukan dialog yang dibuka langsung
/// pada navigator, karena hanya route yang punya entri di riwayat peramban.
/// Tanpa entri itu tombol kembali peramban melewati panel dan mem-pop halaman
/// di belakangnya, membuang isian yang belum tersimpan tanpa bertanya.
const setoranSideSheetPath = '/transaksi-baru/panel';

/// Penanda bahwa panel dibuka dari dalam aplikasi, bukan dari URL.
///
/// `extra` sengaja tidak ikut tersimpan oleh go_router ketika halaman dimuat
/// ulang, dan justru itu yang dipakai di sini: sesudah reload penandanya
/// hilang, [redirectSetoranSideSheet] tahu tidak ada halaman di belakang
/// panel, dan formulir dibuka sebagai halaman penuh.
enum SetoranSheetEntry { fromApp }

/// Formulir dibuka sebagai halaman penuh bila panel dimasuki langsung lewat
/// URL, karena panel tembus pandang di atas layar kosong bukan halaman.
String? redirectSetoranSideSheet(GoRouterState state) =>
    state.extra == SetoranSheetEntry.fromApp ? null : TransaksiBaruPage.route;

/// Halaman route panel setoran, untuk dipasang oleh konfigurasi router.
///
/// Dibangun di sini, bukan di router, supaya chrome panel dan isinya tetap
/// menjadi urusan fitur transaksi.
Page<void> setoranSideSheetPage(LocalKey pageKey) => SideSheetPage<void>(
      key: pageKey,
      // Ditarik pada saat panel hendak ditutup, jadi yang terbaca adalah
      // keadaan formulir saat itu dan bukan saat panel dibuka — yang selalu
      // kosong.
      hasUnsavedInput: () => _formKey.currentState?.hasUnsavedInput ?? false,
      child: Builder(
        builder: (sheetContext) => SetoranFormView(
          key: _formKey,
          header: AppPanelHeader(
            title: 'Transaksi Baru',
            // maybePop, bukan pop: lewat jalan ini penjaga isian yang belum
            // tersimpan ikut bertanya, karena hanya maybePop yang menghormati
            // PopScope. Tombol tutup adalah jalan keluar yang bisa tidak
            // sengaja.
            onClose: () => Navigator.of(sheetContext).maybePop(),
          ),
          // pop, bukan maybePop: jalan ini hanya dilalui setelah setoran
          // berhasil tersimpan. Di sana memang tidak ada lagi yang perlu
          // diselamatkan, dan bertanya justru akan menahan penutupan yang
          // pengguna sudah minta.
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );

/// Deklarasi route panel setoran.
///
/// Satu deklarasi dipakai konfigurasi router aplikasi dan oleh tes yang
/// menjalankan [openSetoranBaru], supaya panel yang diuji adalah panel yang
/// dipasang aplikasi dan bukan salinan yang bisa menyimpang darinya.
GoRoute setoranSideSheetRoute() => GoRoute(
      path: setoranSideSheetPath,
      name: setoranSideSheetPath,
      redirect: (context, state) => redirectSetoranSideSheet(state),
      pageBuilder: (context, state) => setoranSideSheetPage(state.pageKey),
    );

/// Satu kunci untuk satu panel.
///
/// Panel setoran adalah satu route, jadi hanya ada satu formulir panel yang
/// hidup pada satu waktu. Kunci dibuat sekali di sini, bukan di dalam
/// [setoranSideSheetPage], karena pageBuilder dipanggil ulang setiap router
/// membangun ulang dan kunci baru pada tiap build akan membuang state formulir
/// yang sedang diisi.
final _formKey = GlobalKey<SetoranFormViewState>();

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

  // Dibaca dari container, bukan lewat WidgetRef: pemanggilnya bisa saja widget
  // biasa, dan jalan masuk ini tidak perlu memaksa semuanya menjadi Consumer.
  final sheet = ProviderScope.containerOf(context, listen: false).read(
    setoranSheetProvider.notifier,
  );

  sheet.opened();
  try {
    await context.push<void>(
      setoranSideSheetPath,
      extra: SetoranSheetEntry.fromApp,
    );
  } finally {
    // finally, bukan setelah await: panel dapat tertutup lewat barrier, Esc,
    // tombol kembali peramban, atau simpan yang berhasil, dan sorotan rail
    // harus mati pada semuanya — termasuk bila isinya melempar.
    sheet.closed();
  }
}
