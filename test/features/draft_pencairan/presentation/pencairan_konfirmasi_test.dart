import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_konfirmasi_sheet.dart';

void main() {
  bool? answer;

  Future<void> open(
    WidgetTester tester, {
    KonfirmasiNada nada = KonfirmasiNada.normal,
    Widget? isi,
  }) async {
    answer = null;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('buka'),
            onPressed: () async => answer = await showPencairanKonfirmasi(
              context,
              icon: Icons.payments_outlined,
              judul: 'Konfirmasi pembayaran',
              pesan: 'Saldo akan dikurangi.',
              isi: isi,
              ya: 'Ya, sudah dibayar',
              tidak: 'Belum',
              nada: nada,
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('buka')));
    await tester.pumpAndSettle();
  }

  testWidgets('is a white, rounded bottom sheet, not a plain dialog',
      (tester) async {
    await open(tester);

    expect(find.byType(AlertDialog), findsNothing);
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, Colors.white);
    expect((sheet.shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(24)));
  });

  testWidgets('says what is asked: an icon, a title and a line of explanation',
      (tester) async {
    await open(tester);

    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    expect(find.text('Konfirmasi pembayaran'), findsOneWidget);
    expect(find.text('Saldo akan dikurangi.'), findsOneWidget);
  });

  testWidgets('can carry its own content between the text and the buttons',
      (tester) async {
    await open(tester, isi: const Text('3 nasabah', key: Key('isi')));

    expect(find.byKey(const Key('isi')), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('isi'))).dy,
        greaterThan(tester.getTopLeft(find.text('Saldo akan dikurangi.')).dy));
    expect(tester.getTopLeft(find.byKey(const Key('isi'))).dy,
        lessThan(tester.getTopLeft(find.text('Ya, sudah dibayar')).dy));
  });

  testWidgets('the two answers sit side by side, the no on the left',
      (tester) async {
    await open(tester);

    final tidak = tester.getRect(find.byKey(const Key('konfirmasi-tidak')));
    final ya = tester.getRect(find.byKey(const Key('konfirmasi-ya')));
    expect(tidak.right, lessThanOrEqualTo(ya.left));
    expect((tidak.center.dy - ya.center.dy).abs(), lessThan(2));
  });

  testWidgets('yes answers true and closes', (tester) async {
    await open(tester);

    await tester.tap(find.text('Ya, sudah dibayar'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('no, and dismissing, answer false', (tester) async {
    await open(tester);
    await tester.tap(find.text('Belum'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);

    await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  testWidgets('a harmful action reads red, a plain one green', (tester) async {
    Color? yaColor() => tester
        .widget<ElevatedButton>(find.byKey(const Key('konfirmasi-ya')))
        .style
        ?.backgroundColor
        ?.resolve({});

    await open(tester);
    expect(yaColor(), AppColors.greenDark);
    await tester.tap(find.text('Belum'));
    await tester.pumpAndSettle();

    await open(tester, nada: KonfirmasiNada.bahaya);
    expect(yaColor(), const Color(0xFFC62828));
  });
}
