import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';

class PilihNasabahBottomSheet extends StatefulWidget {
  const PilihNasabahBottomSheet({super.key});

  @override
  State<PilihNasabahBottomSheet> createState() =>
      _PilihNasabahBottomSheetState();
}

class _PilihNasabahBottomSheetState extends State<PilihNasabahBottomSheet> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  void initState() {
    super.initState();
    // The picker can be opened before the nasabah page has ever run (straight
    // from the dashboard), so fetch the list rather than relying on another
    // route having populated the shared cubit.
    final cubit = context.read<NasabahCubit>();
    if (cubit.state is NasabahInitial) {
      cubit.loadNasabah();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(title: 'Pilih Nasabah'),

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
              child: BlocBuilder<NasabahCubit, NasabahState>(
                builder: (context, state) {
                  if (state is NasabahLoading || state is NasabahInitial) {
                    return const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (state is NasabahError) {
                    return Center(
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.small
                            .copyWith(color: Colors.grey[500]),
                      ),
                    );
                  }

                  // Source the options from the full active list rather than the
                  // nasabah page's tab/search-filtered state, so every active
                  // nasabah stays selectable regardless of that page's last view.
                  final query = searchQuery.toLowerCase();
                  final filteredCustomers = context
                      .read<NasabahCubit>()
                      .activeNasabah
                      .where((customer) =>
                          customer.name.toLowerCase().contains(query))
                      .toList();

                  if (filteredCustomers.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? 'Belum ada nasabah aktif.'
                            : 'Nasabah tidak ditemukan.',
                        style: AppTextStyle.small
                            .copyWith(color: Colors.grey[500]),
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
        ),
      ),
    );
  }
}
