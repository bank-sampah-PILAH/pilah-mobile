import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

/// Daftar nasabah berpaginasi (PIL-214).
///
/// Halaman berikutnya diminta saat gulir mendekati ujung daftar, bukan lewat
/// tombol, supaya pengurus tidak perlu berhenti membaca untuk menekan apa pun.
class NasabahPagedListView extends StatelessWidget {
  final List<NasabahEntity> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final NasabahCubit? nasabahCubit;

  /// Jarak dari dasar daftar saat halaman berikutnya mulai diambil, dipilih
  /// agar datanya sudah siap sebelum pengurus benar-benar sampai ke ujung.
  static const double ambangMuat = 200;

  const NasabahPagedListView({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.nasabahCubit,
  });

  bool _hampirUjung(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (!metrics.hasContentDimensions) return false;
    return metrics.pixels >= metrics.maxScrollExtent - ambangMuat;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Cubit sendiri yang menolak permintaan ganda dan permintaan setelah
        // halaman terakhir, jadi di sini cukup memberi tahu.
        if (hasMore && !isLoadingMore && _hampirUjung(notification)) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80), // ruang untuk FAB
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final customer = items[index];
          return NasabahListItem(
            isActive: customer.isActive,
            initials: customer.initials,
            avatarColor: customer.avatarColor,
            textColor: customer.textColor,
            name: customer.name,
            email: customer.email,
            phone: customer.phone,
            balance: customer.balance,
            id: customer.id,
            idNasabah: customer.idNasabah,
            jenisKelamin: customer.jenisKelamin,
            tanggalLahir: customer.tanggalLahir,
            tanggalDaftar: customer.tanggalDaftar,
            address: customer.address,
            isPending: customer.status == 'pending',
            nasabahCubit: nasabahCubit,
          );
        },
      ),
    );
  }
}
