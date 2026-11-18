import 'package:flutter/widgets.dart';

/// Menandai isi yang sedang tampil di dalam dialog, bukan bottom sheet.
///
/// Dialog tidak dapat ditarik, jadi isi yang punya pegangan tarik
/// menyembunyikannya di sini. Penanda ini dibaca [BottomSheetHeader] sendiri,
/// sehingga form yang dipakai di kedua bentuk tidak perlu tahu di mana ia
/// tampil.
class DialogSurface extends InheritedWidget {
  const DialogSurface({super.key, required super.child});

  /// `true` bila [context] berada di bawah [DialogSurface].
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DialogSurface>() != null;

  /// Jarak bawah yang perlu diberikan isi supaya naik di atas papan tik.
  ///
  /// Nol di dalam dialog: `Dialog` sudah naik sendiri sebesar `viewInsets`,
  /// dan menambahkannya lagi mengangkat isi dua kali tinggi papan tik.
  static double keyboardInset(BuildContext context) =>
      of(context) ? 0 : MediaQuery.viewInsetsOf(context).bottom;

  @override
  bool updateShouldNotify(DialogSurface oldWidget) => false;
}
