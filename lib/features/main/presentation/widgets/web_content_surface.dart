import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Latar halaman untuk shell web.
///
/// Pada layar lebar rail berwarna putih dan kartu juga putih. Tanpa latar
/// abu-abu di antaranya, keduanya melebur dengan halaman. Scaffold di setiap
/// halaman mengambil warnanya dari tema, jadi cukup menimpa
/// `scaffoldBackgroundColor` di sini; tema aplikasi dan tampilan telepon tidak
/// berubah.
class WebContentSurface extends StatelessWidget {
  const WebContentSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: AppColors.surface,
        ),
        child: ColoredBox(color: AppColors.surface, child: child),
      );
}
