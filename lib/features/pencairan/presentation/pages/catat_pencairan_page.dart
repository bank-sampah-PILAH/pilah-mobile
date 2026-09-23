import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/pencairan_validator.dart';
import '../blocs/pencairan_cubit.dart';
import '../blocs/pencairan_state.dart';

class CatatPencairanArgs {
  final String nasabahId;
  final String nasabahNama;

  const CatatPencairanArgs({
    required this.nasabahId,
    required this.nasabahNama,
  });
}

/// Pengurus records a payout for one nasabah. Pops `true` once recorded so the
/// caller can refresh saldo.
class CatatPencairanPage extends StatelessWidget {
  static const route = '/catat-pencairan';

  final CatatPencairanArgs args;

  const CatatPencairanPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<PencairanCubit>(),
      child: CatatPencairanView(
        nasabahId: args.nasabahId,
        nasabahNama: args.nasabahNama,
      ),
    );
  }
}

class CatatPencairanView extends StatefulWidget {
  final String nasabahId;
  final String nasabahNama;
  final DateTime Function() now;

  const CatatPencairanView({
    super.key,
    required this.nasabahId,
    required this.nasabahNama,
    this.now = DateTime.now,
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

  @override
  void initState() {
    super.initState();
    _tanggal = widget.now();
    context.read<PencairanCubit>().loadSaldo(widget.nasabahId);
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  int? get _nominal => int.tryParse(_nominalController.text);

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
            nasabahId: widget.nasabahId,
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
        final nominal = _nominal;
        final saldoLoaded = state.saldoStatus == SaldoStatus.loaded;
        final localError = _nominalController.text.isEmpty
            ? null
            : PencairanValidator.nominal(nominal, saldo: state.saldo);
        final canSubmit = saldoLoaded &&
            state.submitStatus != SubmitStatus.submitting &&
            PencairanValidator.nominal(nominal, saldo: state.saldo) == null;

        return Scaffold(
          appBar: AppBar(title: const Text('Catat Pencairan')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NasabahSaldoCard(
                    nama: widget.nasabahNama,
                    state: state,
                    onRetry: () => context
                        .read<PencairanCubit>()
                        .loadSaldo(widget.nasabahId),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('nominal-field'),
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      // The server's rejection was about the old value.
                      context.read<PencairanCubit>().clearNominalError();
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
                          onSelected: (_) => setState(() => _metode = metode),
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
                  _Ringkasan(
                    saldo: state.saldo,
                    nominal: localError == null ? nominal : null,
                  ),
                  const SizedBox(height: 24),
                  CustomPrimaryButton(
                    key: const Key('submit-pencairan'),
                    title: state.submitStatus == SubmitStatus.submitting
                        ? 'Menyimpan...'
                        : 'Catat Pencairan',
                    onPressed:
                        canSubmit ? () => _confirmAndSubmit(nominal!) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NasabahSaldoCard extends StatelessWidget {
  final String nama;
  final PencairanState state;
  final VoidCallback onRetry;

  const _NasabahSaldoCard({
    required this.nama,
    required this.state,
    required this.onRetry,
  });

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
          Text(nama, style: AppTextStyle.title1),
          const SizedBox(height: 8),
          Text('Saldo sekarang', style: AppTextStyle.small),
          const SizedBox(height: 4),
          saldo,
        ],
      ),
    );
  }
}

class _Ringkasan extends StatelessWidget {
  final int saldo;
  final int? nominal;

  const _Ringkasan({required this.saldo, required this.nominal});

  @override
  Widget build(BuildContext context) {
    final nominal = this.nominal;
    return Column(
      children: [
        _row('Dicairkan',
            nominal == null ? '-' : 'Rp ${formatRupiahId(nominal)}'),
        _row(
          'Sisa saldo',
          nominal == null ? '-' : 'Rp ${formatRupiahId(saldo - nominal)}',
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyle.small),
            Text(value, style: AppTextStyle.title1),
          ],
        ),
      );
}

class _PencairanBerhasilSheet extends StatelessWidget {
  final Pencairan created;

  const _PencairanBerhasilSheet({required this.created});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: CatatPencairanView.emeraldPrimary,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text('Pencairan berhasil dicatat', style: AppTextStyle.title1),
          const SizedBox(height: 16),
          Text(
            'Dicairkan Rp ${formatRupiahId(created.nominal)} '
            '(${created.metode.label})',
            style: AppTextStyle.small,
          ),
          const SizedBox(height: 8),
          Text('Saldo sesudah', style: AppTextStyle.small),
          Text(
            'Rp ${formatRupiahId(created.saldoSesudah)}',
            style: AppTextStyle.title1.copyWith(
              color: CatatPencairanView.emeraldPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomPrimaryButton(
            title: 'Selesai',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
