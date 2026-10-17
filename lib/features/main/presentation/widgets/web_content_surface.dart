import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Latar halaman untuk shell web.
///
/// Pada layar lebar rail berwarna putih dan kartu juga putih. Tanpa latar
/// abu-abu di antaranya, keduanya melebur dengan halaman. Scaffold di setiap
/// halaman mengambil warnanya dari tema, jadi cukup menimpa
/// `scaffoldBackgroundColor` di sini; tema aplikasi dan tampilan telepon tidak
/// berubah.
///
/// Halaman yang mengecat latarnya sendiri (kebanyakan memakai putih) tidak
/// terpengaruh tema, jadi mereka memanggil [pageColor]: abu-abu di dalam shell
/// web, warna lama mereka di tempat lain.
class WebContentSurface extends StatelessWidget {
  const WebContentSurface({super.key, required this.child});

  final Widget child;

  /// Latar halaman: [AppColors.surface] di dalam shell web, selain itu [phone].
  static Color pageColor(BuildContext context, {required Color phone}) =>
      context.getInheritedWidgetOfExactType<_WebSurfaceScope>() != null
          ? AppColors.surface
          : phone;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: AppColors.surface,
        ),
        child: _WebSurfaceScope(
          child: ColoredBox(color: AppColors.surface, child: child),
        ),
      );
}

class _WebSurfaceScope extends InheritedWidget {
  const _WebSurfaceScope({required super.child});

  @override
  bool updateShouldNotify(_WebSurfaceScope oldWidget) => false;
}
