import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_setoran_detail.dart';

TransaksiDetailEntity _detail({bool dibatalkan = false}) =>
    TransaksiDetailEntity(
      name: 'Budi Santoso',
      amountFormatted: 'Rp 7.000',
      balanceFormatted: 'Rp 50.000',
      waStatus: 'sent',
      items: [
        ItemSetoranEntity(
          jenis: 'Plastik PET',
          berat: '2 kg',
          harga: 'Rp 3.500',
          subtotal: 'Rp 7.000',
        ),
      ],
      isDibatalkan: dibatalkan,
      alasanBatal: dibatalkan ? 'Salah pilih nasabah' : '',
      dibatalkanOlehNama: dibatalkan ? 'Pengurus Demo' : '',
      dibatalkanPada: dibatalkan ? DateTime(2026, 11, 1, 9, 5) : null,
    );

Future<void> _pump(WidgetTester tester, TransaksiDetailEntity detail) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AktivitasSetoranDetail(
          transactionId: 't1',
          loadDetail: (_) async => detail,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// PIL-428 in the inline Riwayat detail from PIL-453: a voided setoran says
/// who voided it, when and why, as the detail sheet did.
void main() {
  testWidgets('a voided setoran shows who voided it, when and why',
      (tester) async {
    await _pump(tester, _detail(dibatalkan: true));

    expect(find.text('PEMBATALAN'), findsOneWidget);
    expect(find.text('Dibatalkan oleh Pengurus Demo • 01/11/2026 09.05'),
        findsOneWidget);
    expect(find.text('Alasan: Salah pilih nasabah'), findsOneWidget);
  });

  testWidgets('a voided setoran shows no saldo after it', (tester) async {
    // The saldo it would show was computed without this setoran.
    await _pump(tester, _detail(dibatalkan: true));

    expect(find.text('Saldo setelah transaksi'), findsNothing);
    expect(find.text('Rp 50.000'), findsNothing);
  });

  testWidgets('a tercatat setoran keeps its saldo and has no pembatalan',
      (tester) async {
    await _pump(tester, _detail());

    expect(find.text('Saldo setelah transaksi'), findsOneWidget);
    expect(find.text('PEMBATALAN'), findsNothing);
  });
}
