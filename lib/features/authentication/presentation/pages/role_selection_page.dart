import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
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
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  static const route = '/choose-role';

  /// The title a role is offered under here, for screens that name the role
  /// being registered; null for a role this page does not offer.
  static String? titleFor(String? role) => _roleOptions
      .where((option) => option.value.wireValue == role)
      .firstOrNull
      ?.title;

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  GoogleRegistrationRole? _selectedRole;
  GoogleRegistrationRequired? _registration;
  bool _isChangingAccount = false;

  /// The signed-in account picking again (PIL-451): its role was saved when it
  /// first tapped Lanjutkan, and it may still change it while the profile step
  /// is unfinished. Null when this page serves a fresh Google registration.
  AuthEntity? _account;
  bool _isChangingRole = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(authenticationProvider);
    _registration = _registrationFrom(state);
    if (_registration == null &&
        state is Authenticated &&
        state.authEntity.nextStep == 'complete_profile') {
      _account = state.authEntity;
      _selectedRole = GoogleRegistrationRole.values
          .where((role) => role.wireValue == state.authEntity.role)
          .firstOrNull;
    }
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
      // A draft typed for the old role must not prefill the new role's form.
      if (_account != null) {
        ref.read(onboardingProvider.notifier).clearProfileDraft();
      }
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

  /// Lanjutkan: a fresh registration creates the account with [role]; a
  /// signed-in account switches to it.
  void _submit(GoogleRegistrationRole role) {
    if (_account != null) {
      _changeRole(role);
    } else {
      ref.read(authenticationProvider.notifier).registerGoogleRole(role);
    }
  }

  /// Lanjutkan for a signed-in account. Success arrives as a new
  /// [Authenticated] session, which [_listen] routes on; a refusal keeps the
  /// account where it was and says why.
  Future<void> _changeRole(GoogleRegistrationRole role) async {
    setState(() => _isChangingRole = true);
    final error =
        await ref.read(authenticationProvider.notifier).changeRole(role);
    if (!mounted || error == null) return;
    setState(() => _isChangingRole = false);
    AppNotification.showError(
      context,
      title: 'Ganti Peran Gagal',
      message: error,
    );
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
    final account = _account;
    if (registration == null && account == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(LoginPage.route);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final isLoading = state is GoogleRegistrationSubmitting || _isChangingRole;
    final roleOptions = _roleOptions
        .where((option) => isRoleSupportedOnPlatform(
              option.value.wireValue,
              isWeb: kIsWeb,
            ))
        .toList();
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
                          fontWeight: AppFontWeight.semibold,
                        )),
                    const SizedBox(height: 4),
                    Text('Daftar Akun', style: AppTextStyle.headline1),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih peran yang sesuai untuk melanjutkan pendaftaran.',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.grey100,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _VerifiedIdentity(
                      name: registration?.name ?? account!.name,
                      email: registration?.email ?? account!.email,
                      // The account already exists once a role was saved;
                      // leaving it is the profile step's logout.
                      showChangeAccount: registration != null,
                      onChangeAccount: isLoading || _isChangingAccount
                          ? null
                          : _changeAccount,
                    ),
                    const SizedBox(height: 32),
                    Text('Saya ingin mendaftar sebagai',
                        style: AppTextStyle.title1),
                    const SizedBox(height: 16),
                    for (var index = 0;
                        index < roleOptions.length;
                        index++) ...[
                      _RoleCard(
                        option: roleOptions[index],
                        selected: _selectedRole == roleOptions[index].value,
                        enabled: !isLoading,
                        onTap: () => setState(
                            () => _selectedRole = roleOptions[index].value),
                      ),
                      if (index < roleOptions.length - 1)
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
              child: AppButton(
                label: 'Lanjutkan',
                isLoading: isLoading,
                onPressed: _selectedRole == null
                    ? null
                    : () => _submit(_selectedRole!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedIdentity extends StatelessWidget {
  final String name;
  final String email;
  final bool showChangeAccount;
  final VoidCallback? onChangeAccount;

  const _VerifiedIdentity({
    required this.name,
    required this.email,
    required this.showChangeAccount,
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
          if (showChangeAccount)
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
      selected: selected,
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
                              fontSize: AppFontSize.sm,
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
