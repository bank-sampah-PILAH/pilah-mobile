import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';

/// Isi picker nasabah: cari, pilih, pop nasabah yang dipilih.
///
/// Tidak membawa chrome wadahnya sendiri — tinggi, sudut, warna latar dan
/// penghindaran papan tik datang dari [showAdaptivePicker], supaya isi yang
/// sama dapat tampil sebagai bottom sheet pada telepon dan sebagai dialog pada
/// peramban. [presentation] hanya dipakai untuk hal yang memang berbeda di
/// mata pengguna.
class PilihNasabahBottomSheet extends StatefulWidget {
  const PilihNasabahBottomSheet({
    super.key,
    this.presentation = PickerPresentation.bottomSheet,
  });

  final PickerPresentation presentation;

  @override
  State<PilihNasabahBottomSheet> createState() =>
      _PilihNasabahBottomSheetState();
}

class _PilihNasabahBottomSheetState extends State<PilihNasabahBottomSheet> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Future<List<NasabahEntity>> _nasabahFuture;

  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  void initState() {
    super.initState();
    // Selalu ambil sendiri, bukan menumpang state cubit. Halaman nasabah bisa
    // meninggalkan cubit dalam keadaan Loaded dengan daftar berpaginasi
    // sementara daftar picker masih kosong, dan mengambil ulang di sini juga
    // membuat saldo yang tampil selalu yang terbaru setelah ada setoran.
    _nasabahFuture = context.read<NasabahCubit>().loadActiveNasabah();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomSheetHeader(
          title: 'Pilih Nasabah',
          showDragHandle: widget.presentation.showsDragHandle,
        ),

        // Search Bar
        CustomSearchField(
          hintText: 'Cari nama...',
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: FutureBuilder<List<NasabahEntity>>(
            future: _nasabahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                return Center(
                  child: Text(
                    error is NetworkException
                        ? error.displayMessage
                        : error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                  ),
                );
              }

              // Source the options from the full active list rather than the
              // nasabah page's tab/search-filtered state, so every active
              // nasabah stays selectable regardless of that page's last view.
              final query = searchQuery.toLowerCase();
              final filteredCustomers = (snapshot.data ?? [])
                  .where(
                      (customer) => customer.name.toLowerCase().contains(query))
                  .toList();

              if (filteredCustomers.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty
                        ? 'Belum ada nasabah aktif.'
                        : 'Nasabah tidak ditemukan.',
                    style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  // `id` is the backend UUID and means nothing to a user;
                  // `idNasabah` carries the human-readable kode. It can be
                  // empty (the mapper defaults it), in which case the phone
                  // stands alone rather than leading with a stray separator.
                  final subtitle = [
                    if (customer.idNasabah.trim().isNotEmpty)
                      customer.idNasabah,
                    customer.phone,
                  ].join(' · ');
                  return InkWell(
                    onTap: () {
                      context.pop(customer);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: customer.avatarColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              customer.initials,
                              style: AppTextStyle.title1.copyWith(
                                color: customer.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: AppTextStyle.title1.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppTextStyle.small.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Saldo',
                                style: AppTextStyle.extraSmall.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customer.balance,
                                style: AppTextStyle.title1.copyWith(
                                  color: emeraldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
