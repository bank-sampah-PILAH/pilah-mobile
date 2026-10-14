import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationStates>(
      builder: (context, state) {
        final auth = state is Authenticated ? state.authEntity : null;
        final name =
            (auth?.name.trim().isNotEmpty ?? false) ? auth!.name : 'Pengurus';
        final bankName = (auth?.bankSampahNama?.trim().isNotEmpty ?? false)
            ? auth!.bankSampahNama!
            : 'Bank Sampah';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Wraps to a second line instead of cutting a long name off.
                  Text.rich(
                    TextSpan(
                      text: 'Selamat datang, $name ',
                      children: const [
                        TextSpan(text: '👋', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppTapTarget(
              label: 'Buka profil',
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                context.push('/profile');
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.greenDark,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
