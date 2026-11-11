import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The green banner at the top of an onboarding step: a title, a line under
/// it and a logout button that calls [onExit].
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onExit,
  });

  final String title;
  final String subtitle;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 40),
      decoration: const BoxDecoration(color: AppColors.greenDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.headline1.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Keluar',
          ),
        ],
      ),
    );
  }
}

/// The two steps of onboarding, "Profil Diri" and then the step named by
/// [secondStepLabel]. [currentStep] is 1 or 2: step one shows a check mark
/// once step two is reached, and step two is greyed until then.
class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    super.key,
    required this.currentStep,
    required this.secondStepLabel,
  });

  final int currentStep;
  final String secondStepLabel;

  @override
  Widget build(BuildContext context) {
    final onSecond = currentStep == 2;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Step(
            number: 1,
            label: 'Profil Diri',
            reached: true,
            done: onSecond,
          ),
          Flexible(
            child: Container(
              width: 100,
              height: 2,
              margin: const EdgeInsets.only(bottom: 24),
              color: onSecond ? AppColors.greenDark : AppColors.border,
            ),
          ),
          _Step(
            number: 2,
            label: secondStepLabel,
            reached: onSecond,
            done: false,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.reached,
    required this.done,
  });

  final int number;
  final String label;
  final bool reached;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final onColor = reached ? Colors.white : AppColors.grey100;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: reached ? AppColors.greenDark : AppColors.fill,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? Icon(Icons.check, color: onColor, size: 20)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: onColor,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: reached ? AppColors.greenDark : AppColors.grey100,
            fontWeight: AppFontWeight.semibold,
          ),
        ),
      ],
    );
  }
}

/// The white card that holds the fields of an onboarding step. Put the fields
/// in [children]; [formKey] validates them together.
class OnboardingFormCard extends StatelessWidget {
  const OnboardingFormCard({
    super.key,
    required this.formKey,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A field of an onboarding form: its capital label, an optional line of help,
/// then the [child] field and some space below.
///
/// The label carries a red star while [isRequired], which the form's own
/// "Semua kolom bertanda * wajib diisi." line refers to. Pass false for a
/// field that may be left empty, so that sentence stays true.
class OnboardingFormField extends StatelessWidget {
  const OnboardingFormField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.isRequired = true,
  });

  final String label;
  final String? description;
  final Widget child;

  /// Whether the label carries the red star. Defaults to true: on these forms
  /// a required field is the rule and an optional one the exception.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyle.small.copyWith(
      color: AppColors.grey100,
      fontWeight: AppFontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: labelStyle,
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: labelStyle.copyWith(color: AppColors.danger),
                ),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description!,
              style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
        ],
        const SizedBox(height: 8),
        Semantics(
          label: isRequired ? '$label, wajib diisi' : '$label, opsional',
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
