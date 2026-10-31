import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/features/legal/domain/legal_document.dart';

class LegalInformationPage extends StatelessWidget {
  const LegalInformationPage({super.key});

  static const route = '/legal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentFrame(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          child: Column(
            children: [
              ContentInset(
                child: AppBackHeader(
                  title: 'Informasi & legal',
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/login'),
                ),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  return ListView(
                    padding: ContentFrame.insetOf(context).add(
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    ),
                    children: [
                      for (final document in LegalDocument.values) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          leading: Icon(switch (document) {
                            LegalDocument.privacyPolicy =>
                              Icons.policy_outlined,
                            LegalDocument.termsAndConditions =>
                              Icons.description_outlined,
                            LegalDocument.accountDeletion =>
                              Icons.person_remove_outlined,
                          }),
                          title: Text(document.title),
                          subtitle: Text(switch (document) {
                            LegalDocument.privacyPolicy =>
                              'Pengumpulan, penggunaan, dan penyimpanan data.',
                            LegalDocument.termsAndConditions =>
                              'Aturan penggunaan akun dan layanan PILAH.',
                            LegalDocument.accountDeletion =>
                              'Cara meminta penghapusan akun dan data terkait.',
                          }),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(document.path),
                        ),
                        const Divider(height: 1),
                      ],
                    ],
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
