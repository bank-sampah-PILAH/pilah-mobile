import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/pencairan_validator.dart';
import '../blocs/pencairan_cubit.dart';
import '../blocs/pencairan_state.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

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

  /// Matches the "PILIH NASABAH" section label already on this screen, so
  /// every section header in the form reads the same way.
  Widget _buildLabel(String text) => Text(
        text,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      );

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
          'Pencairan Rp ${CurrencyFormatter.formatNumber(nominal)} akan dicatat sebagai '
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

  /// A bottom sheet on a phone; on a wide window a sheet would stretch across
  /// the whole screen, so the same summary opens as a centred dialog.
  Future<void> _showBerhasil(Pencairan created) async {
    if (context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          // The summary is square at the bottom (it is drawn for a sheet).
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _lebarDialogBerhasil),
            child: _PencairanBerhasilSheet(created: created),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        builder: (sheetContext) => _PencairanBerhasilSheet(created: created),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  static const double _lebarDialogBerhasil = 420;

  /// Nominal, metode, tanggal and keterangan: the same fields in either
  /// layout.
  List<Widget> _buildIsian(PencairanState state, String? localError) => [
        _buildLabel('NOMINAL'),
        const SizedBox(height: 8),
        TextField(
          key: const Key('nominal-field'),
          controller: _nominalController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyle.small.copyWith(color: Colors.black87),
          onChanged: (_) {
            // The server's rejection was about the old value.
            context.read<PencairanCubit>().clearNominalError();
            setState(() {});
          },
          decoration: appInputDecoration(
            hintText: 'Contoh: 50000',
          ).copyWith(
            prefixText: 'Rp ',
            prefixStyle: AppTextStyle.small.copyWith(color: Colors.black87),
            errorText: localError ?? state.nominalError,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('METODE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final metode in MetodePencairan.values)
              AppChip(
                key: Key('metode-chip-${metode.name}'),
                label: metode.label,
                selected: _metode == metode,
                onTap: () => setState(() => _metode = metode),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('TANGGAL'),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('tanggal-field'),
          onTap: _pickTanggal,
          child: InputDecorator(
            decoration: appInputDecoration().copyWith(
              suffixIcon: const Icon(Icons.calendar_month, color: Colors.grey),
            ),
            child: Text(
              formatTanggalId(_tanggal),
              style: AppTextStyle.small.copyWith(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('KETERANGAN (OPSIONAL)'),
        const SizedBox(height: 8),
        TextField(
          key: const Key('keterangan-field'),
          controller: _keteranganController,
          maxLength: 255,
          maxLines: 2,
          style: AppTextStyle.small.copyWith(color: Colors.black87),
          decoration: appInputDecoration(
            hintText: 'Keterangan (opsional)',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PencairanCubit, PencairanState>(
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success &&
            state.created != null) {
          context.read<RiwayatAktivitasCubit>().load(silent: true);
          context.read<RecentActivityCubit>().load(silent: true);
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

        final lebar = context.layoutBreakpoint == LayoutBreakpoint.expanded;
        final saldoCard = customer == null
            ? null
            : _SaldoCard(
                state: state,
                onRetry: () =>
                    context.read<PencairanCubit>().loadSaldo(customer.id),
              );
        final ringkasan = customer == null
            ? null
            : _RingkasanCard(
                saldo: state.saldo,
                nominal: localError == null ? nominal : null,
              );
        final submitButton = CustomPrimaryButton(
          key: const Key('submit-pencairan'),
          title: state.submitStatus == SubmitStatus.submitting
              ? 'Menyimpan...'
              : 'Catat Pencairan',
          onPressed: canSubmit
              ? () => _confirmAndSubmit(nominal!)
              : (customer == null
                  ? () => setState(() => _hasSubmitted = true)
                  : null),
        );
        final header = Padding(
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
                  child:
                      Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
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
        );
        final formScroll = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                if (!lebar) ...[
                  const SizedBox(height: 24),
                  saldoCard!,
                ],
                const SizedBox(height: 24),
                ..._buildIsian(state, localError),
                if (!lebar) ...[
                  const SizedBox(height: 8),
                  ringkasan!,
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        );

        // A wide window keeps the money in view: saldo, what is left after
        // the payout, and the button that records it sit in a panel beside
        // the form, not in a bar stretched across the bottom of the screen.
        if (lebar) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: ContentBounds(
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: formScroll),
                          SizedBox(
                            width: LayoutBreakpoint.sidePanelWidth,
                            child: SingleChildScrollView(
                              key: const Key('catat-pencairan-panel'),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (saldoCard != null) ...[
                                    saldoCard,
                                    const SizedBox(height: 16),
                                    ringkasan!,
                                    const SizedBox(height: 16),
                                  ],
                                  submitButton,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [header, Expanded(child: formScroll)],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: submitButton,
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
          'Rp ${CurrencyFormatter.formatNumber(state.saldo)}',
          style: AppTextStyle.title1.copyWith(
            color: AppColors.greenDark,
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
            nominal == null
                ? '-'
                : 'Rp ${CurrencyFormatter.formatNumber(nominal)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _row(
            'Sisa saldo',
            nominal == null
                ? '-'
                : 'Rp ${CurrencyFormatter.formatNumber(saldo - nominal)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  // Both sides may shrink: in the narrow side panel of a wide window a large
  // nominal and its label have to share well under 300 px.
  Widget _row(String label, String value, {bool emphasized = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyle.small.copyWith(
                color: emphasized ? Colors.black87 : Colors.grey[500],
                fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
                fontSize: emphasized ? 16 : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style:
                    (emphasized ? AppTextStyle.headline1 : AppTextStyle.title1)
                        .copyWith(
                  color: emphasized ? AppColors.greenDark : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: emphasized ? 20 : 15,
                ),
              ),
            ),
          ),
        ],
      );
}

/// Mirrors [TransaksiBerhasilPanel]'s structure (icon, title, bordered
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
              color: AppColors.greenDark,
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
                _row('Dicairkan',
                    'Rp ${CurrencyFormatter.formatNumber(created.nominal)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _row('Saldo sesudah',
                    'Rp ${CurrencyFormatter.formatNumber(created.saldoSesudah)}',
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
          Text(label,
              style: AppTextStyle.small.copyWith(color: Colors.grey[600])),
          Text(
            value,
            style: AppTextStyle.title1.copyWith(
              color: isPrimary ? AppColors.greenDark : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isPrimary ? 16 : 14,
            ),
          ),
        ],
      );
}
