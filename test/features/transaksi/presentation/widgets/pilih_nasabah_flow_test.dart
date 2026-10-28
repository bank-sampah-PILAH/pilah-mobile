import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';

import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

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
  Future<List<NasabahEntity>> loadActiveNasabah() async =>
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

  testWidgets('the list can be searched, and picking reports the nasabah',
      (tester) async {
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([
          nasabahRow('1', nama: 'Budi Santoso'),
          nasabahRow('2', nama: 'Siti Aminah', saldo: '1500'),
        ]));
    await open(tester);
    await openPicker(tester);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('NAS-2 · 08122'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'siti');
    await tester.pump();
    expect(find.text('Budi Santoso'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Nasabah tidak ditemukan.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'siti');
    await tester.pump();
    await tester.tap(find.text('Siti Aminah'));
    await tester.pumpAndSettle();

    expect(chosen?.id, '2');
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
