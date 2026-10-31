import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

/// Shared registration workspace: a desktop rail, tablet progress strip, and
/// stacked phone content. Actions stay outside the scroll view and keyboard.
class OnboardingFlowLayout extends StatelessWidget {
  const OnboardingFlowLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onExit,
    required this.child,
    required this.actions,
    this.progress,
    this.notice,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onExit;
  final Widget child;
  final Widget actions;
  final Widget? progress;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.layoutBreakpoint;
    final desktop = breakpoint == LayoutBreakpoint.expanded;
    final gutter =
        breakpoint == LayoutBreakpoint.compact ? AppSpacing.lg : AppSpacing.xxl;
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: gutter, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (MediaQuery.textScalerOf(context).scale(16) <= 24) ...[
                  SvgPicture.asset('assets/svg/logo.svg',
                      width: 32, height: 40, excludeFromSemantics: true),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: Text('PILAH', style: AppTextStyle.title1)),
                Tooltip(
                  message: 'Keluar',
                  child: TextButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (desktop)
                  Container(
                    key: const ValueKey('onboarding-sidebar'),
                    width: 256,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(right: BorderSide(color: AppColors.border)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pendaftaran akun', style: AppTextStyle.title1),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'Siapkan akun dan bank sampah Anda di satu tempat.',
                              style: AppTextStyle.small
                                  .copyWith(color: AppColors.grey100)),
                          const SizedBox(height: AppSpacing.xxl),
                          if (progress != null) progress!,
                          const SizedBox(height: AppSpacing.xxl),
                          const Divider(),
                          const SizedBox(height: AppSpacing.md),
                          const Icon(Icons.lock_outline,
                              color: AppColors.greenDark),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Data untuk verifikasi',
                              style: AppTextStyle.headline3),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'Data Anda hanya digunakan untuk keperluan verifikasi bank sampah.',
                              style: AppTextStyle.small
                                  .copyWith(color: AppColors.grey100)),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('onboarding-content-scroll'),
                          padding: EdgeInsets.all(gutter),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 880),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!desktop && progress != null) ...[
                                    progress!,
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                  Semantics(
                                      header: true,
                                      child: Text(title,
                                          style: AppTextStyle.headline1)),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(subtitle,
                                      style: AppTextStyle.headline3
                                          .copyWith(color: AppColors.grey100)),
                                  const SizedBox(height: AppSpacing.xl),
                                  if (notice != null) ...[
                                    notice!,
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                  Container(
                                    key: const ValueKey(
                                        'onboarding-form-surface'),
                                    padding: EdgeInsets.all(
                                        breakpoint == LayoutBreakpoint.compact
                                            ? AppSpacing.lg
                                            : AppSpacing.xl),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: AppColors.border),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: child,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        key: const ValueKey('onboarding-actions'),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: gutter, vertical: AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border:
                              Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 880),
                            child: actions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Informational steps, not links: navigation still goes through the form so
/// validation and the in-memory profile draft cannot be bypassed.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress(
      {super.key,
      required this.currentStep,
      this.lastStepLabel = 'Data Bank Sampah'});

  final int currentStep;
  final String lastStepLabel;

  @override
  Widget build(BuildContext context) {
    final vertical = context.layoutBreakpoint == LayoutBreakpoint.expanded;
    final labels = ['Peran Akun', 'Profil Diri', lastStepLabel];
    final steps = List.generate(
        labels.length, (index) => _buildStep(index, labels[index], vertical));
    return vertical
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: steps)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final step in steps) Expanded(child: step)]);
  }

  Widget _buildStep(int index, String text, bool vertical) {
    final done = index < currentStep;
    final active = index == currentStep;
    final color = active || done ? AppColors.greenDark : AppColors.grey100;
    final numberColor = active ? Colors.white : AppColors.grey100;
    var status = 'Berikutnya';
    if (done) {
      status = 'Selesai';
    } else if (active) {
      status = 'Sedang diisi';
    }
    final badge = CircleAvatar(
      radius: 16,
      backgroundColor: active ? AppColors.greenDark : AppColors.fill,
      child: done
          ? const Icon(Icons.check, size: 20, color: AppColors.greenDark)
          : Text('${index + 1}',
              style: AppTextStyle.small.copyWith(
                  color: numberColor, fontWeight: AppFontWeight.semibold)),
    );
    final label = Text(text,
        textAlign: vertical ? TextAlign.start : TextAlign.center,
        style: AppTextStyle.small
            .copyWith(color: color, fontWeight: AppFontWeight.semibold));
    return Semantics(
      label: 'Langkah ${index + 1} dari 3. $text. $status',
      excludeSemantics: true,
      child: vertical
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Row(children: [
                badge,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: label)
              ]))
          : Column(
              children: [badge, const SizedBox(height: AppSpacing.sm), label]),
    );
  }
}

/// Pair related fields only when each still has a comfortable input width.
class OnboardingFieldPair extends StatelessWidget {
  const OnboardingFieldPair(
      {super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < LayoutBreakpoint.mediumMinWidth ||
          MediaQuery.textScalerOf(context).scale(16) > 24) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, second]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: first),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: second),
      ]);
    });
  }
}

class OnboardingActions extends StatelessWidget {
  const OnboardingActions({super.key, required this.primary, this.secondary});
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= LayoutBreakpoint.mediumMinWidth;
      if (MediaQuery.textScalerOf(context).scale(16) > 24) {
        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              if (secondary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                secondary!
              ]
            ]);
      }
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (secondary != null) ...[
          Flexible(child: SizedBox(width: wide ? 140 : null, child: secondary)),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
            flex: 2,
            child:
                SizedBox(width: wide ? 260 : double.infinity, child: primary)),
      ]);
    });
  }
}
