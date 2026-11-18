import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/legal/presentation/pages/legal_information_page.dart';

void openLegalInformation(BuildContext context) {
  context.push(LegalInformationPage.route);
}

class LegalInformationButton extends StatelessWidget {
  const LegalInformationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Informasi & legal',
      variant: AppButtonVariant.outlined,
      icon: Icons.info_outline,
      onPressed: () => openLegalInformation(context),
    );
  }
}
