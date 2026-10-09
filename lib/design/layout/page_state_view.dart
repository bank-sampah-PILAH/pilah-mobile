import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Kondisi sebuah halaman yang memuat data dari server.
enum PageState {
  /// Permintaan sedang berjalan dan belum ada data yang sah untuk ditampilkan.
  loading,

  /// Permintaan berhasil tetapi tidak ada data.
  empty,

  /// Permintaan gagal.
  error,

  /// Data siap ditampilkan.
  ready,
}

/// Memilih tampilan sesuai [state] halaman.
///
/// PRD 6.2.5 mewajibkan layar yang memuat data menangani loading, kosong, dan
/// gagal, bukan hanya berhasil. Widget ini mengumpulkan keempatnya di satu
/// tempat supaya tiap layar web tidak menuliskannya ulang, dan memakai
/// [EmptyView] serta [SkeletonListItem] yang sudah ada alih-alih membuat
/// tampilan baru.
class PageStateView extends StatelessWidget {
  const PageStateView({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
    this.emptyTitle = 'Belum ada data',
    this.emptySubtitle,
    this.emptyIcon = Icons.inbox_outlined,
    this.errorMessage,
    this.skeletonCount = 5,
  });

  final PageState state;

  /// Konten ketika [state] adalah [PageState.ready].
  final Widget child;

  /// Dipanggil saat pengguna menekan "Coba lagi". Bila null, tombol tidak
  /// ditampilkan: tombol yang tidak melakukan apa pun lebih buruk daripada
  /// tidak ada tombol.
  final VoidCallback? onRetry;

  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  /// Pesan kegagalan. Bila null dipakai pesan umum, karena tombol "Coba lagi"
  /// sendirian tidak memberi tahu apa yang gagal (PRD 6.2.6).
  final String? errorMessage;

  final int skeletonCount;

  @override
  Widget build(BuildContext context) => switch (state) {
        // Konten lama sengaja tidak ditampilkan di balik skeleton: angka basi
        // yang terlihat seperti angka terkini lebih menyesatkan daripada
        // menunggu.
        PageState.loading => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: skeletonCount,
            itemBuilder: (_, __) => const SkeletonListItem(),
          ),
        PageState.empty => EmptyView(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: emptyIcon,
          ),
        PageState.error => _ErrorView(
            message: errorMessage ??
                'Data tidak dapat dimuat. Periksa koneksi Anda, '
                    'lalu coba lagi.',
            onRetry: onRetry,
          ),
        PageState.ready => child,
      };
}

/// Kondisi gagal: menyebutkan masalahnya, lalu menawarkan jalan kembali.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // Scrollable walau isinya tidak pernah melimpah: kondisi ini dapat
      // berada di dalam RefreshIndicator, yang hanya menerima gestur tarik
      // dari keturunan yang dapat di-scroll. Pola yang sama dipakai EmptyView.
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 48, color: AppColors.grey100),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.small.copyWith(color: Colors.black87),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
