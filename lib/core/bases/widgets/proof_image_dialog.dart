import 'package:flutter/material.dart';

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

  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.black54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Image Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
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
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueGrey.shade300,
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
                              return _ProofPlaceholder(
                                icon: Icons.broken_image,
                                title: 'Gagal memuat gambar',
                                subtitle: 'Periksa koneksi lalu coba lagi.',
                              );
                            },
                          ),
                        )
                      : _ProofPlaceholder(
                          icon: Icons.image_not_supported_outlined,
                          title: 'Tidak ada foto kegiatan',
                          subtitle:
                              'Bank sampah ini mendaftar tanpa melampirkan bukti.',
                        ),
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280), // Cool gray
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
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
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
