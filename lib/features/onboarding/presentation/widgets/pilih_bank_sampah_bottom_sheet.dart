import 'package:pilah_mobile/design/layout/dialog_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';

/// Lets a calon nasabah pick a bank sampah to apply to (PIL-204), searching
/// the list [OnboardingNotifier.loadBankSampahDirectory] fetches on open.
class PilihBankSampahBottomSheet extends ConsumerStatefulWidget {
  /// Bank sampah ids to hide from the list, e.g. ones already joined.
  final Set<String> excludedBankIds;

  const PilihBankSampahBottomSheet(
      {super.key, this.excludedBankIds = const {}});

  @override
  ConsumerState<PilihBankSampahBottomSheet> createState() =>
      _PilihBankSampahBottomSheetState();
}

enum _LoadState { loading, error, loaded }

class _PilihBankSampahBottomSheetState
    extends ConsumerState<PilihBankSampahBottomSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  _LoadState _loadState = _LoadState.loading;
  String? _errorMessage;
  List<BankSampahDirectoryEntity> _banks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadState = _LoadState.loading);
    final (:result, :error) =
        await ref.read(onboardingProvider.notifier).loadBankSampahDirectory();
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loadState = _LoadState.error;
        _errorMessage = error.displayMessage;
      });
      return;
    }
    final banks = result ?? const [];
    setState(() {
      _loadState = _LoadState.loaded;
      _banks = widget.excludedBankIds.isEmpty
          ? banks
          : banks
              .where((bank) => !widget.excludedBankIds.contains(bank.id))
              .toList();
    });
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
        bottom: DialogSurface.keyboardInset(context),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHeader(title: 'Pilih Bank Sampah'),
            CustomSearchField(
              hintText: 'Cari nama bank sampah...',
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case _LoadState.loading:
        return const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _LoadState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Gagal memuat daftar bank sampah.',
                textAlign: TextAlign.center,
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        );
      case _LoadState.loaded:
        return _buildList();
    }
  }

  Widget _buildList() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _banks
        : _banks
            .where((bank) => bank.nama.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'Belum ada bank sampah yang tersedia.'
              : 'Bank sampah tidak ditemukan.',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final bank = filtered[index];
        return InkWell(
          onTap: () => context.pop(bank),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.greenDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child:
                      const Icon(Icons.recycling, color: AppColors.greenDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.nama,
                        style: AppTextStyle.title1.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [bank.kota, bank.alamat]
                            .where((part) => part.trim().isNotEmpty)
                            .join(' · '),
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.grey100,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
