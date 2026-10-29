import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_media_dialog.dart';

/// Shows a bank sampah's foto kegiatan so a superadmin can review it.
///
/// [imageUrl] is null when the bank sampah has no photo on record. That renders
/// an explicit "no photo" state — never a stand-in image. This dialog is the
/// evidence an approval decision is made against, so showing something that
/// merely looks like a photo is worse than showing nothing: it invites the
/// reviewer to approve against an image the applicant never submitted. This
/// previously fell back to a picsum.photos stock photo.
void showProofImageDialog(BuildContext context, {String? imageUrl}) {
  final url = imageUrl?.trim();
  final hasProof = url != null && url.isNotEmpty;

  showAppMediaDialog(
    context,
    closeLabel: 'Close',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasProof
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.fill,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.grey100,
                        ),
                      ),
                    );
                  },
                  // A photo exists but could not be fetched. Kept
                  // distinct from the no-photo state below: one is a
                  // network problem, the other means the applicant
                  // submitted nothing, and a reviewer has to be able
                  // to tell those apart.
                  errorBuilder: (context, error, stackTrace) {
                    return const _ProofPlaceholder(
                      icon: Icons.broken_image,
                      title: 'Gagal memuat gambar',
                      subtitle: 'Periksa koneksi lalu coba lagi.',
                    );
                  },
                ),
              )
            : const _ProofPlaceholder(
                icon: Icons.image_not_supported_outlined,
                title: 'Tidak ada foto kegiatan',
                subtitle: 'Bank sampah ini mendaftar tanpa melampirkan bukti.',
              ),
      ),
    ),
  );
}

/// Fills the image area when there is nothing to show — either no photo was
/// submitted, or one exists but failed to load.
class _ProofPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProofPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fill,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.grey200, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.grey100, fontSize: AppFontSize.sm),
          ),
        ],
      ),
    );
  }
}
