import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/legal/domain/legal_document.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_information_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  Future<void> _requestDeletion(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:banksampahpilah@gmail.com?subject=Permintaan%20penghapusan%20akun%20PILAH',
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A missing email app uses the same manual contact fallback.
    }
    if (!context.mounted) return;
    AppNotification.showError(
      context,
      title: 'Email tidak dapat dibuka',
      message: 'Kirim permintaan ke banksampahpilah@gmail.com.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = document.sections;
    return Scaffold(
      body: SafeArea(
        child: ContentFrame(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          child: Column(
            children: [
              ContentInset(
                child: AppBackHeader(
                  title: 'Informasi & legal',
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(LegalInformationPage.route),
                ),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  return SelectionArea(
                    child: ListView(
                      padding: ContentFrame.insetOf(context).add(
                        const EdgeInsets.all(AppSpacing.lg),
                      ),
                      children: [
                        Text(document.title, style: AppTextStyle.headline1),
                        const SizedBox(height: AppSpacing.xl),
                        for (var index = 0;
                            index < sections.length;
                            index++) ...[
                          Semantics(
                            header: true,
                            child: Text(
                              sections[index].title,
                              style: AppTextStyle.title1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            sections[index].body,
                            style: AppTextStyle.small.copyWith(
                              color: AppColors.inkSoft,
                              fontSize: AppFontSize.md,
                              height: 1.7,
                            ),
                          ),
                          if (document == LegalDocument.accountDeletion &&
                              index == 0) ...[
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              label: 'Kirim email permintaan',
                              icon: Icons.email_outlined,
                              onPressed: () => _requestDeletion(context),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
