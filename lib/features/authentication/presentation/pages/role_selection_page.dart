import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/register_google_role_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/services/di.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  static const route = '/choose-role';

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  GoogleRegistrationRole? _selectedRole;
  GoogleRegistrationRequired? _registration;
  bool _isChangingAccount = false;

  @override
  void initState() {
    super.initState();
    _registration = _registrationFrom(context.read<AuthenticationBloc>().state);
  }

  GoogleRegistrationRequired? _registrationFrom(AuthenticationStates state) {
    return switch (state) {
      GoogleRegistrationPending() => state.registration,
      GoogleRegistrationSubmitting() => state.registration,
      GoogleRegistrationFailure() => state.registration,
      _ => null,
    };
  }

  void _listen(BuildContext context, AuthenticationStates state) {
    final registration = _registrationFrom(state);
    if (registration != null) _registration = registration;

    if (state is Authenticated) {
      context.go(locationForAuthStep(
        state.authEntity.nextStep,
        hasPendingInvite: di<InviteTokenStore>().hasToken,
        role: state.authEntity.role,
      ));
    } else if (state is GoogleRegistrationFailure) {
      AppNotification.showError(
        context,
        title: 'Pendaftaran Gagal',
        message: state.message,
      );
    } else if (state is GoogleRegistrationExpired) {
      context.go(LoginPage.route);
      AppNotification.afterNavigation(
        (context) => AppNotification.showError(
          context,
          title: 'Sesi Berakhir',
          message: state.message,
        ),
      );
    }
  }

  Future<void> _changeAccount() async {
    if (_isChangingAccount) return;
    setState(() => _isChangingAccount = true);

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isChangingAccount = false);
      AppNotification.showError(
        context,
        title: 'Ganti Akun Gagal',
        message: 'Tidak dapat keluar dari akun Google. Silakan coba lagi.',
      );
      return;
    }

    if (!mounted) return;
    context
        .read<AuthenticationBloc>()
        .add(const ChangeGoogleAccountRequested());
    context.go(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final registration = _registration;
    if (registration == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(LoginPage.route);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return BlocConsumer<AuthenticationBloc, AuthenticationStates>(
      listener: _listen,
      builder: (context, state) {
        final isLoading = state is GoogleRegistrationSubmitting;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Langkah 1',
                            style: AppTextStyle.small.copyWith(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 4),
                        Text('Daftar Akun', style: AppTextStyle.headline1),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih peran yang sesuai untuk melanjutkan pendaftaran.',
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.grey100,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _VerifiedIdentity(
                          name: registration.name,
                          email: registration.email,
                          onChangeAccount: isLoading || _isChangingAccount
                              ? null
                              : _changeAccount,
                        ),
                        const SizedBox(height: 32),
                        Text('Saya ingin mendaftar sebagai',
                            style: AppTextStyle.title1),
                        const SizedBox(height: 16),
                        for (var index = 0;
                            index < _roleOptions.length;
                            index++) ...[
                          _RoleCard(
                            option: _roleOptions[index],
                            selected:
                                _selectedRole == _roleOptions[index].value,
                            enabled: !isLoading,
                            onTap: () => setState(() =>
                                _selectedRole = _roleOptions[index].value),
                          ),
                          if (index < _roleOptions.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenDark.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null || isLoading
                          ? null
                          : () => context.read<AuthenticationBloc>().add(
                                RegisterGoogleRoleRequested(
                                  role: _selectedRole!,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Lanjutkan'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VerifiedIdentity extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback? onChangeAccount;

  const _VerifiedIdentity({
    required this.name,
    required this.email,
    required this.onChangeAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.grey100,
            child: Icon(Icons.verified_user_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyle.headline3),
                Text(email,
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
                    )),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeAccount,
            child: const Text('Ganti akun'),
          ),
        ],
      ),
    );
  }
}

class _RoleOption {
  final GoogleRegistrationRole value;
  final String title;
  final String description;
  final IconData icon;

  const _RoleOption(this.value, this.title, this.description, this.icon);
}

const _roleOptions = [
  _RoleOption(
    GoogleRegistrationRole.nasabah,
    'Nasabah',
    'Menabung sampah dan memantau saldo.',
    Icons.recycling_outlined,
  ),
  _RoleOption(
    GoogleRegistrationRole.pengelola,
    'Pengelola Bank Sampah',
    'Mengelola transaksi dan anggota bank sampah.',
    Icons.storefront_outlined,
  ),
  _RoleOption(
    GoogleRegistrationRole.pengelolaInduk,
    'Pengelola Bank Sampah Induk',
    'Mendampingi unit-unit bank sampah.',
    Icons.account_balance_outlined,
  ),
];

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${option.title}. ${option.description}',
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.greenDark : AppColors.grey200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(option.icon, color: AppColors.greenDark, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: AppTextStyle.headline3),
                        const SizedBox(height: 4),
                        Text(option.description,
                            style: AppTextStyle.small.copyWith(
                              color: AppColors.grey100,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? AppColors.greenDark : AppColors.grey100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
