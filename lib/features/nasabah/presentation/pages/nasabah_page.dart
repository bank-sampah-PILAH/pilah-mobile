import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

class NasabahPage extends StatelessWidget {
  const NasabahPage({super.key});

  static const route = '/nasabah';

  @override
  Widget build(BuildContext context) {
    return const _NasabahPageBody();
  }
}

class _NasabahPageBody extends StatefulWidget {
  const _NasabahPageBody();

  @override
  State<_NasabahPageBody> createState() => _NasabahPageBodyState();
}

class _NasabahPageBodyState extends State<_NasabahPageBody> {
  @override
  void initState() {
    super.initState();
    // Load with the authenticated session when the tab is first opened.
    context.read<NasabahCubit>().loadNasabah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'nasabah_page_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true, // This hides the bottom navbar
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TambahNasabahBottomSheet(),
          );
        },
        backgroundColor: AppColors.greenDark,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Nasabah',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  BlocBuilder<NasabahCubit, NasabahState>(
                    builder: (context, state) {
                      final activeCount = context.read<NasabahCubit>().activeCount;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount aktif',
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              CustomSearchField(
                hintText: 'Cari nama nasabah...',
                onChanged: (value) {
                  context.read<NasabahCubit>().searchNasabah(value);
                },
              ),
              const SizedBox(height: 16),
              
              // Filter Chips
              BlocBuilder<NasabahCubit, NasabahState>(
                buildWhen: (previous, current) {
                  if (previous is NasabahLoaded && current is NasabahLoaded) {
                    return previous.isActiveTab != current.isActiveTab;
                  }
                  return true;
                },
                builder: (context, state) {
                  final isActiveTab = state is NasabahLoaded ? state.isActiveTab : true;
                  return NasabahFilterChips(
                    isActiveTab: isActiveTab,
                    onTabChanged: (value) {
                      context.read<NasabahCubit>().setActiveTab(value);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // List View
              Expanded(
                child: BlocBuilder<NasabahCubit, NasabahState>(
                  builder: (context, state) {
                    if (state is NasabahLoading || state is NasabahInitial) {
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: 5,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => const SkeletonListItem(),
                      );
                    }

                    if (state is NasabahLoaded) {
                      final customers = state.nasabahList;

                      if (customers.isEmpty) {
                        if (state.searchQuery.isNotEmpty) {
                          return const EmptyView(
                            title: 'Nasabah Tidak Ditemukan',
                            subtitle: 'Coba kata kunci yang berbeda',
                            icon: Icons.search_off,
                          );
                        }
                        return EmptyView(
                          title: state.isActiveTab
                              ? 'Belum Ada Nasabah'
                              : 'Tidak Ada Nasabah Nonaktif',
                          subtitle: state.isActiveTab
                              ? 'Tekan tombol + untuk menambah nasabah pertama.'
                              : 'Semua nasabah masih berstatus aktif.',
                          icon: state.isActiveTab
                              ? Icons.people_outline
                              : Icons.person_off_outlined,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: customers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return NasabahListItem(
                            isActive: customer.isActive,
                            initials: customer.initials,
                            avatarColor: customer.avatarColor,
                            textColor: customer.textColor,
                            name: customer.name,
                            phone: customer.phone,
                            balance: customer.balance,
                            id: customer.id,
                            idNasabah: customer.idNasabah,
                            jenisKelamin: customer.jenisKelamin,
                            tanggalLahir: customer.tanggalLahir,
                            tanggalDaftar: customer.tanggalDaftar,
                            address: customer.address,
                            nasabahCubit: context.read<NasabahCubit>(),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
