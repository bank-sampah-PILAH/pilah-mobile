import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';

/// Halaman penuh untuk mencatat setoran.
///
/// Tinggal rangka: latar, header, dan jalan keluar. Seluruh isi dan keadaan
/// formulir ada di [SetoranFormView], supaya panel samping di peramban
/// menjalankan formulir yang sama alih-alih salinan kedua yang harus dijaga
/// agar tetap sejalan.
class TransaksiBaruPage extends StatelessWidget {
  const TransaksiBaruPage({super.key});

  static const route = '/transaksi-baru';

  @override
  Widget build(BuildContext context) {
    void close() => context.pop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SetoranFormView(
        onClose: close,
        header: AppBackHeader(title: 'Transaksi Baru', onBack: close),
      ),
    );
  }
}
