import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_flow_layout.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/services/di.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  static const route = '/choose-role';

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  GoogleRegistrationRole? _selectedRole;
  GoogleRegistrationRequired? _registration;
  bool _isChangingAccount = false;

  @override
  void initState() {
    super.initState();
    _registration = _registrationFrom(ref.read(authenticationProvider));
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
    ref.read(authenticationProvider.notifier).changeGoogleAccount();
    context.go(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationProvider, (previous, state) {
      _listen(context, state);
    });
    final state = ref.watch(authenticationProvider);
    final registration = _registration;
    if (registration == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(LoginPage.route);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final isLoading = state is GoogleRegistrationSubmitting;
    final isBusy = isLoading || _isChangingAccount;
    final roleOptions = _roleOptions
        .where((option) => isRoleSupportedOnPlatform(
              option.value.wireValue,
              isWeb: kIsWeb,
            ))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: OnboardingFlowLayout(
        title: 'Daftar Akun',
        subtitle: 'Pilih peran yang sesuai untuk melanjutkan pendaftaran.',
        onExit: isBusy ? null : _changeAccount,
        progress: const OnboardingProgress(currentStep: 0),
        actions: OnboardingActions(
            primary: AppButton(
          label: 'Lanjutkan',
          trailingIcon: Icons.arrow_forward,
          isLoading: isLoading,
          onPressed: _selectedRole == null || _isChangingAccount
              ? null
              : () => ref
                  .read(authenticationProvider.notifier)
                  .registerGoogleRole(_selectedRole!),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerifiedIdentity(
              name: registration.name,
              email: registration.email,
              onChangeAccount: isBusy ? null : _changeAccount,
            ),
            const SizedBox(height: 24),
            Text('Saya ingin mendaftar sebagai', style: AppTextStyle.title1),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final paired =
                  constraints.maxWidth >= LayoutBreakpoint.mediumMinWidth &&
                      MediaQuery.textScalerOf(context).scale(16) <= 24;
              Widget roleCard(_RoleOption option) => _RoleCard(
                    option: option,
                    selected: _selectedRole == option.value,
                    enabled: !isBusy,
                    onTap: () => setState(() => _selectedRole = option.value),
                  );

              if (!paired) {
                return Wrap(
                  runSpacing: 16,
                  children: [
                    for (final option in roleOptions)
                      SizedBox(
                        width: constraints.maxWidth,
                        child: roleCard(option),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0;
                      index < roleOptions.length;
                      index += 2) ...[
                    if (index > 0) const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: roleCard(roleOptions[index])),
                          const SizedBox(width: 16),
                          Expanded(
                            child: index + 1 < roleOptions.length
                                ? roleCard(roleOptions[index + 1])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final identity = Row(children: [
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
                  style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
            ],
          )),
        ]);
        final changeAccount = TextButton(
            onPressed: onChangeAccount, child: const Text('Ganti akun'));
        if (constraints.maxWidth < LayoutBreakpoint.mediumMinWidth ||
            MediaQuery.textScalerOf(context).scale(16) > 24) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 8),
                changeAccount,
              ]);
        }
        return Row(children: [Expanded(child: identity), changeAccount]);
      }),
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
    'Pengurus Bank Sampah',
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
      checked: selected,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
