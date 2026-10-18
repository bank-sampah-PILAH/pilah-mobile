import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

import 'content_bounds.dart';
import 'layout_breakpoint.dart';

/// Pola daftar dan detail berdampingan untuk layar lebar.
///
/// Pada compact hanya [master] yang dirender dan [detail] diabaikan: di
/// telepon detail tetap dibuka sebagai modal bottom sheet oleh layarnya
/// sendiri, sebagaimana sekarang. Pada medium dan expanded [detail] muncul
/// sebagai panel di samping daftar.
///
/// Dibuat agar konversi dapat bertahap. Sebuah layar cukup menyimpan sendiri
/// item yang sedang dipilih, lalu meneruskannya sebagai [detail] ketika ada;
/// tidak ada yang perlu diubah pada perilaku sheet-nya di telepon.
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterFlex = 3,
    this.detailFlex = 2,
  });

  /// Daftar, dan permukaan utama layar.
  final Widget master;

  /// Detail item terpilih, atau null bila tidak ada yang dipilih.
  final Widget? detail;

  /// Proporsi lebar daftar terhadap panel. Bawaan 3:2, sehingga daftar tetap
  /// lebih lebar: daftar adalah permukaan utama dan panel menunjangnya.
  final int masterFlex;
  final int detailFlex;

  @override
  Widget build(BuildContext context) {
    final split =
        context.layoutBreakpoint != LayoutBreakpoint.compact && detail != null;
    // Sendiri, daftar dibatasi lebarnya. Dengan panel, daftar dan panel
    // mengisi seluruh lebar: panel menempel di tepi kanan jendela, bukan
    // mengambang di tengah dengan ruang kosong di kanannya.
    if (!split) return ContentBounds(child: master);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: masterFlex, child: master),
        const VerticalDivider(width: 1, color: AppColors.grey200),
        Expanded(flex: detailFlex, child: detail!),
      ],
    );
  }
}
