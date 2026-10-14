import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

class NasabahSetoranDetailSheet extends StatefulWidget {
  const NasabahSetoranDetailSheet({
    super.key,
    required this.loadDetail,
  });

  final Future<NasabahSetoranDetail> Function() loadDetail;

  @override
  State<NasabahSetoranDetailSheet> createState() =>
      _NasabahSetoranDetailSheetState();
}

class _NasabahSetoranDetailSheetState extends State<NasabahSetoranDetailSheet> {
  late Future<NasabahSetoranDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.loadDetail();
  }

  void _retry() => setState(() {
        _detail = widget.loadDetail();
      });

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NasabahStyle.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Detail Setoran',
                    style: NasabahStyle.text(20, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<NasabahSetoranDetail>(
                    future: _detail,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: NasabahStyle.emerald,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        final error = snapshot.error;
                        return Column(
                          children: [
                            Text(
                              error is NasabahApiException
                                  ? error.message
                                  : error is NetworkException
                                      ? error.displayMessage
                                      : 'Rincian setoran gagal dimuat.',
                              textAlign: TextAlign.center,
                              style: NasabahStyle.text(13),
                            ),
                            TextButton(
                              onPressed: _retry,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        );
                      }
                      return _detailContent(snapshot.data!);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _detailContent(NasabahSetoranDetail detail) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Tanggal', _dateTime(detail.date)),
          _row('Total setoran', nasabahRupiah(detail.amount)),
          _row('Saldo setelah', nasabahRupiah(detail.balanceAfter)),
          if (detail.note.isNotEmpty) _row('Catatan', detail.note),
          const SizedBox(height: 16),
          Text(
            'RINCIAN SETORAN',
            style: NasabahStyle.text(
              11,
              weight: FontWeight.w600,
              color: NasabahStyle.muted,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in detail.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NasabahCard(
                padding: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.name,
                      style: NasabahStyle.text(14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _row('Berat', '${item.weight} kg'),
                    _row('Harga/kg', nasabahRupiah(item.price)),
                    _row('Subtotal', nasabahRupiah(item.subtotal)),
                  ],
                ),
              ),
            ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: NasabahStyle.text(13, color: NasabahStyle.muted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: NasabahStyle.text(13, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  String _dateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour.$minute';
  }
}
