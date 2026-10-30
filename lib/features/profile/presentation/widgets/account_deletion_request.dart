import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionRequestButton extends StatelessWidget {
  const AccountDeletionRequestButton({super.key});

  static final _requestUrl = Uri.parse(
    'https://sites.google.com/view/pilah-privacy-policy',
  );

  Future<void> _open(BuildContext context) async {
    try {
      final opened = await launchUrl(
        _requestUrl,
        mode: LaunchMode.externalApplication,
      );
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    AppNotification.showError(
      context,
      title: 'Gagal',
      message:
          'Halaman informasi tidak dapat dibuka. Periksa koneksi Anda dan coba lagi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Permintaan penghapusan akun',
      variant: AppButtonVariant.outlined,
      icon: Icons.delete_outline,
      trailingIcon: Icons.open_in_new,
      onPressed: () => _open(context),
    );
  }
}
