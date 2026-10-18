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

  @override
  bool updateShouldNotify(DialogSurface oldWidget) => false;
}
