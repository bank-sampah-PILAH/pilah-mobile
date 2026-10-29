import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_date_picker.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_confirmation_dialog.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/pesan_simpan_jenis.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Isi form jenis sampah, tanpa wadah.
///
/// Dipakai dua tempat dengan wadah berbeda: bottom sheet pada telepon
/// (`TambahJenisSampahBottomSheet`) dan panel di samping daftar pada jendela
/// expanded (`HargaPage`). Yang dipisahkan ke luar adalah *chrome* wadah —
/// judul, pegangan tarik, tombol tutup, sudut, latar, dan penghindaran papan
/// tik — mengikuti pembagian yang sudah dipakai `showAdaptivePicker`: isi hanya
/// tahu cara memvalidasi dan menyimpan, wadah tahu cara menampilkan dirinya dan
/// apa arti "tutup".
///
/// Itu sebabnya form ini tidak pernah memanggil `context.pop()` sendiri. Pop
/// hanya benar untuk sheet; panel berada inline di dalam body halaman dan
/// ditutup dengan melepas pilihan. Keduanya diberitahu lewat [onSaved].
class JenisSampahForm extends ConsumerStatefulWidget {
  const JenisSampahForm({
    super.key,
    required this.onSaved,
    this.initialData,
    this.now = DateTime.now,
  });

  /// Jenis sampah yang sedang diubah, atau null untuk menambah yang baru.
  final HargaEntity? initialData;

  /// Sumber waktu "sekarang", dapat diganti di test.
  final DateTime Function() now;

  /// Dipanggil setelah simpan, aktifkan, atau nonaktifkan berhasil. Wadah
  /// memutuskan artinya: sheet mem-pop dirinya, panel melepas pilihan.
  final VoidCallback onSaved;

  /// Judul untuk wadah yang menampilkan [initial].
  ///
  /// Judul adalah bagian dari chrome, tetapi kalimatnya bergantung pada mode,
  /// jadi kalimatnya tinggal di sini supaya kedua wadah tidak menuliskannya
  /// sendiri dan berisiko berbeda.
  static String titleFor(HargaEntity? initial) =>
      initial == null ? 'Tambah Jenis Sampah' : 'Edit Jenis Sampah';

  @override
  ConsumerState<JenisSampahForm> createState() => _JenisSampahFormState();
}

class _JenisSampahFormState extends ConsumerState<JenisSampahForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeSampahController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  String? _selectedCategory;
  bool _isSaving = false;
  String? _serverKodeError;

  /// Dinaikkan tiap kali panel berganti baris. Simpan yang sedang
  /// berjalan mencatat nilainya lebih dulu, sehingga hasil yang datang
  /// terlambat tahu bahwa form di depan mata bukan lagi form yang
  /// memulainya.
  int _generasiBaris = 0;

  /// Tengah malam waktu setempat saat harga baru mulai berlaku, atau `null`
  /// bila harga baru berlaku sekarang.
  DateTime? _berlakuMulai;

  /// Batas jadwal harga dari backend (`BATAS_JADWAL_HARGA_HARI`).
  static const int _batasJadwalHari = 365;

  /// Pesan untuk field wajib yang dibiarkan kosong. Dipakai empat field,
  /// jadi kalimatnya hidup di satu tempat agar tidak bercabang.
  static const String _wajibDiisi = 'Bagian ini wajib diisi.';

  /// Dropdown options as (API value, display label, icon). The value is what the
  /// backend `JenisSampah.Kategori` choices accept and is stored in
  /// [_selectedCategory]; the label is display-only. They differ for "Lainnya",
  /// which maps to the backend's catch-all `dll` — there is no `lainnya` choice.
  static const List<({String value, String label, IconData icon})> _categories =
      [
    (value: 'kertas', label: 'Kertas', icon: Icons.description),
    (value: 'plastik', label: 'Plastik', icon: Icons.recycling),
    (value: 'logam', label: 'Logam', icon: Icons.settings),
    (value: 'kaca', label: 'Kaca', icon: Icons.wine_bar),
    (value: 'dll', label: 'Lainnya', icon: Icons.category_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  /// Panel hidup lebih lama daripada satu pilihan: memilih baris lain membangun
  /// ulang widget yang sama dengan [JenisSampahForm.initialData] berbeda, dan
  /// tanpa ini field akan tetap memuat isi baris sebelumnya. Sheet tidak pernah
  /// mengalaminya karena selalu dibuat baru.
  @override
  void didUpdateWidget(JenisSampahForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData?.id != widget.initialData?.id) {
      _disposeControllers();
      _initControllers();
      _serverKodeError = null;
      _berlakuMulai = null;
      // Tombol milik baris yang baru, jadi ia tidak boleh ikut terkunci oleh
      // simpanan baris sebelumnya. Simpanan itu tetap berjalan dan tetap
      // melaporkan hasilnya lewat notifikasi; yang dilepas kuncinya, dan
      // generasinya naik supaya hasil tadi tidak lagi menyentuh form ini.
      _isSaving = false;
      _generasiBaris++;
    }
  }

  void _initControllers() {
    _kodeSampahController =
        TextEditingController(text: widget.initialData?.kodeSampah ?? '');
    _nameController =
        TextEditingController(text: widget.initialData?.name ?? '');
    _descController =
        TextEditingController(text: widget.initialData?.subtitle ?? '');

    // The dropdown holds the backend value verbatim, so edit mode preselects by
    // matching the stored category directly. An unknown category (e.g. organik,
    // which has no dropdown entry) leaves the field empty rather than
    // silently rewriting it to a category the user never chose.
    final cat = widget.initialData?.category.toLowerCase();
    _selectedCategory =
        cat != null && _categories.any((c) => c.value == cat) ? cat : null;

    _priceController = TextEditingController(
      text: widget.initialData?.price.toString() ?? '',
    );
  }

  void _disposeControllers() {
    _kodeSampahController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool get _isEditMode => widget.initialData != null;

  bool get _isActive => widget.initialData?.isActive ?? true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildKodeField(),
          ..._buildNamaField(),
          ..._buildKategoriField(),
          ..._buildDeskripsiField(),
          ..._buildHargaField(),
          if (_isEditMode) ..._buildPengaturanHarga(),
          const SizedBox(height: 32),
          _buildSimpanButton(),
          if (_isEditMode) _buildToggleStatusButton(),
        ],
      ),
    );
  }

  /// Pesan untuk isian wajib yang masih kosong.
  String? _validateWajib(String? value) =>
      (value == null || value.trim().isEmpty) ? _wajibDiisi : null;

  // Tiap isian berdiri sebagai satu kelompok — label, input, dan
  // keterangannya — sehingga `build` tinggal menyebut urutannya. Sebelumnya
  // semuanya satu daftar panjang dan percabangannya membuat satu method itu
  // terlalu rumit untuk dibaca sekaligus.

  List<Widget> _buildKodeField() => [
        const AppFieldLabel('ID / KODE SAMPAH'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _kodeSampahController,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_serverKodeError != null) {
              setState(() => _serverKodeError = null);
            }
          },
          validator: _validateKode,
          decoration: appInputDecoration(hintText: 'Contoh: PLS-001'),
        ),
        const SizedBox(height: 4),
        Text(
          'Kode unik untuk identifikasi jenis sampah ini.',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildNamaField() => [
        const AppFieldLabel('NAMA JENIS SAMPAH'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          validator: _validateWajib,
          decoration: appInputDecoration(hintText: 'Contoh: Plastik PET'),
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildKategoriField() => [
        const AppFieldLabel('KATEGORI'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          borderRadius: BorderRadius.circular(AppRadius.md),
          initialValue: _selectedCategory,
          validator: _validateWajib,
          hint: const Text('— Pilih Kategori —'),
          decoration: appInputDecoration(),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey100),
          items: _categories.map(_buildDropdownItem).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildDeskripsiField() => [
        const AppFieldLabel('DESKRIPSI (OPSIONAL)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 2,
          decoration: appInputDecoration(
              hintText: 'Contoh: Botol bening, kemasan plastik'),
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildHargaField() => [
        const AppFieldLabel('HARGA BELI PER KG (RP)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          // Baris terakhir yang diisi dari papan tik, jadi Enter di sini
          // menyimpan alih-alih sekadar memindahkan fokus. Itu yang membuat
          // form ini dapat diselesaikan tanpa menyentuh tetikus.
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isSaving) _handleSimpan();
          },
          validator: _validateWajib,
          decoration: appInputDecoration(
            hintText: '0',
          ).copyWith(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 8, top: 14, bottom: 14),
              child: Text(
                'Rp',
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.black,
                  fontWeight: AppFontWeight.semibold,
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Harga yang akan dibayarkan ke nasabah.',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
      ];

  /// Hanya pada mode ubah: harga baru dapat dijadwalkan, dan nilainya perlu
  /// ditunjukkan bersama peringatan bahwa perubahan tidak berlaku surut.
  List<Widget> _buildPengaturanHarga() => [
        const SizedBox(height: 20),
        const AppFieldLabel('BERLAKU MULAI'),
        const SizedBox(height: 8),
        _buildPilihanBerlaku(),
        const SizedBox(height: 16),
        _buildRingkasanHarga(widget.initialData!),
        const SizedBox(height: 12),
        _buildPeringatanTidakSurut(),
      ];

  Widget _buildSimpanButton() {
    // Diangkat keluar dari ternary `_isSaving`: menuliskannya di dalam sana
    // membuat dua ternary bersarang, dan yang di dalam menjawab pertanyaan
    // yang berbeda — mode form, bukan keadaan simpan.
    final label = _isEditMode ? 'Simpan Perubahan' : 'Simpan Jenis Sampah';
    return AppButton(
      label: label,
      isLoading: _isSaving,
      onPressed: _handleSimpan,
    );
  }

  Widget _buildToggleStatusButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppButton(
        label: _isActive ? 'Nonaktifkan Jenis Sampah' : 'Aktifkan Jenis Sampah',
        variant: _isActive
            ? AppButtonVariant.destructiveOutlined
            : AppButtonVariant.outlined,
        icon: _isActive ? Icons.block : Icons.check_circle_outline,
        onPressed: _isSaving ? null : _handleToggleStatus,
      ),
    );
  }

  String? _validateKode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _wajibDiisi;
    }
    final state = ref.read(hargaProvider);
    if (state is HargaLoaded) {
      final list = state.jenisSampahList;
      final isDuplicate = list.any((e) =>
          e.kodeSampah.trim().toLowerCase() == value.trim().toLowerCase() &&
          e.id != widget.initialData?.id);
      if (isDuplicate) {
        return 'Kode sampah ini sudah digunakan.';
      }
    }
    if (_serverKodeError != null) return _serverKodeError;
    return null;
  }

  static String _pesanStatus(bool wasActive) => wasActive
      ? 'Jenis sampah berhasil dinonaktifkan.'
      : 'Jenis sampah berhasil diaktifkan.';

  /// Panel sudah beralih ke tampilan lain selagi permintaan berjalan, sehingga
  /// form ini tidak lagi ada. Perubahannya tetap terjadi, jadi tetap
  /// dikabarkan, lewat navigator utama.
  static void _kabarkanTanpaForm(String message) =>
      AppNotification.afterNavigation((context) => AppNotification.showSuccess(
          context,
          title: 'Berhasil',
          message: message));

  Future<void> _handleToggleStatus() async {
    final notifier = ref.read(hargaProvider.notifier);
    final id = widget.initialData!.id;
    final wasActive = _isActive;
    final generasi = _generasiBaris;

    // Confirm before touching the API. A cancel or a barrier dismiss returns
    // false, and nothing has changed at this point, so there is no optimistic
    // UI state to roll back.
    final confirmed = await HargaConfirmationDialog.show(
      context,
      isActivating: !wasActive,
      wasteName: widget.initialData!.name,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final error = wasActive
        ? await notifier.deactivateHarga(id)
        : await notifier.activateHarga(id);
    if (!mounted) {
      if (error == null) _kabarkanTanpaForm(_pesanStatus(wasActive));
      return;
    }

    // Seperti `_handleSimpan`: hasil yang datang setelah panel berganti
    // baris tidak boleh menutup panel baris yang sekarang tampil.
    final barisMasihSama = generasi == _generasiBaris;
    if (barisMasihSama) setState(() => _isSaving = false);

    if (error == null) {
      if (barisMasihSama) widget.onSaved();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: _pesanStatus(wasActive),
      );
      return;
    }

    AppNotification.showError(
      context,
      title: 'Gagal',
      message: error.displayMessage,
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    ({String value, String label, IconData icon}) category,
  ) {
    return DropdownMenuItem<String>(
      value: category.value,
      child: Row(
        children: [
          Icon(category.icon, size: 20, color: AppColors.grey100),
          const SizedBox(width: 12),
          Text(category.label),
        ],
      ),
    );
  }

  Future<void> _handleSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(hargaProvider.notifier);
    final isEditMode = _isEditMode;

    final int priceVal = int.tryParse(_priceController.text) ?? 0;
    final String formattedPrice = CurrencyFormatter.formatRupiah(priceVal);

    final harga = HargaEntity(
      id: widget.initialData?.id ?? '',
      kodeSampah: _kodeSampahController.text.trim(),
      name: _nameController.text.trim(),
      price: priceVal,
      priceFormatted: formattedPrice,
      category: _selectedCategory ?? 'dll',
      subtitle: _descController.text.trim(),
      badgeText: widget.initialData?.badgeText ?? 'Anorganik',
      icon: widget.initialData?.icon ?? Icons.recycling,
      iconColor: widget.initialData?.iconColor ?? AppColors.greenDark,
      isActive: widget.initialData?.isActive ?? true,
    );

    final hargaBerubah = isEditMode && priceVal != widget.initialData!.price;
    final berlakuMulai = _berlakuMulai;

    // Panel hidup lebih lama daripada satu pilihan, jadi baris dapat
    // berganti selagi permintaan ini berjalan.
    final generasi = _generasiBaris;

    setState(() => _isSaving = true);
    var error = isEditMode
        ? await notifier.updateHarga(harga)
        : await notifier.addHarga(harga);
    // Harga tidak ikut PUT: setiap perubahan harga dicatat sebagai versi baru.
    var hanyaHargaGagal = false;
    if (error == null && hargaBerubah) {
      error = await notifier.ubahHarga(UbahHarga(
        id: harga.id,
        harga: priceVal,
        berlakuMulai: berlakuMulai,
      ));
      hanyaHargaGagal = error != null;
    }
    if (!mounted) {
      if (error == null) {
        _kabarkanTanpaForm(pesanSimpanJenis(
          isEditMode: isEditMode,
          hargaBerubah: hargaBerubah,
          berlakuMulai: berlakuMulai,
        ));
      }
      return;
    }

    // Hasil ini milik baris yang memulainya. Bila panel sudah pindah
    // baris, hanya kabarnya yang masih berlaku: `onSaved` akan menutup
    // panel yang kini menampilkan baris lain beserta isian yang belum
    // disimpan, dan error kode akan menempel pada field bukan miliknya.
    final barisMasihSama = generasi == _generasiBaris;
    if (barisMasihSama) setState(() => _isSaving = false);

    if (error == null) {
      if (barisMasihSama) widget.onSaved();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: pesanSimpanJenis(
          isEditMode: isEditMode,
          hargaBerubah: hargaBerubah,
          berlakuMulai: berlakuMulai,
        ),
      );
      return;
    }

    if (hanyaHargaGagal) {
      // PUT sudah menyimpan isian lain; mengulang Simpan aman karena PUT yang
      // sama tidak mengubah apa-apa, lalu harga dikirim lagi.
      AppNotification.showError(
        context,
        title: 'Harga Belum Tersimpan',
        message: 'Perubahan lain sudah tersimpan, tetapi harga baru gagal '
            'disimpan: ${error.displayMessage}. Tekan Simpan lagi untuk '
            'mencoba harganya.',
      );
      return;
    }

    final fields = error.fieldErrors();
    if (barisMasihSama && fields.containsKey('kode')) {
      setState(() => _serverKodeError = fields['kode']);
      _formKey.currentState?.validate();
    }
    AppNotification.showError(
      context,
      title: 'Gagal Menyimpan',
      message: error.displayMessage,
    );
  }

  Widget _buildPilihanBerlaku() {
    final berlakuMulai = _berlakuMulai;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            AppChip(
              label: 'Sekarang',
              selected: berlakuMulai == null,
              onTap: () => setState(() => _berlakuMulai = null),
            ),
            AppChip(
              label: 'Tanggal lain',
              selected: berlakuMulai != null,
              onTap: _pilihTanggalBerlaku,
            ),
          ],
        ),
        if (berlakuMulai != null) ...[
          const SizedBox(height: 4),
          Text(
            'Mulai ${formatTanggalId(berlakuMulai)}, pukul 00.00',
            style: AppTextStyle.small.copyWith(color: AppColors.grey100),
          ),
        ],
      ],
    );
  }

  /// Harga terjadwal dimulai tengah malam waktu setempat pada tanggal yang
  /// dipilih, paling cepat besok (harga hari ini memakai "Sekarang").
  Future<void> _pilihTanggalBerlaku() async {
    final besok = DateUtils.dateOnly(widget.now()).add(const Duration(days: 1));
    final dipilih = await showAppDatePicker(
      context: context,
      initialDate: _berlakuMulai ?? besok,
      firstDate: besok,
      lastDate: besok.add(const Duration(days: _batasJadwalHari - 1)),
    );
    if (dipilih == null || !mounted) return;
    setState(() => _berlakuMulai = DateUtils.dateOnly(dipilih));
  }

  /// Nilai yang dihitung sistem, bukan input, sehingga berlatar abu (SDS 5.1).
  Widget _buildRingkasanHarga(HargaEntity jenis) {
    final berlakuMulai = jenis.berlakuMulai;
    final terjadwal = jenis.hargaTerjadwal;
    final keterangan = AppTextStyle.small.copyWith(color: AppColors.grey100);
    final nilai = AppTextStyle.headline3.copyWith(
      color: AppColors.black,
      fontWeight: AppFontWeight.semibold,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Harga saat ini', style: keterangan),
          const SizedBox(height: 2),
          Text(
            berlakuMulai == null
                ? '${CurrencyFormatter.formatRupiah(jenis.price)}/kg'
                : '${CurrencyFormatter.formatRupiah(jenis.price)}/kg sejak '
                    '${formatTanggalId(berlakuMulai.toLocal())}',
            style: nilai,
          ),
          if (terjadwal != null) ...[
            const SizedBox(height: 8),
            Text('Harga terjadwal', style: keterangan),
            const SizedBox(height: 2),
            Text(
              '${CurrencyFormatter.formatRupiah(terjadwal.harga)}/kg mulai '
              '${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
              style: nilai,
            ),
          ],
        ],
      ),
    );
  }

  /// Peringatan BR-03 pada P-03; kuning menandakan peringatan (SDS 5.1).
  Widget _buildPeringatanTidakSurut() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.avatarYellow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.avatarYellowText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Perubahan harga tidak berlaku surut. Setoran yang sudah '
              'tercatat tetap memakai harga lama.',
              style: AppTextStyle.small.copyWith(color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
