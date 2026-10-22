import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';
import 'package:pilah_mobile/services/di.dart';

enum _Tampilan { detail, edit, riwayat }

/// Detail pencairan, form edit, dan riwayat perubahannya dalam satu dialog:
/// detail lebih dulu, lalu "Edit Pencairan" atau "Riwayat Perubahan" menggantinya
/// dengan tombol kembali di header. Dipakai di layar lebar; di telepon tiap
/// tampilan tetap halaman sendiri.
///
/// [onChanged] dipanggil setelah edit tersimpan, lalu dialog ditutup.
class PencairanDetailFlow extends StatefulWidget {
  const PencairanDetailFlow({
    super.key,
    required this.item,
    required this.onChanged,
    this.createRevisiCubit,
  });

  final Pencairan item;
  final VoidCallback onChanged;

  final RevisiPencairanCubit Function()? createRevisiCubit;

  @override
  State<PencairanDetailFlow> createState() => _PencairanDetailFlowState();
}

class _PencairanDetailFlowState extends State<PencairanDetailFlow> {
  _Tampilan _tampilan = _Tampilan.detail;

  void _ke(_Tampilan tampilan) => setState(() => _tampilan = tampilan);

  void _tutup() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final header = switch (_tampilan) {
      _Tampilan.detail => AppPanelHeader(
          title: 'Detail Pencairan',
          onClose: _tutup,
        ),
      _Tampilan.edit => AppPanelHeader(
          title: 'Edit Pencairan',
          subtitle: item.nasabahNama,
          onBack: () => _ke(_Tampilan.detail),
          onClose: _tutup,
        ),
      _Tampilan.riwayat => AppPanelHeader(
          title: 'Riwayat Perubahan',
          subtitle: item.nasabahNama,
          onBack: () => _ke(_Tampilan.detail),
          onClose: _tutup,
        ),
    };
    final Widget body = switch (_tampilan) {
      _Tampilan.detail => Flexible(
          child: SingleChildScrollView(
            child: PencairanDetailSheet(
              item: item,
              embedded: true,
              onEdit: () => _ke(_Tampilan.edit),
              onRiwayatPerubahan: () => _ke(_Tampilan.riwayat),
            ),
          ),
        ),
      _Tampilan.edit => Flexible(
          child: EditPencairanView(
            pencairan: item,
            embedded: true,
            showHeader: false,
            onSaved: () {
              widget.onChanged();
              _tutup();
            },
          ),
        ),
      _Tampilan.riwayat => Flexible(
          child: BlocProvider(
            create: (_) => (widget.createRevisiCubit ??
                () => di<RevisiPencairanCubit>())(),
            child: RevisiPencairanView(
              pencairanId: item.id,
              embedded: true,
              showHeader: false,
            ),
          ),
        ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpacing.md),
          body,
        ],
      ),
    );
  }
}
