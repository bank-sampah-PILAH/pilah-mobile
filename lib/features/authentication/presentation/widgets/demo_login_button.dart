import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_profile.dart';

class DemoLoginButton extends StatelessWidget {
  final bool isLoading;
  final List<DemoLoginProfile> profiles;

  const DemoLoginButton({
    super.key,
    this.isLoading = false,
    this.profiles = DemoLoginProfiles.all,
  });

  Future<void> _selectProfile(BuildContext context) async {
    final profile = await showModalBottomSheet<DemoLoginProfile>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih akun demo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ),
              ...profiles.map(
                (profile) => ListTile(
                  title: Text(profile.label),
                  subtitle: Text(profile.email),
                  onTap: () => Navigator.of(context).pop(profile),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (profile == null || !context.mounted) return;

    context.read<AuthenticationBloc>().add(
          LoginWithGoogleRequested(
            name: profile.name,
            email: profile.email,
            photoUrl: '',
            idToken: profile.idToken,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : () => _selectProfile(context),
        icon: const Icon(Icons.science_outlined, color: AppColors.greenDark),
        label: Text(
          'Masuk dengan akun demo',
          style: AppTextStyle.headline3.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.grey.shade300),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
