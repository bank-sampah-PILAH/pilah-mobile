import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/design/layout/side_sheet_presentation.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_jenis_sampah_picker.dart';

const _pickerPath = '/transaksi-baru/pilih-jenis';

class _PickerEntry {
  const _PickerEntry(this.selectedId);

  final String? selectedId;
}

GoRoute jenisSampahSideSheetRoute() => GoRoute(
      path: _pickerPath,
      redirect: (context, state) =>
          state.extra is _PickerEntry ? null : TransaksiBaruPage.route,
      pageBuilder: (context, state) {
        final entry = state.extra as _PickerEntry;
        return SideSheetPage<HargaEntity>(
          key: state.pageKey,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PilihJenisSampahPicker(
              selectedId: entry.selectedId,
              presentation: PickerPresentation.dialog,
            ),
          ),
        );
      },
    );

Future<HargaEntity?> openJenisSampahPicker(
  BuildContext context, {
  required String? selectedId,
  bool? isWeb,
}) {
  final presentation = SideSheetPresentation.resolve(
    width: MediaQuery.sizeOf(context).width,
    isWeb: isWeb,
  );
  if (presentation == SideSheetPresentation.sideSheet) {
    return context.push<HargaEntity>(
      _pickerPath,
      extra: _PickerEntry(selectedId),
    );
  }
  return showAdaptivePicker<HargaEntity>(
    context: context,
    builder: (context, presentation) => PilihJenisSampahPicker(
      selectedId: selectedId,
      presentation: presentation,
    ),
  );
}
