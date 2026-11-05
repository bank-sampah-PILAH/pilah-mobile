import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_consent_dialog.dart';

void main() {
  bool? answer;
  var answered = false;

  Future<void> open(WidgetTester tester) async {
    answer = null;
    answered = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showAnalyticsConsentDialog(context);
              answered = true;
            },
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains what is noted and offers agree and decline',
      (tester) async {
    await open(tester);

    expect(
        find.text('Bantu kami meningkatkan pengalaman Anda'), findsOneWidget);
    expect(
        find.textContaining(
            'Kami mencatat langkah yang Anda lakukan di PILAH, misalnya saat '
            'setoran disimpan'),
        findsOneWidget);
    expect(
        find.textContaining(
            'Kami tidak merekam layar, dan tidak mencatat nama nasabah, '
            'saldo, foto, email, atau nomor telepon'),
        findsOneWidget);
    expect(find.textContaining('mengubah pilihan kapan saja di Profil'),
        findsOneWidget);
    expect(find.text('Setuju'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });

  testWidgets('where the screen is recorded, says so and that all is hidden',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showAnalyticsConsentDialog(context, recordsScreen: true),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kami juga merekam layar'), findsOneWidget);
    expect(
      find.textContaining('nomor telepon disamarkan sehingga tidak terlihat'),
      findsOneWidget,
    );
    expect(find.textContaining('Kami tidak merekam layar'), findsNothing);
  });

  testWidgets(
      'where the screen is recorded, says the fixed labels stay visible and '
      'does not claim that only the layout can be seen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showAnalyticsConsentDialog(context, recordsScreen: true),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Label dan judul tetap dari aplikasi tetap terlihat'),
      findsOneWidget,
    );
    expect(find.textContaining('hanya tata letak'), findsNothing);
    expect(find.textContaining('Semua tulisan dan gambar'), findsNothing);
  });

  testWidgets(
      'where the screen is recorded, says the site address and its files are '
      'part of the recording while the page route is not sent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showAnalyticsConsentDialog(context, recordsScreen: true),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rute halaman tidak dikirim'), findsOneWidget);
    expect(find.textContaining('alamat situs dan berkas bawaannya'),
        findsOneWidget);
    expect(find.textContaining('Alamat halaman tidak dikirim'), findsNothing);
  });

  testWidgets('no longer says the screen is recorded or that data is covered',
      (tester) async {
    await open(tester);

    expect(find.textContaining('merekam layar dan gerakan'), findsNothing);
    expect(find.textContaining('akan ditutup'), findsNothing);
    expect(find.textContaining('Rekaman'), findsNothing);
  });

  testWidgets('stays a readable width on a wide window', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await open(tester);

    // The long paragraph used to stretch the white surface across the window.
    // The AlertDialog widget itself always fills it, so the Material inside is
    // what is measured.
    final surface = find
        .descendant(
            of: find.byType(AlertDialog), matching: find.byType(Material))
        .first;
    expect(tester.getSize(surface).width, lessThanOrEqualTo(480));
  });

  testWidgets('agreeing answers true', (tester) async {
    await open(tester);

    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(answer, isTrue);
    expect(find.text('Bantu kami meningkatkan pengalaman Anda'), findsNothing);
  });

  testWidgets('declining answers false', (tester) async {
    await open(tester);

    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('tapping outside or going back does not answer for the user',
      (tester) async {
    await open(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
        find.text('Bantu kami meningkatkan pengalaman Anda'), findsOneWidget);
    expect(answered, isFalse);
  });

  testWidgets('says who receives the data and what comes along with it',
      (tester) async {
    await open(tester);

    expect(find.textContaining('PostHog'), findsOneWidget);
    expect(find.textContaining('di luar negeri'), findsOneWidget);
    expect(find.textContaining('jenis perangkat dan peramban'), findsOneWidget);
    expect(
        find.textContaining('perkiraan lokasi dari alamat IP'), findsOneWidget);
    expect(find.textContaining('Alamat halaman tidak dikirim'), findsOneWidget);
  });

  testWidgets(
      'does not claim that only PILAH sees the data, or promise events '
      'that are not sent', (tester) async {
    await open(tester);

    expect(find.textContaining('Data hanya dilihat tim PILAH'), findsNothing);
    expect(find.textContaining('jadwal dibuat'), findsNothing);
  });
}
