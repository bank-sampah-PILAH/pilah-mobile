import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_filter_bar.dart';

/// One filtered report and activity feed for Pengurus on mobile and web.
class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({super.key, this.isWeb = kIsWeb});

  static const route = '/laporan';
  final bool isWeb;

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(aktivitasSelectionProvider.notifier).clear();
        ref
            .read(riwayatAktivitasProvider.notifier)
            .load(pageSize: widget.isWeb ? 10 : null);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _webPadding(BuildContext context) =>
      context.layoutBreakpoint != LayoutBreakpoint.compact;

  @override
  Widget build(BuildContext context) {
    ref.listen(riwayatAktivitasProvider, (previous, current) {
      if (previous?.search != current.search &&
          _searchController.text != current.search) {
        _searchController.text = current.search;
      }
    });
    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
      body: SafeArea(
        // Wide: a data page, so only the table card scrolls. Phone: the whole
        // page scrolls, across the body, so its scrollbar is at the edge.
        child: ContentFrame(
          child: _webPadding(context) ? _dataPage() : _phonePage(),
        ),
      ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Riwayat Aktivitas',
            search: CustomSearchField(
              hintText: 'Cari nama pelanggan...',
              controller: _searchController,
              onChanged: ref.read(riwayatAktivitasProvider.notifier).search,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AktivitasFilterBar(),
        ],
      );

  /// Halaman data (layar lebar): judul, pencarian, dan penyaring tetap di
  /// atas; tabel di bawahnya satu-satunya yang bergulir, dengan ringkasan satu
  /// baris dan paginasi di dalam kartunya.
  Widget _dataPage() => Column(
        children: [
          ContentInset(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.webGutter,
                AppSpacing.webTop,
                AppSpacing.webGutter,
                AppSpacing.lg,
              ),
              child: _header(),
            ),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () => ref
                  .read(riwayatAktivitasProvider.notifier)
                  .load(silent: true),
              child: AktivitasListView(isWeb: widget.isWeb),
            ),
          ),
        ],
      );

  /// Telepon: header, penyaring, dan ringkasan bergulir bersama daftar. Saat
  /// ada setoran terpilih, header mode pilih menumpuk di atasnya dan tombol
  /// kembali melepas pilihan lebih dulu.
  Widget _phonePage() {
    final selecting = ref.watch(aktivitasSelectionProvider) != null;
    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(aktivitasSelectionProvider.notifier).clear();
      },
      child: Column(
        children: [
          if (selecting)
            AktivitasSelectionBar(
              onEdit: (id) => showEditSetoranSheet(context, id),
              onHapus: (id) => showBatalkanSetoranDialog(context, id),
            ),
          Expanded(child: _phoneList()),
        ],
      ),
    );
  }

  Widget _phoneList() => NestedScrollView(
        // Let filters and totals scroll away on short screens or with a keyboard.
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const AktivitasSummaryView(),
                ],
              ),
            ),
          ),
        ],
        body: AppRefreshIndicator(
          onRefresh: () =>
              ref.read(riwayatAktivitasProvider.notifier).load(silent: true),
          child: AktivitasListView(isWeb: widget.isWeb),
        ),
      );
}
