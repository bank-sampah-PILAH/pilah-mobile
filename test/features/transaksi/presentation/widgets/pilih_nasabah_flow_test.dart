import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

Finder _pickerText(String text) => find.descendant(
      of: find.byType(ListView).last,
      matching: find.text(text),
    );

class _BrokenNasabahNotifier extends NasabahNotifier {
  _BrokenNasabahNotifier(NasabahNotifier delegate)
      : super(
          delegate.getNasabahUseCase,
          delegate.getActiveNasabahUseCase,
          delegate.getNasabahRingkasanUseCase,
          delegate.addNasabahUseCase,
          delegate.updateNasabahUseCase,
          delegate.activateNasabahUseCase,
          delegate.deactivateNasabahUseCase,
          delegate.approveNasabahUseCase,
          delegate.rejectNasabahUseCase,
          delegate.sinkronProfilNasabahUseCase,
        );

  @override
  NasabahState build() => NasabahInitial();

  @override
  Future<HalamanNasabah> loadActiveNasabahPage({
    int page = 1,
    String? search,
  }) async =>
      throw StateError('rusak');
}

void main() {
  late StubApi api;
  late NasabahNotifier notifier;
  NasabahEntity? chosen;

  setUp(() {
    api = StubApi();
    notifier = buildNasabahNotifier(api);
    chosen = null;
  });

  Future<void> open(WidgetTester tester,
      {NasabahEntity? selected,
      bool hasError = true,
      NasabahNotifier? withNotifier}) async {
    await pumpRouted(
      tester,
      Scaffold(
        body: PilihNasabahSection(
          selectedCustomer: selected,
          onCustomerSelected: (n) => chosen = n,
          hasError: hasError,
          errorText: 'Nasabah harus dipilih',
        ),
      ),
      wrap: (app) => withNasabahProvider(withNotifier ?? notifier, app),
      size: const Size(800, 1800),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Tap untuk pilih nasabah'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the validation message under the empty picker',
      (tester) async {
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
    await open(tester);

    expect(find.text('Nasabah harus dipilih'), findsOneWidget);
  });

  testWidgets(
    'server search finds first, middle and last nasabah and preserves selection',
    (tester) async {
      final rows = List.generate(1000, (index) {
        final number = (index + 1).toString().padLeft(4, '0');
        return nasabahRow(
          number,
          nama: 'Load Nasabah $number',
          active: index != 1,
          status: index == 2 ? 'pending' : 'approved',
        );
      });
      api.onRequest(
        'GET',
        '/api/v1/nasabah',
        json: (options) {
          final query = options.uri.queryParameters;
          final search = query['search']?.toLowerCase();
          final matches = rows.where((row) {
            return search == null ||
                (row['nama'] as String).toLowerCase().contains(search);
          }).toList();
          final page = int.parse(query['page'] ?? '1');
          final pageSize = int.parse(query['page_size'] ?? '50');
          final start = (page - 1) * pageSize;
          final results = matches.skip(start).take(pageSize).toList();
          return nasabahPage(
            results,
            count: matches.length,
            hasNext: start + results.length < matches.length,
          );
        },
      );
      await open(tester);
      await openPicker(tester);
      expect(_pickerText('Load Nasabah 0001'), findsOneWidget);
      expect(_pickerText('Load Nasabah 0002'), findsNothing);
      expect(_pickerText('Load Nasabah 0003'), findsNothing);
      expect(find.text('Load Nasabah 0500'), findsNothing);
      expect(api.last.query['page_size'], '50');

      await tester.enterText(find.byType(TextField), 'L');
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Ketik minimal 2 karakter untuk mencari.'),
        findsOneWidget,
      );
      expect(api.requests, hasLength(1));

      await tester.enterText(find.byType(TextField), 'Load Nasabah 0001');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(_pickerText('Load Nasabah 0001'), findsOneWidget);
      expect(api.last.query['search'], 'Load Nasabah 0001');

      await tester.enterText(find.byType(TextField), 'Load Nasabah 05');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(find.byType(TextField), 'Load Nasabah 0500');
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        api.requests,
        hasLength(2),
        reason: 'typing restarts the debounce instead of fetching each key',
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(_pickerText('Load Nasabah 0500'), findsOneWidget);
      expect(api.last.query['search'], 'Load Nasabah 0500');

      await tester.enterText(find.byType(TextField), 'Load Nasabah 1000');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(_pickerText('Load Nasabah 1000'), findsOneWidget);
      expect(api.last.query['search'], 'Load Nasabah 1000');
      expect(find.text('Rp 25.000'), findsOneWidget);

      await tester.tap(_pickerText('Load Nasabah 1000'));
      await tester.pumpAndSettle();
      expect(chosen?.id, '1000');
      expect(chosen?.idNasabah, 'NAS-1000');
      expect(chosen?.balance, 'Rp 25.000');
    },
  );

  testWidgets('scrolling loads the next server page', (tester) async {
    final rows = List.generate(100, (index) {
      final number = (index + 1).toString().padLeft(4, '0');
      return nasabahRow(number, nama: 'Load Nasabah $number');
    });
    api.onRequest(
      'GET',
      '/api/v1/nasabah',
      json: (options) {
        final query = options.uri.queryParameters;
        final page = int.parse(query['page'] ?? '1');
        final pageSize = int.parse(query['page_size'] ?? '50');
        final start = (page - 1) * pageSize;
        final results = rows.skip(start).take(pageSize).toList();
        return nasabahPage(
          results,
          count: rows.length,
          hasNext: start + results.length < rows.length,
        );
      },
    );
    await open(tester);
    await openPicker(tester);

    await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(2));
    expect(api.last.query['page'], '2');
    expect(find.text('Load Nasabah 0051'), findsOneWidget);
  });

  testWidgets('an empty list says there are no active nasabah', (tester) async {
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
    await open(tester);
    await openPicker(tester);

    expect(find.text('Belum ada nasabah aktif.'), findsOneWidget);
  });

  testWidgets('a failed fetch shows the backend message', (tester) async {
    api.on('GET', '/api/v1/nasabah',
        status: 403, json: {'error': 'Tidak diizinkan'});
    await open(tester);
    await openPicker(tester);

    expect(find.text('Tidak diizinkan'), findsOneWidget);
  });

  testWidgets('a nasabah without a code shows the phone alone', (tester) async {
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([
          {...nasabahRow('1'), 'kode': ' '},
        ]));
    await open(tester);
    await openPicker(tester);

    expect(find.text('08121'), findsOneWidget);
  });

  testWidgets('an unexpected error is shown as plain text', (tester) async {
    final broken = _BrokenNasabahNotifier(notifier);
    await open(tester, withNotifier: broken);
    await openPicker(tester);

    expect(find.textContaining('rusak'), findsOneWidget);
  });

  testWidgets('without an error the empty picker has a neutral border',
      (tester) async {
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
    await open(tester, hasError: false);

    expect(find.text('Nasabah harus dipilih'), findsNothing);
    expect(find.text('Tap untuk pilih nasabah'), findsOneWidget);
  });

  testWidgets('a selected customer is shown with their code', (tester) async {
    api.on('GET', '/api/v1/nasabah', json: nasabahPage([]));
    final selected = NasabahEntity(
      id: '1',
      idNasabah: 'NAS-1',
      name: 'Budi Santoso',
      phone: '0812',
      balance: 'Rp 0',
      isActive: true,
      address: '-',
      initials: 'BS',
      avatarColor: Colors.green,
      textColor: Colors.white,
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '',
    );
    await open(tester, selected: selected);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('NAS-1'), findsOneWidget);
  });
}
