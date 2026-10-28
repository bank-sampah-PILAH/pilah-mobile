import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';

/// Isi picker nasabah: cari, pilih, pop nasabah yang dipilih.
///
/// Tidak membawa chrome wadahnya sendiri — tinggi, sudut, warna latar dan
/// penghindaran papan tik datang dari [showAdaptivePicker], supaya isi yang
/// sama dapat tampil sebagai bottom sheet pada telepon dan sebagai dialog pada
/// peramban. [presentation] hanya dipakai untuk hal yang memang berbeda di
/// mata pengguna.
class PilihNasabahPicker extends ConsumerStatefulWidget {
  const PilihNasabahPicker({
    super.key,
    this.presentation = PickerPresentation.bottomSheet,
  });

  final PickerPresentation presentation;

  @override
  ConsumerState<PilihNasabahPicker> createState() => _PilihNasabahPickerState();
}

class _PilihNasabahPickerState extends ConsumerState<PilihNasabahPicker> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  final List<NasabahEntity> _nasabah = [];
  Timer? _searchDebounce;
  int _page = 0;
  int _requestGeneration = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Object? _error;
  Object? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_loadMoreWhenNearEnd);
    unawaited(_loadPage(page: 1, query: '', generation: _requestGeneration));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _search(String value) {
    final query = value.trim();
    final generation = ++_requestGeneration;
    _searchDebounce?.cancel();
    setState(() {
      searchQuery = query;
      _nasabah.clear();
      _page = 0;
      _hasMore = false;
      _isLoading = query.isEmpty || query.length >= 2;
      _isLoadingMore = false;
      _error = null;
      _loadMoreError = null;
    });
    if (_listController.hasClients) _listController.jumpTo(0);

    if (query.length == 1) return;
    if (query.isEmpty) {
      unawaited(_loadPage(page: 1, query: '', generation: generation));
      return;
    }
    _searchDebounce = Timer(NasabahNotifier.jedaPencarian, () {
      unawaited(_loadPage(page: 1, query: query, generation: generation));
    });
  }

  Future<void> _loadPage({
    required int page,
    required String query,
    required int generation,
    bool append = false,
  }) async {
    _setLoading(append: append);
    try {
      final result =
          await ref.read(nasabahProvider.notifier).loadActiveNasabahPage(
                page: page,
                search: query.length >= 2 ? query : null,
              );
      if (!_isCurrentRequest(generation)) return;
      _setLoadedPage(
        page: page,
        items: _eligibleNasabah(result.items),
        hasMore: result.hasMore,
        append: append,
      );
    } catch (error) {
      if (!_isCurrentRequest(generation)) return;
      _setLoadError(error, append: append);
    }
  }

  bool _isCurrentRequest(int generation) =>
      mounted && generation == _requestGeneration;

  void _setLoading({required bool append}) {
    setState(() {
      if (append) {
        _isLoadingMore = true;
        _loadMoreError = null;
      } else {
        _isLoading = true;
        _error = null;
      }
    });
  }

  List<NasabahEntity> _eligibleNasabah(List<NasabahEntity> items) => items
      .where((customer) => customer.isActive && customer.status == 'approved')
      .toList();

  void _setLoadedPage({
    required int page,
    required List<NasabahEntity> items,
    required bool hasMore,
    required bool append,
  }) {
    setState(() {
      _page = page;
      if (append) {
        _nasabah.addAll(items);
      } else {
        _nasabah
          ..clear()
          ..addAll(items);
      }
      _hasMore = hasMore;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _setLoadError(Object error, {required bool append}) {
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      if (append) {
        _loadMoreError = error;
      } else {
        _error = error;
      }
    });
  }

  void _loadMoreWhenNearEnd() {
    if (_listController.hasClients &&
        _listController.position.extentAfter < 240) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_hasMore || _isLoading || _isLoadingMore || searchQuery.length == 1) {
      return;
    }
    unawaited(
      _loadPage(
        page: _page + 1,
        query: searchQuery,
        generation: _requestGeneration,
        append: true,
      ),
    );
  }

  Widget _buildNasabahList() {
    if (searchQuery.length == 1) return _buildSearchHint();
    if (_isLoading && _nasabah.isEmpty) return _buildInitialLoading();
    if (_error != null && _nasabah.isEmpty) return _buildInitialError();
    if (_nasabah.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _listController,
      itemCount: _nasabah.length + (_hasMore ? 1 : 0),
      itemBuilder: _buildNasabahItem,
    );
  }

  Widget _buildSearchHint() => Center(
        child: Text(
          'Ketik minimal 2 karakter untuk mencari.',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
      );

  Widget _buildInitialLoading() => const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _buildInitialError() {
    final error = _error!;
    return Center(
      child: Text(
        error is NetworkException ? error.displayMessage : error.toString(),
        textAlign: TextAlign.center,
        style: AppTextStyle.small.copyWith(color: AppColors.grey100),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Text(
          searchQuery.isEmpty
              ? 'Belum ada nasabah aktif.'
              : 'Nasabah tidak ditemukan.',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
      );

  Widget _buildNasabahItem(BuildContext context, int index) {
    if (index == _nasabah.length) return _buildLoadMoreFooter();

    final customer = _nasabah[index];
    // `id` is the backend UUID and means nothing to a user;
    // `idNasabah` carries the human-readable kode. It can be empty (the
    // mapper defaults it), in which case the phone stands alone.
    final subtitle = [
      if (customer.idNasabah.trim().isNotEmpty) customer.idNasabah,
      customer.phone,
    ].join(' · ');
    return InkWell(
      onTap: () => context.pop(customer),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: customer.avatarColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                customer.initials,
                style: AppTextStyle.title1.copyWith(
                  color: customer.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSize.lg,
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
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSize.lg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
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
                    color: AppColors.grey100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.balance,
                  style: AppTextStyle.title1.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSize.md,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_loadMoreError != null) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: const Text('Gagal memuat. Coba lagi'),
        ),
      );
    }
    return const SizedBox(height: 24);
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
          onChanged: _search,
        ),
        const SizedBox(height: 16),

        // List
        Expanded(child: _buildNasabahList()),
      ],
    );
  }
}
