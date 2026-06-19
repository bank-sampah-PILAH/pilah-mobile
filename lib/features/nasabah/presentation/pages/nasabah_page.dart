import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_search_bar.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

class NasabahPage extends StatelessWidget {
  const NasabahPage({super.key});

  static const route = '/nasabah';

  @override
  Widget build(BuildContext context) {
    return const _NasabahPageBody();
  }
}

class _NasabahPageBody extends StatelessWidget {
  const _NasabahPageBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
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
                    'Nasabah',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '4 aktif',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              NasabahSearchBar(
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
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.greenDark,
                        ),
                      );
                    }

                    if (state is NasabahLoaded) {
                      final customers = state.nasabahList;

                      if (customers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nasabah Tidak Ditemukan',
                                style: AppTextStyle.headline1.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Coba kata kunci yang berbeda',
                                style: AppTextStyle.small.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: customers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return NasabahListItem(
                            isActive: customer['isActive'] ?? true,
                            initials: customer['initials'],
                            avatarColor: customer['avatarColor'],
                            textColor: customer['textColor'],
                            name: customer['name'],
                            phone: customer['phone'],
                            balance: customer['balance'],
                            id: customer['id'],
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
