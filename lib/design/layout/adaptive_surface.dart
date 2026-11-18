import 'package:flutter/material.dart';
import 'dialog_surface.dart';
import 'layout_breakpoint.dart';

/// Menampilkan form atau detail di atas halaman.
///
/// Di telepon tetap modal bottom sheet seperti sebelumnya. Di layar lebar,
/// sheet selebar jendela terlihat janggal, jadi isi yang sama dibungkus dialog
/// dengan lebar terbatas. Isinya tidak diubah; hanya pembungkusnya yang
/// berbeda.
Future<T?> showAdaptiveSurface<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (context.layoutBreakpoint == LayoutBreakpoint.compact) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    // Dialog styling (white, 16 radius, no tint) comes from AppTheme.
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        // Builder, bukan builder(dialogContext) langsung: konteks yang diterima
        // isi harus berada di bawah DialogSurface supaya ia dapat bertanya
        // apakah dirinya sedang di dalam dialog.
        child: DialogSurface(child: Builder(builder: builder)),
      ),
    ),
  );
}
