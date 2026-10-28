import 'package:flutter/material.dart';

/// Latar halaman untuk shell web.
///
/// Latar halaman web sama dengan tampilan telepon: putih. Scaffold di setiap
/// halaman mengambil warnanya dari tema, jadi cukup menimpa
/// `scaffoldBackgroundColor` di sini; tema aplikasi dan tampilan telepon tidak
/// berubah.
///
/// Halaman yang mengecat latarnya sendiri (kebanyakan memakai putih) tidak
/// terpengaruh tema, jadi mereka memanggil [pageColor]: putih di dalam shell
/// web, warna lama mereka di tempat lain.
class WebContentSurface extends StatelessWidget {
  const WebContentSurface({super.key, required this.child});

  final Widget child;

  /// Latar halaman: [Colors.white] di dalam shell web, selain itu [phone].
  static Color pageColor(BuildContext context, {required Color phone}) =>
      context.getInheritedWidgetOfExactType<_WebSurfaceScope>() != null
          ? Colors.white
          : phone;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.white,
        ),
        child: _WebSurfaceScope(
          child: ColoredBox(color: Colors.white, child: child),
        ),
      );
}

class _WebSurfaceScope extends InheritedWidget {
  const _WebSurfaceScope({required super.child});

  @override
  bool updateShouldNotify(_WebSurfaceScope oldWidget) => false;
}
