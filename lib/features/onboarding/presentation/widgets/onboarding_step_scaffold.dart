import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_exit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';

class OnboardingStepScaffold extends ConsumerWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onExit,
    required this.onUnauthenticated,
    required this.progress,
    required this.formKey,
    required this.formFields,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final VoidCallback onExit;
  final VoidCallback onUnauthenticated;
  final Widget progress;
  final GlobalKey<FormState> formKey;
  final List<Widget> formFields;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authenticationProvider, (previous, current) {
      if (current is Unauthenticated) onUnauthenticated();
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => handleOnboardingStepPop(
        context,
        didPop: didPop,
        isWizardStep: ref.read(onboardingProvider.notifier).hasProfileDraft,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          child: Column(
            children: [
              OnboardingHeader(
                title: title,
                subtitle: subtitle,
                onExit: onExit,
              ),
              progress,
              const SizedBox(height: 24),
              OnboardingFormCard(formKey: formKey, children: formFields),
              ...footer,
            ],
          ),
        ),
      ),
    );
  }
}
