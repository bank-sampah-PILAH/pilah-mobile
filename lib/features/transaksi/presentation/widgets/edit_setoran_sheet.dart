import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/setoran_subtotal.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Membuka form koreksi setoran [id]. Mengembalikan true bila tersimpan.
Future<bool?> showEditSetoranSheet(BuildContext context, String id) =>
    showAdaptiveSurface<bool>(
      context,
      builder: (context) => EditSetoranSheet(id: id),
    );

/// Mengoreksi berat, jenis sampah, dan catatan sebuah setoran yang sudah
/// tercatat (PIL-427). Alasan wajib diisi; versi lama tersimpan dan tampil di
/// detail setoran.
class EditSetoranSheet extends ConsumerStatefulWidget {
  const EditSetoranSheet({super.key, required this.id});

  final String id;

  static const alasanKey = ValueKey('edit-setoran-alasan');
  static const catatanKey = ValueKey('edit-setoran-catatan');
  static const saveKey = ValueKey('edit-setoran-simpan');

  @override
  ConsumerState<EditSetoranSheet> createState() => _EditSetoranSheetState();
}

class _EditSetoranSheetState extends ConsumerState<EditSetoranSheet> {
  final _catatan = TextEditingController();
  final _alasan = TextEditingController();
  TransaksiDetailEntity? _detail;
  List<Map<String, dynamic>> _items = [];
  // Satu kunci per kartu, supaya menghapus kartu di tengah tidak menukar
  // isi kolom berat kartu di bawahnya.
  List<UniqueKey> _keys = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _alasan.addListener(_rebuild);
    _catatan.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(hargaProvider.notifier).loadHarga();
      _load();
    });
  }

  @override
  void dispose() {
    _catatan.dispose();
    _alasan.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() => _saveError = null);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final detail = await ref
        .read(transaksiProvider.notifier)
        .fetchTransaksiDetail(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (detail == null) {
        _loadError = 'Rincian setoran gagal dimuat.';
        return;
      }
      _detail = detail;
      _catatan.text = detail.catatan;
      _items = detail.items
          .map<Map<String, dynamic>>((i) => {
                'jenis': i.jenis,
                'jenis_sampah_id': i.jenisSampahId,
                'harga': i.hargaPerKg,
                'berat': i.beratKg,
              })
          .toList();
      _keys = List.generate(_items.length, (_) => UniqueKey());
    });
  }

  List<ItemSetoranRequest> get _requestItems => _items
      .map((i) => ItemSetoranRequest(
            jenisSampahId: i['jenis_sampah_id'] as String,
            berat: (i['berat'] as num).toDouble(),
          ))
      .toList();

  bool get _itemsValid =>
      _items.isNotEmpty &&
      _items.every((i) =>
          ((i['jenis_sampah_id'] as String?) ?? '').isNotEmpty &&
          ((i['berat'] as num?) ?? 0) > 0);

  bool get _itemsChanged {
    final detail = _detail;
    if (detail == null) return false;
    if (_items.length != detail.items.length) return true;
    final before = {
      for (final i in detail.items) i.jenisSampahId: i.beratKg.toDouble()
    };
    return _items.any((i) =>
        before[i['jenis_sampah_id']] != (i['berat'] as num?)?.toDouble());
  }

  bool get _catatanChanged =>
      _catatan.text.trim() != (_detail?.catatan ?? '').trim();

  bool get _canSave =>
      !_saving &&
      _detail != null &&
      _itemsValid &&
      (_itemsChanged || _catatanChanged) &&
      _alasan.text.trim().isNotEmpty;

  int get _total => _items.fold<int>(
      0,
      (sum, i) =>
          sum +
          setoranSubtotal(
              (i['harga'] as int?) ?? 0, (i['berat'] as num?) ?? 0));

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final result = await ref.read(transaksiProvider.notifier).editTransaksi(
          TransaksiEditRequest(
            id: widget.id,
            items: _itemsChanged ? _requestItems : null,
            catatan: _catatanChanged ? _catatan.text : null,
            alasan: _alasan.text,
          ),
        );
    if (!mounted) return;
    if (result.detail == null) {
      setState(() {
        _saving = false;
        _saveError = result.error ?? 'Setoran gagal disimpan.';
      });
      return;
    }
    ref.read(aktivitasSelectionProvider.notifier).clear();
    ref.read(riwayatAktivitasProvider.notifier).load(silent: true);
    Navigator.of(context).pop(true);
    // The toast is a route of its own: show it once this sheet is gone, so it
    // is neither popped with the sheet nor left under it.
    AppNotification.afterNavigation((ctx) => AppNotification.showSuccess(
          ctx,
          title: 'Berhasil',
          message:
              'Setoran diperbarui. Versi lama tersimpan di riwayat perubahan.',
        ));
  }

  void _addItem() => setState(() {
        _items.add(
            {'jenis': null, 'jenis_sampah_id': null, 'harga': 0, 'berat': 1.0});
        _keys.add(UniqueKey());
        _saveError = null;
      });

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Edit Setoran'),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Column(children: [
              Text(_loadError!, style: AppTextStyle.small),
              TextButton(onPressed: _load, child: const Text('Coba Lagi')),
            ])
          else
            ..._form(),
        ],
      ),
    );
  }

  List<Widget> _form() => [
        _ringkasan(_detail!),
        const SizedBox(height: 16),
        const AppFieldLabel('RINCIAN SETORAN'),
        const SizedBox(height: 12),
        for (var i = 0; i < _items.length; i++)
          ItemSetoranCard(
            key: _keys[i],
            index: i,
            itemData: _items[i],
            hargaFor: (jenis) => _detail?.hargaPadaTanggal[jenis.id] ?? 0,
            hasError: ((_items[i]['berat'] as num?) ?? 0) <= 0,
            errorText: ((_items[i]['berat'] as num?) ?? 0) <= 0
                ? 'Berat harus lebih dari 0'
                : null,
            onDelete: () => setState(() {
              _items.removeAt(i);
              _keys.removeAt(i);
            }),
            onChanged: (updated) {
              final newId = updated['jenis_sampah_id'] as String?;
              if (newId != null &&
                  _items.indexed.any(
                      (e) => e.$1 != i && e.$2['jenis_sampah_id'] == newId)) {
                AppNotification.showWarning(
                  context,
                  title: 'Jenis Sudah Dipilih',
                  message:
                      'Jenis sampah ini sudah ada di daftar item. Ubah berat pada item yang sudah ada.',
                );
                return;
              }
              setState(() {
                _items[i] = updated;
                _saveError = null;
              });
            },
          ),
        AppButton(
          label: 'Tambah Item',
          icon: Icons.add,
          variant: AppButtonVariant.outlined,
          onPressed: _addItem,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total baru',
                style: AppTextStyle.small
                    .copyWith(fontWeight: AppFontWeight.bold)),
            Text(
              CurrencyFormatter.formatRupiah(_total),
              style: AppTextStyle.title1.copyWith(color: AppColors.greenDark),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('CATATAN'),
        const SizedBox(height: 8),
        TextField(
          key: EditSetoranSheet.catatanKey,
          controller: _catatan,
          maxLines: 2,
          decoration: appInputDecoration(hintText: 'Catatan (opsional)'),
        ),
        const SizedBox(height: 16),
        const AppFieldLabel('ALASAN PERUBAHAN'),
        const SizedBox(height: 8),
        TextField(
          key: EditSetoranSheet.alasanKey,
          controller: _alasan,
          maxLength: 255,
          decoration: appInputDecoration(hintText: 'Mis. salah timbang'),
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 4),
          Text(_saveError!,
              style: AppTextStyle.small.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: 16),
        AppButton(
          key: EditSetoranSheet.saveKey,
          label: _saving ? 'Menyimpan...' : 'Simpan Perubahan',
          icon: Icons.save_outlined,
          onPressed: _canSave ? _save : null,
        ),
      ];

  Widget _ringkasan(TransaksiDetailEntity detail) {
    final tanggal = detail.tanggal;
    final diubah = detail.revisi.length;
    final palette = avatarPaletteFor(detail.name);
    return Container(
      key: const ValueKey('edit-setoran-ringkasan'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.$1,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  initialsOf(detail.name),
                  style: AppTextStyle.small.copyWith(
                    color: palette.$2,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.headline3
                          .copyWith(fontWeight: AppFontWeight.semibold),
                    ),
                    if (tanggal != null)
                      Text(
                        formatTanggalJamId(tanggal),
                        style: AppTextStyle.small
                            .copyWith(color: AppColors.grey100),
                      ),
                  ],
                ),
              ),
              if (diubah > 0) ...[
                const SizedBox(width: 8),
                _Chip('Diubah $diubah kali'),
              ],
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Nominal(
                      label: 'Total Transaksi Ini',
                      value: detail.amountFormatted,
                      emphasis: true,
                    ),
                  ),
                  const VerticalDivider(
                    key: ValueKey('edit-setoran-ringkasan-divider'),
                    width: 24,
                    thickness: 1,
                    color: AppColors.grey200,
                  ),
                  Expanded(
                    child: _Nominal(
                      label: 'Saldo setelah setoran',
                      value: detail.balanceFormatted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Nominal extends StatelessWidget {
  const _Nominal({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    // Space between, so the amounts share a line even when a label wraps.
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyle.small.copyWith(color: AppColors.inkSoft)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyle.title1.copyWith(
            color: emphasis ? AppColors.greenDark : AppColors.black,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyle.extraSmall.copyWith(
          color: AppColors.warning,
          fontWeight: AppFontWeight.semibold,
        ),
      ),
    );
  }
}
