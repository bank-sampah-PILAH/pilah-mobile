import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_view.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_search_bar.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

class NasabahPage extends StatefulWidget {
  const NasabahPage({super.key});

  static const route = '/nasabah';

  @override
  State<NasabahPage> createState() => _NasabahPageState();
}

class _NasabahPageState extends State<NasabahPage> {
  bool isActiveTab = true;

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
              const NasabahSearchBar(),
              const SizedBox(height: 16),
              
              // Filter Chips
              NasabahFilterChips(
                isActiveTab: isActiveTab,
                onTabChanged: (value) {
                  setState(() {
                    isActiveTab = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // List View
              Expanded(
                child: NasabahListView(
                  isActiveTab: isActiveTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
