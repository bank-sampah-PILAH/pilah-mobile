import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/pencairan_validator.dart';
import '../blocs/pencairan_cubit.dart';
import '../blocs/pencairan_state.dart';

/// Pengurus records a payout. Nasabah is picked inside the form — the same
/// active-nasabah sheet Setoran Baru uses — rather than supplied by the
/// caller, so this page needs no route args (PIL-282). Pops `true` once
/// recorded so the caller can refresh saldo.
class CatatPencairanPage extends StatelessWidget {
  static const route = '/catat-pencairan';

  const CatatPencairanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<PencairanCubit>(),
      child: const CatatPencairanView(),
    );
  }
}

class CatatPencairanView extends StatefulWidget {
  final DateTime Function() now;

  /// Seeds the picked nasabah, skipping the picker section. Exists for
  /// testability, mirroring how a route arg used to work; production always
  /// starts unselected.
  final NasabahEntity? initialCustomer;

  const CatatPencairanView({
    super.key,
    this.now = DateTime.now,
    this.initialCustomer,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  State<CatatPencairanView> createState() => _CatatPencairanViewState();
}

class _CatatPencairanViewState extends State<CatatPencairanView> {
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  MetodePencairan _metode = MetodePencairan.tunai;
  late DateTime _tanggal;
  NasabahEntity? _selectedCustomer;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tanggal = widget.now();
    _selectedCustomer = widget.initialCustomer;
    final customer = _selectedCustomer;
    if (customer != null) {
      context.read<PencairanCubit>().loadSaldo(customer.id);
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  int? get _nominal => int.tryParse(_nominalController.text);

  void _onCustomerSelected(NasabahEntity customer) {
    setState(() => _selectedCustomer = customer);
    context.read<PencairanCubit>().loadSaldo(customer.id);
  }

  Future<void> _pickTanggal() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _tanggal = DateUtils.isSameDay(picked, now)
          ? now
          : DateTime(
              picked.year, picked.month, picked.day, now.hour, now.minute);
    });
  }

  Future<void> _confirmAndSubmit(int nominal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi pencairan'),
        content: Text(
          'Pencairan Rp ${formatRupiahId(nominal)} akan dicatat sebagai '
          'pembayaran ${_metode.label}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Catat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PencairanCubit>().submit(
          PencairanRequest(
            nasabahId: _selectedCustomer!.id,
            nominal: nominal,
            metode: _metode,
            tanggal: _tanggal,
            keterangan: _keteranganController.text,
          ),
        );
  }

  Future<void> _showBerhasil(Pencairan created) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (sheetContext) => _PencairanBerhasilSheet(created: created),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PencairanCubit, PencairanState>(
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success &&
            state.created != null) {
          context.read<RiwayatAktivitasCubit>().load(silent: true);
          _showBerhasil(state.created!);
        } else if (state.errorMessage != null &&
            state.saldoStatus != SaldoStatus.failure) {
          AppNotification.showError(
            context,
            title: 'Pencairan gagal',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final customer = _selectedCustomer;
        final nominal = _nominal;
        final saldoLoaded = state.saldoStatus == SaldoStatus.loaded;
        final localError = _nominalController.text.isEmpty
            ? null
            : PencairanValidator.nominal(nominal, saldo: state.saldo);
        final canSubmit = customer != null &&
            saldoLoaded &&
            state.submitStatus != SubmitStatus.submitting &&
            PencairanValidator.nominal(nominal, saldo: state.saldo) == null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back,
                              color: Colors.grey[800], size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Catat Pencairan',
                        style: AppTextStyle.headline1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PILIH NASABAH',
                          style: AppTextStyle.extraSmall.copyWith(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PilihNasabahSection(
                          selectedCustomer: customer,
                          onCustomerSelected: _onCustomerSelected,
                          hasError: _hasSubmitted && customer == null,
                          errorText: 'Nasabah harus dipilih',
                        ),
                        if (customer != null) ...[
                          const SizedBox(height: 24),
                          _SaldoCard(
                            state: state,
                            onRetry: () => context
                                .read<PencairanCubit>()
                                .loadSaldo(customer.id),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            key: const Key('nominal-field'),
                            controller: _nominalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) {
                              // The server's rejection was about the old value.
                              context
                                  .read<PencairanCubit>()
                                  .clearNominalError();
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Nominal',
                              prefixText: 'Rp ',
                              border: const OutlineInputBorder(),
                              errorText: localError ?? state.nominalError,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Metode', style: AppTextStyle.small),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final metode in MetodePencairan.values)
                                ChoiceChip(
                                  label: Text(metode.label),
                                  selected: _metode == metode,
                                  onSelected: (_) =>
                                      setState(() => _metode = metode),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            key: const Key('tanggal-field'),
                            onTap: _pickTanggal,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_month),
                              ),
                              child: Text(formatTanggalId(_tanggal)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('keterangan-field'),
                            controller: _keteranganController,
                            maxLength: 255,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Keterangan (opsional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _RingkasanCard(
                            saldo: state.saldo,
                            nominal: localError == null ? nominal : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomPrimaryButton(
                key: const Key('submit-pencairan'),
                title: state.submitStatus == SubmitStatus.submitting
                    ? 'Menyimpan...'
                    : 'Catat Pencairan',
                onPressed: canSubmit
                    ? () => _confirmAndSubmit(nominal!)
                    : (customer == null
                        ? () => setState(() => _hasSubmitted = true)
                        : null),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SaldoCard extends StatelessWidget {
  final PencairanState state;
  final VoidCallback onRetry;

  const _SaldoCard({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final Widget saldo;
    switch (state.saldoStatus) {
      case SaldoStatus.loaded:
        saldo = Text(
          'Rp ${formatRupiahId(state.saldo)}',
          style: AppTextStyle.title1.copyWith(
            color: CatatPencairanView.emeraldPrimary,
            fontWeight: FontWeight.bold,
          ),
        );
      case SaldoStatus.failure:
        saldo = TextButton(
          onPressed: onRetry,
          child: const Text('Gagal memuat saldo. Coba lagi'),
        );
      case SaldoStatus.initial:
      case SaldoStatus.loading:
        saldo = const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo sekarang', style: AppTextStyle.small),
          const SizedBox(height: 4),
          saldo,
        ],
      ),
    );
  }
}

/// Mirrors [TransactionSummarySection]'s look (white card, soft shadow,
/// divider, bold final row) for the same form-time-summary role in Setoran.
class _RingkasanCard extends StatelessWidget {
  final int saldo;
  final int? nominal;

  const _RingkasanCard({required this.saldo, required this.nominal});

  @override
  Widget build(BuildContext context) {
    final nominal = this.nominal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row(
            'Dicairkan',
            nominal == null ? '-' : 'Rp ${formatRupiahId(nominal)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _row(
            'Sisa saldo',
            nominal == null ? '-' : 'Rp ${formatRupiahId(saldo - nominal)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasized = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyle.small.copyWith(
              color: emphasized ? Colors.black87 : Colors.grey[500],
              fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
              fontSize: emphasized ? 16 : null,
            ),
          ),
          Text(
            value,
            style: (emphasized ? AppTextStyle.headline1 : AppTextStyle.title1)
                .copyWith(
              color: emphasized
                  ? CatatPencairanView.emeraldPrimary
                  : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: emphasized ? 20 : 15,
            ),
          ),
        ],
      );
}

/// Mirrors [TransaksiBerhasilBottomSheet]'s structure (icon, title, bordered
/// detail box with dividers, primary CTA).
class _PencairanBerhasilSheet extends StatelessWidget {
  final Pencairan created;

  const _PencairanBerhasilSheet({required this.created});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: CatatPencairanView.emeraldPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pencairan Berhasil!',
            style: AppTextStyle.headline1.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dicairkan sebagai pembayaran ${created.metode.label}.',
            style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _row('Dicairkan', 'Rp ${formatRupiahId(created.nominal)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _row('Saldo sesudah',
                    'Rp ${formatRupiahId(created.saldoSesudah)}',
                    isPrimary: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CustomPrimaryButton(
            title: 'Selesai',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isPrimary = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyle.small.copyWith(color: Colors.grey[600])),
          Text(
            value,
            style: AppTextStyle.title1.copyWith(
              color: isPrimary
                  ? CatatPencairanView.emeraldPrimary
                  : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isPrimary ? 16 : 14,
            ),
          ),
        ],
      );
}
