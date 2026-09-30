import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_confirmation_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

class DetailNasabahBottomSheet extends StatefulWidget {
  /// Nasabah yang ditampilkan, memakai entity domain apa adanya.
  final NasabahEntity nasabah;

  final NasabahCubit? nasabahCubit;

  const DetailNasabahBottomSheet({
    super.key,
    required this.nasabah,
    this.nasabahCubit,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4);
  static const Color errorColor = Color(0xFFBA1A1A);

  @override
  State<DetailNasabahBottomSheet> createState() =>
      _DetailNasabahBottomSheetState();
}

class _DetailNasabahBottomSheetState extends State<DetailNasabahBottomSheet> {
  Future<NasabahRingkasan?>? _ringkasanFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.nasabah.id;
    if (id.isNotEmpty && widget.nasabahCubit != null) {
      _ringkasanFuture = widget.nasabahCubit!.fetchRingkasan(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nasabah = widget.nasabah;
    final bool isActive = nasabah.isActive;
    final String initials = nasabah.initials;
    final String name = nasabah.name;
    final String phone = nasabah.phone;
    final String balance = nasabah.balance;
    final String idNasabah = nasabah.idNasabah;
    final String email = nasabah.email.isNotEmpty ? nasabah.email : '-';
    final String jenisKelamin =
        nasabah.jenisKelamin.isNotEmpty ? nasabah.jenisKelamin : '-';
    final String tanggalLahir =
        nasabah.tanggalLahir.isNotEmpty ? nasabah.tanggalLahir : '-';
    final String address = nasabah.address.isNotEmpty ? nasabah.address : '-';
    final String tanggalDaftar =
        nasabah.tanggalDaftar.isNotEmpty ? nasabah.tanggalDaftar : '-';
    // Email nasabah berakun menjadi kunci penautan ke akunnya dan tidak dapat
    // diubah pengurus (PIL-288). Tanpa penanda ini, pengurus baru tahu batas
    // itu dari 403 setelah mengisi form. Default tidak terkunci: payload lama
    // belum membawa penandanya.
    final bool punyaAkun = nasabah.punyaAkun;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header Section
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isActive
                          ? DetailNasabahBottomSheet.mintTint
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: AppTextStyle.headline1.copyWith(
                        color: isActive
                            ? DetailNasabahBottomSheet.emeraldPrimary
                            : Colors.red[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyle.headline1.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              idNasabah,
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomStatusBadge(isActive: isActive),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Card Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID Nasabah', idNasabah, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', email, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Jenis Kelamin',
                      jenisKelamin,
                      isBold: true,
                      icon: Icon(
                        jenisKelamin.toLowerCase() == 'perempuan'
                            ? Icons.female
                            : Icons.male,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Tanggal Lahir', tanggalLahir, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nomor WA', phone, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Saldo',
                      balance,
                      isBold: true,
                      valueColor: DetailNasabahBottomSheet.emeraldPrimary,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Tanggal Daftar',
                      tanggalDaftar,
                      isBold: true,
                      icon: Icon(Icons.calendar_month,
                          size: 16, color: Colors.indigo[300]),
                    ),
                    const SizedBox(height: 16),
                    _buildRingkasanRow(),
                    const SizedBox(height: 20),
                    Text(
                      'Alamat',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address,
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (punyaAkun) ...[
                const SizedBox(height: 16),
                _buildEmailDikelolaNasabah(),
              ],
              if (punyaAkun) _buildProfilAkunBerbeda(),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              EditNasabahBottomSheet(nasabah: nasabah),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            DetailNasabahBottomSheet.emeraldPrimary,
                        side: const BorderSide(
                            color: DetailNasabahBottomSheet.emeraldPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyle.title1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.nasabahCubit == null) return;

                        showDialog(
                          context: context,
                          builder: (context) => NasabahConfirmationDialog(
                            isActivating: !isActive,
                            customerName: name,
                            customerId:
                                nasabah.id.isNotEmpty ? nasabah.id : idNasabah,
                            nasabahCubit: widget.nasabahCubit!,
                          ),
                        );
                      },
                      icon: Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: Colors.white),
                      label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? DetailNasabahBottomSheet.errorColor
                            : DetailNasabahBottomSheet.emeraldPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: AppTextStyle.title1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keterangan bahwa email ini kunci masuk pemilik akun, bukan data yang
  /// boleh diganti pengurus.
  ///
  /// Sekadar penjelasan tampilan: batasnya tetap ditegakkan server pada setiap
  /// permintaan (PIL-223), bukan oleh layar ini.
  Widget _buildEmailDikelolaNasabah() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DetailNasabahBottomSheet.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 18,
            color: DetailNasabahBottomSheet.emeraldPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email dikelola oleh nasabah',
                  style: AppTextStyle.title1.copyWith(
                    color: DetailNasabahBottomSheet.emeraldPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pengurus dapat memperbaiki data lain, tetapi tidak emailnya.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Labels for the backend keys of `profil_berbeda`.
  static const Map<String, String> _labelField = {
    'nama': 'Nama',
    'jenis_kelamin': 'Jenis kelamin',
    'tanggal_lahir': 'Tanggal lahir',
    'alamat': 'Alamat',
    'no_hp': 'Nomor HP',
  };

  String _nilaiAkun(NasabahProfilAkun akun, String field) {
    final value = switch (field) {
      'nama' => akun.nama,
      'jenis_kelamin' => akun.jenisKelamin,
      'tanggal_lahir' => akun.tanggalLahir,
      'alamat' => akun.alamat,
      'no_hp' => akun.noHp,
      _ => '',
    };
    return value.isNotEmpty ? value : '-';
  }

  /// Catatan pengurus dan profil akun nasabah terpisah. Bila nasabah mengisi
  /// hal yang berbeda, tunjukkan bedanya dan tawarkan untuk menyamakan.
  Widget _buildProfilAkunBerbeda() {
    return FutureBuilder<NasabahRingkasan?>(
      future: _ringkasanFuture,
      builder: (context, snapshot) {
        final ringkasan = snapshot.data;
        final akun = ringkasan?.profilAkun;
        final berbeda = ringkasan?.profilBerbeda ?? const <String>[];
        if (akun == null || berbeda.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_problem,
                        size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Data akun berbeda',
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Nasabah ini memiliki data berbeda dari catatan yang anda miliki.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                for (final field in berbeda)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoRow(
                      _labelField[field] ?? field,
                      _nilaiAkun(akun, field),
                    ),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.nasabahCubit == null ? null : _samakan,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[800],
                      side: BorderSide(color: Colors.orange[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Samakan dengan data akun'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _samakan() async {
    final nama = widget.nasabah.name;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Samakan dengan data akun?'),
        content: Text(
          'Catatan $nama di bank sampah ini akan diganti dengan data yang '
          'nasabah isikan pada akunnya. Anda tetap dapat menyuntingnya lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Samakan'),
          ),
        ],
      ),
    );
    if (konfirmasi != true || !mounted) return;

    // The root overlay outlives this sheet, so it hosts the notification.
    final overlayContext = Navigator.of(context, rootNavigator: true).context;
    final sheetContext = context;
    final error = await widget.nasabahCubit!.sinkronProfil(widget.nasabah.id);
    if (!mounted || !sheetContext.mounted) return;

    if (error == null) {
      sheetContext.pop();
      AppNotification.showSuccess(
        overlayContext,
        title: 'Data disamakan',
        message: 'Catatan $nama sekarang sama dengan data akunnya.',
      );
    } else {
      AppNotification.showError(
        overlayContext,
        title: 'Gagal',
        message: error.displayMessage,
      );
    }
  }

  Widget _buildRingkasanRow() {
    return FutureBuilder<NasabahRingkasan?>(
      future: _ringkasanFuture,
      builder: (context, snapshot) {
        String value;
        if (_ringkasanFuture == null) {
          value = '-';
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          value = 'Memuat...';
        } else if (snapshot.hasData && snapshot.data != null) {
          final r = snapshot.data!;
          value = '${r.jumlahTransaksi} Trx | ${r.totalKg} kg';
        } else {
          value = '-';
        }
        return _buildInfoRow(
          'Ringkasan Trx',
          value,
          isBold: true,
          valueColor: AppColors.statPurple,
          icon: Icon(Icons.bar_chart, size: 16, color: AppColors.statPurple),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    Widget? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyle.title1.copyWith(
                    color: valueColor ?? Colors.black87,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
