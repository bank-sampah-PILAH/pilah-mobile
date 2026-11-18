import 'package:flutter/widgets.dart';

import 'layout_breakpoint.dart';

/// Membatasi lebar konten pada layar lebar, lalu memusatkannya.
///
/// Pada compact dan medium tidak ada pembatasan: di lebar itu setiap piksel
/// memang dibutuhkan. Pada expanded konten dibatasi
/// [LayoutBreakpoint.contentMaxWidth] supaya panjang baris tetap terbaca,
/// dengan sisa ruang dibagi rata menjadi gutter kiri dan kanan.
///
/// Pembatasan tidak pernah memperkecil konten: bila jendela lebih sempit dari
/// batas, lebar yang tersedia dipakai seutuhnya.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    super.key,
    required this.child,
    this.maxWidth = LayoutBreakpoint.contentMaxWidth,
    this.heightFactor,
  });

  final Widget child;

  /// Batas lebar pada expanded. Bawaannya [LayoutBreakpoint.contentMaxWidth];
  /// formulir memakai [LayoutBreakpoint.formMaxWidth].
  final double maxWidth;

  /// Diteruskan ke [Align.heightFactor]. Bawaannya null: setinggi ruang yang
  /// ada, seperti badan halaman. Isi 1 untuk sebuah bar, misalnya footer di
  /// `bottomNavigationBar`, supaya tingginya mengikuti isinya.
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    if (context.layoutBreakpoint != LayoutBreakpoint.expanded) return child;
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: heightFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
