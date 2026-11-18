import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'layout_breakpoint.dart';

/// Membatasi lebar konten pada layar lebar seperti [ContentBounds], tetapi
/// untuk halaman yang bergulir: batasnya diberikan sebagai **jarak kiri dan
/// kanan** ([insetOf]), bukan sebagai lebar kolom di sekeliling area gulir.
///
/// Dengan begitu area gulir (`ListView`, `SingleChildScrollView`) selebar
/// badan halaman dan scrollbarnya ada di tepi jendela, bukan melayang di
/// tengah layar di tepi kolom 1200 piksel. Konten tetap terpusat dan tidak
/// pernah lebih lebar dari [maxWidth].
///
/// Pasang di atas badan halaman, lalu setiap area gulir menambahkan
/// `ContentFrame.insetOf(context)` ke `padding`-nya, dan bagian yang tidak
/// bergulir (kepala halaman, misalnya) dibungkus [ContentInset]:
///
/// ```dart
/// ContentFrame(
///   child: Column(children: [
///     const ContentInset(child: AppPageHeader(title: 'Judul')),
///     Expanded(
///       child: Builder(
///         builder: (context) => ListView(
///           padding: ContentFrame.insetOf(context).add(const EdgeInsets.all(16)),
///           children: [...],
///         ),
///       ),
///     ),
///   ]),
/// )
/// ```
///
/// Yang diukur adalah lebar yang tersedia bagi badan halaman, bukan lebar
/// jendela: rail di kiri sudah memakan sebagian lebar. Pada compact dan medium
/// tidak ada jarak tambahan, sama seperti [ContentBounds].
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = LayoutBreakpoint.contentMaxWidth,
  });

  final Widget child;

  /// Lebar konten terbesar pada expanded. Formulir memakai
  /// [LayoutBreakpoint.formMaxWidth].
  final double maxWidth;

  /// Jarak horizontal yang harus ditambahkan area gulir ke `padding`-nya;
  /// nol bila tidak ada [ContentFrame] di atasnya.
  static EdgeInsets insetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ContentInset>()?.inset ??
      EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final expanded = context.layoutBreakpoint == LayoutBreakpoint.expanded;
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth - maxWidth;
        final side = expanded && room.isFinite ? math.max(0.0, room / 2) : 0.0;
        return _ContentInset(
          inset: EdgeInsets.symmetric(horizontal: side),
          child: child,
        );
      },
    );
  }
}

/// Memberi bagian yang tidak bergulir jarak yang sama dengan [ContentFrame],
/// supaya sejajar dengan konten area gulir di bawahnya.
class ContentInset extends StatelessWidget {
  const ContentInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: ContentFrame.insetOf(context), child: child);
}

class _ContentInset extends InheritedWidget {
  const _ContentInset({required this.inset, required super.child});

  final EdgeInsets inset;

  @override
  bool updateShouldNotify(_ContentInset oldWidget) => inset != oldWidget.inset;
}
