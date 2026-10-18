import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_detail_sheet.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/riwayat_harga_content.dart';
import 'package:pilah_mobile/services/di.dart';

/// Detail satu jenis sampah dan riwayat harganya dalam satu tempat: detail
/// lebih dulu, lalu "Riwayat harga" menggantinya dengan linimasa dan tombol
/// kembali. Edit diteruskan ke [onEdit], karena form-nya punya wadah sendiri.
///
/// Wadahnya mengikuti layar: [embedded] di panel samping layar lebar, bottom
/// sheet di bawah itu.
class HargaDetailFlow extends StatefulWidget {
  const HargaDetailFlow({
    super.key,
    required this.item,
    required this.onEdit,
    this.embedded = false,
    this.onClose,
    this.createRiwayatCubit,
  });

  final HargaEntity item;
  final VoidCallback onEdit;
  final bool embedded;

  /// Menutup seluruh panel. Null di bottom sheet, yang ditutup dengan
  /// menggesernya.
  final VoidCallback? onClose;

  /// Pembuat cubit riwayat; bawaannya dari `di`. Dapat diganti di test.
  final RiwayatHargaCubit Function()? createRiwayatCubit;

  @override
  State<HargaDetailFlow> createState() => _HargaDetailFlowState();
}

class _HargaDetailFlowState extends State<HargaDetailFlow> {
  bool _riwayat = false;

  @override
  void didUpdateWidget(HargaDetailFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Memilih baris lain di panel selalu mulai dari detail barisnya.
    if (oldWidget.item.id != widget.item.id) _riwayat = false;
  }

  @override
  Widget build(BuildContext context) {
    final header = AppPanelHeader(
      title: _riwayat ? 'Riwayat harga' : widget.item.name,
      subtitle: _riwayat ? widget.item.name : 'Detail jenis sampah',
      onBack: _riwayat ? () => setState(() => _riwayat = false) : null,
      onClose: widget.onClose,
    );

    final Widget body;
    if (_riwayat) {
      body = widget.embedded
          ? Expanded(child: _content())
          : SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: _content(),
            );
    } else {
      final detail = HargaDetailSheet(
        item: widget.item,
        embedded: true,
        showName: false,
        onEdit: widget.onEdit,
        onRiwayat: () => setState(() => _riwayat = true),
      );
      body = widget.embedded
          ? Expanded(child: SingleChildScrollView(child: detail))
          : detail;
    }

    final column = Column(
      mainAxisSize: widget.embedded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          const AppSheetHandle(),
          const SizedBox(height: AppSpacing.lg),
        ],
        header,
        const SizedBox(height: AppSpacing.lg),
        body,
      ],
    );
    return widget.embedded ? column : AppSheetContainer(child: column);
  }

  Widget _content() => BlocProvider(
        // Baris lain, riwayat lain: cubit baru, bukan yang lama dengan data
        // jenis sebelumnya.
        key: ValueKey(widget.item.id),
        create: (_) =>
            (widget.createRiwayatCubit ?? () => di<RiwayatHargaCubit>())(),
        child: RiwayatHargaContent(jenisId: widget.item.id),
      );
}
