import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'layout_breakpoint.dart';

/// Wadah yang dipakai sebuah picker modal pada lebar jendela tertentu.
///
/// Dipisahkan dari widget mana pun supaya aturannya dapat diuji tanpa
/// membangun tree, dan supaya keempat picker pada fitur transaksi memakai
/// jawaban yang sama alih-alih masing-masing memeriksa MediaQuery.
///
/// Perhatikan bahwa pembedanya di sini adalah **lebar**, bukan platform seperti
/// pada [NavigationForm]. Aturan lead dev — bottom bar di aplikasi, navigasi
/// kiri di peramban — berbicara tentang navigasi yang menetap di layar. Picker
/// bersifat sementara, dan panduan Material mengikat wadahnya ke window size
/// class: bottom sheet adalah pola jendela compact, dialog untuk medium ke
/// atas. Kedua aturan toh sepakat di tempat yang penting, karena telepon
/// native selalu compact.
enum PickerPresentation {
  /// Menempel di tepi bawah. Benar pada telepon, tempat jempol berada.
  bottomSheet,

  /// Kotak di tengah jendela. Benar pada peramban, dekat tempat kursor menekan.
  dialog;

  /// Lebar dialog, dalam logical pixel.
  ///
  /// Daftar nasabah adalah baris nama pendek; melebarkannya sampai memenuhi
  /// monitor hanya memperbesar jarak tempuh mata dari nama ke saldo. 480 cukup
  /// untuk baris terpanjang pada daftar ini dan selalu masuk: jendela medium
  /// paling sempit adalah 600 px, dan setelah inset bawaan Dialog masih
  /// tersisa 520 px.
  static const double dialogWidth = 480;

  /// Batas tinggi dialog, dalam logical pixel.
  static const double dialogMaxHeight = 640;

  /// Porsi tinggi jendela yang diambil wadah picker.
  static const double heightFactor = 0.85;

  /// Apakah wadah ini menampilkan drag handle.
  ///
  /// Handle menjanjikan sesuatu yang dapat ditarik. Dialog tidak dapat ditarik,
  /// jadi pada dialog handle itu sebuah janji palsu.
  bool get showsDragHandle => this == bottomSheet;

  /// Mengklasifikasikan [width] logical pixel ke dalam satu wadah.
  ///
  /// Lebar non-positif menjadi [bottomSheet], mengikuti
  /// [LayoutBreakpoint.fromWidth], karena frame pertama bisa berjalan sebelum
  /// ukuran diketahui.
  static PickerPresentation resolve({required double width}) =>
      LayoutBreakpoint.fromWidth(width) == LayoutBreakpoint.compact
          ? bottomSheet
          : dialog;
}

/// Membuka [builder] pada wadah yang sesuai dengan lebar jendela saat ini.
///
/// Seluruh chrome wadah — tinggi, sudut, warna latar, penghindaran papan tik —
/// ada di sini, bukan di dalam [builder]. Itulah yang membuat isi picker dapat
/// dipakai pada kedua wadah: ia hanya tahu cara menampilkan daftarnya, dan
/// menerima [PickerPresentation] semata untuk hal yang memang berbeda di mata
/// pengguna, seperti drag handle.
///
/// Mengembalikan nilai yang di-pop oleh isi picker, atau null bila ditutup
/// tanpa memilih.
Future<T?> showAdaptivePicker<T>({
  required BuildContext context,
  required Widget Function(
          BuildContext context, PickerPresentation presentation)
      builder,
}) {
  final size = MediaQuery.sizeOf(context);
  final presentation = PickerPresentation.resolve(width: size.width);

  // Sama untuk kedua wadah, supaya pindah wadah tidak ikut menggeser isi.
  const padding = EdgeInsets.fromLTRB(16, 16, 16, 0);

  switch (presentation) {
    case PickerPresentation.bottomSheet:
      return showModalBottomSheet<T>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Padding(
          // Papan tik mendorong sheet ke atas alih-alih menutupi kolom cari.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            height: size.height * PickerPresentation.heightFactor,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: padding,
            child: builder(sheetContext, presentation),
          ),
        ),
      );

    case PickerPresentation.dialog:
      return showDialog<T>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          // Ukuran eksplisit, bukan sekadar batas: Dialog memberi anaknya
          // constraint longgar, dan isi picker memakai Expanded yang menuntut
          // tinggi yang terbatas.
          child: SizedBox(
            width: PickerPresentation.dialogWidth,
            height: math.min(
              size.height * PickerPresentation.heightFactor,
              PickerPresentation.dialogMaxHeight,
            ),
            child: Padding(
              padding: padding,
              child: builder(dialogContext, presentation),
            ),
          ),
        ),
      );
  }
}

/// Membuka [builder] sebagai konfirmasi: bottom sheet pada telepon, dialog di
/// tengah pada peramban.
///
/// Memakai keputusan yang sama dengan [showAdaptivePicker] tetapi rangka yang
/// berbeda, dan itu disengaja. Picker setinggi jendela karena isinya daftar
/// yang bergulir; konfirmasi memeluk isinya, karena isinya beberapa baris yang
/// sudah diketahui. Menyatukan keduanya di balik satu bendera akan membuat satu
/// fungsi yang separuh parameternya tidak berlaku pada separuh pemakaiannya.
///
/// [dismissible] false menutup kedua jalan keluar — tekan di luar dan tombol
/// kembali — untuk konfirmasi yang memang menuntut sebuah pilihan.
Future<T?> showAdaptiveConfirmation<T>({
  required BuildContext context,
  required Widget Function(
          BuildContext context, PickerPresentation presentation)
      builder,
  bool dismissible = true,
}) {
  final presentation =
      PickerPresentation.resolve(width: MediaQuery.sizeOf(context).width);

  const padding = EdgeInsets.all(24);

  switch (presentation) {
    case PickerPresentation.bottomSheet:
      return showModalBottomSheet<T>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        isDismissible: dismissible,
        enableDrag: dismissible,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: padding,
          child: builder(sheetContext, presentation),
        ),
      );

    case PickerPresentation.dialog:
      return showDialog<T>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: dismissible,
        builder: (dialogContext) => PopScope(
          canPop: dismissible,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            // Lebar tetap, tinggi mengikuti isi: tidak ada daftar yang bergulir
            // di sini, jadi memaksakan tinggi hanya menambah ruang kosong.
            child: SizedBox(
              width: PickerPresentation.dialogWidth,
              child: Padding(
                padding: padding,
                child: builder(dialogContext, presentation),
              ),
            ),
          ),
        ),
      );
  }
}
