import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';

/// Pumps a screen whose only job is to raise [show] on tap, taps it, and lets
/// the entrance animation finish.
Future<void> _raise(
  WidgetTester tester,
  void Function(BuildContext context) show,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => show(context),
            child: const Text('raise'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('raise'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Runs the auto-dismiss timer out so no timer is left pending at test end.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Pumps in fixed steps until [finder] finds nothing, up to [limit] frames.
///
/// `pumpAndSettle` is unusable for the loading toast: its spinner animates
/// forever, so a settle during teardown never returns. Stepping by hand also
/// keeps the assertion honest — it fails on a timeout instead of hanging.
Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int limit = 40,
}) async {
  for (var i = 0; i < limit && finder.evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('AppNotification.showWarning', () {
    testWidgets('carries the amber tone, not a success or error one',
        (tester) async {
      await _raise(
        tester,
        (context) => AppNotification.showWarning(
          context,
          title: 'Sudah Terdaftar',
          message: 'Anda sudah terdaftar pada bank sampah ini',
        ),
      );

      final flushbar = tester.widget<Flushbar>(find.byType(Flushbar));
      expect(flushbar.backgroundColor, const Color(0xFFFEF3C7));
      expect(flushbar.borderColor, const Color(0xFFD97706));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);

      await _settle(tester);
    });

    testWidgets('shows the title and message it was given', (tester) async {
      await _raise(
        tester,
        (context) => AppNotification.showWarning(
          context,
          title: 'Peringatan',
          message:
              'Transaksi disimpan, namun gagal mengirim WhatsApp otomatis.',
        ),
      );

      expect(find.text('Peringatan'), findsOneWidget);
      expect(
        find.text(
            'Transaksi disimpan, namun gagal mengirim WhatsApp otomatis.'),
        findsOneWidget,
      );

      await _settle(tester);
    });

    testWidgets('the three tones stay visually distinct', (tester) async {
      await _raise(
        tester,
        (context) => AppNotification.showSuccess(
          context,
          title: 'Berhasil',
          message: 'ok',
        ),
      );
      final success = tester.widget<Flushbar>(find.byType(Flushbar));
      await _settle(tester);

      await _raise(
        tester,
        (context) =>
            AppNotification.showError(context, title: 'Gagal', message: 'no'),
      );
      final error = tester.widget<Flushbar>(find.byType(Flushbar));
      await _settle(tester);

      await _raise(
        tester,
        (context) => AppNotification.showWarning(
          context,
          title: 'Peringatan',
          message: 'hm',
        ),
      );
      final warning = tester.widget<Flushbar>(find.byType(Flushbar));

      expect(
        {
          success.backgroundColor,
          error.backgroundColor,
          warning.backgroundColor
        }.length,
        3,
        reason: 'a tone that shares a fill with another conveys nothing',
      );

      await _settle(tester);
    });
  });

  group('AppNotification.showSuccess with an action', () {
    testWidgets('offers the action rather than taking it', (tester) async {
      var shared = 0;
      await _raise(
        tester,
        (context) => AppNotification.showSuccess(
          context,
          title: 'Berhasil',
          message: 'Laporan berhasil disimpan ke folder Download',
          actionLabel: 'Bagikan',
          onAction: () => shared++,
        ),
      );

      expect(find.text('Bagikan'), findsOneWidget);
      expect(
        shared,
        0,
        reason: 'the whole point of the refactor is that sharing waits to be '
            'asked for — firing it on display is the old behaviour',
      );

      await tester.tap(find.text('Bagikan'));
      await tester.pump();
      expect(shared, 1);

      // The toast takes itself down, so the share sheet does not open under it.
      await _pumpUntilGone(tester, find.text('Bagikan'));
      expect(find.text('Bagikan'), findsNothing);

      await _settle(tester);
    });

    testWidgets('a success with nothing to offer carries no button',
        (tester) async {
      await _raise(
        tester,
        (context) => AppNotification.showSuccess(
          context,
          title: 'Berhasil',
          message: 'Transaksi tersimpan',
        ),
      );

      expect(find.byType(TextButton), findsNothing);

      await _settle(tester);
    });
  });

  group('AppNotification.showLoading', () {
    testWidgets('stays up until the caller takes it down', (tester) async {
      late Flushbar loading;
      await _raise(
        tester,
        (context) => loading = AppNotification.showLoading(
          context,
          title: 'Informasi',
          message: 'Menyiapkan laporan XLS...',
        ),
      );

      expect(find.text('Menyiapkan laporan XLS...'), findsOneWidget);

      // Well past every other tone's auto-dismiss: an export that outlasts the
      // toast would otherwise leave the user watching a finished spinner, or a
      // vanished one while the work is still running.
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Menyiapkan laporan XLS...'), findsOneWidget);

      loading.dismiss();
      await _pumpUntilGone(tester, find.text('Menyiapkan laporan XLS...'));
      expect(find.text('Menyiapkan laporan XLS...'), findsNothing);
    });
  });
}
