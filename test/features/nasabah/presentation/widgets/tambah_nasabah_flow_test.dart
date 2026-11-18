import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/phone_prefix.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

import '../../../../support/fake_analytics_client.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/nasabah';

void main() {
  late StubApi api;
  late NasabahNotifier notifier;
  late FakeAnalyticsClient analytics;

  setUp(() {
    analytics = FakeAnalyticsClient();
    api = StubApi();
    notifier = buildNasabahNotifier(api);
    api.on('GET', _path, json: nasabahPage([]));
  });

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              builder: (_) => const TambahNasabahBottomSheet(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      wrap: (app) => withNasabahProvider(notifier, app, analytics: analytics),
      size: const Size(800, 2600),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester,
      {String kode = 'NAS-9',
      String email = 'siti@x.test',
      String phone = '81234567890'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Siti Aminah');
    await tester.enterText(fields.at(1), kode);
    await tester.ensureVisible(find.text('— Pilih —'));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perempuan').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), email);
    await tester.ensureVisible(fields.at(3));
    await tester.tap(fields.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(4), phone);
    await tester.enterText(fields.at(5), 'Jl. Melati Nomor 5');
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Simpan Nasabah'));
    await tester.tap(find.text('Simpan Nasabah'));
    await pumpToast(tester);
  }

  List<String> names() => analytics.events.map((e) => e.name).toList();

  testWidgets('opening the form, refusing it and saving it tell analytics',
      (tester) async {
    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await open(tester);
    expect(names(), ['nasabah_tambah_dimulai']);
    expect(analytics.events.single.properties['sumber'], 'halaman_nasabah');

    await save(tester);
    final refused = analytics.events[1];
    expect(refused.name, 'validasi_gagal');
    expect(refused.properties['tugas'], 'tambah_nasabah');
    // tanggal_lahir dropped out of this list with PIL-478: an empty birth
    // date is no longer a reason the form refuses to submit, so it can no
    // longer be a field the refusal names.
    expect(refused.properties['bidang'], [
      'nama',
      'jenis_kelamin',
      'email',
      'no_hp',
      'alamat',
    ]);
    expect(refused.properties['jumlah_masalah'], 5);

    await fill(tester);
    await save(tester);
    final saved = analytics.events.last;
    expect(saved.name, 'nasabah_ditambah');
    expect(saved.properties['percobaan_ke'], 2);
    expect(saved.properties['alur_id'],
        analytics.events.first.properties['alur_id']);
    expect(names(), hasLength(3));
    await settleToasts(tester);
  });

  testWidgets('a badly formed email is named, not hidden as "lainnya"',
      (tester) async {
    await open(tester);
    await fill(tester, email: 'bukan-email');

    await save(tester);

    final refused =
        analytics.events.singleWhere((e) => e.name == 'validasi_gagal');
    expect(refused.properties['bidang'], ['email']);
    expect(refused.properties['jumlah_masalah'], 1);
    await settleToasts(tester);
  });

  testWidgets('a badly formed phone number is named', (tester) async {
    await open(tester);
    await fill(tester, phone: '12345');

    await save(tester);

    final refused =
        analytics.events.singleWhere((e) => e.name == 'validasi_gagal');
    expect(refused.properties['bidang'], ['no_hp']);
    await settleToasts(tester);
  });

  testWidgets('an empty ID is valid and is not named as a refused field',
      (tester) async {
    await open(tester);
    await fill(tester, kode: '');

    await save(tester);

    final refused = analytics.events.where((e) => e.name == 'validasi_gagal');
    expect(refused, isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a save that lands after the sheet was closed is still counted',
      (tester) async {
    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await open(tester);
    await fill(tester);
    api.latency = const Duration(seconds: 1);
    await tester.ensureVisible(find.text('Simpan Nasabah'));
    await tester.tap(find.text('Simpan Nasabah'));
    await tester.pump();

    // The pengurus leaves the sheet while the request is still running.
    Navigator.of(tester.element(find.byType(TambahNasabahBottomSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TambahNasabahBottomSheet), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(names(), contains('nasabah_ditambah'));
    expect(names(), isNot(contains('nasabah_tambah_dibatalkan')));
  });

  testWidgets('a failed save is not reported as added', (tester) async {
    api.on('POST', _path, status: 500, json: {'error': 'boom'});
    await open(tester);

    await fill(tester);
    await save(tester);

    expect(names(), ['nasabah_tambah_dimulai']);
    await settleToasts(tester);
  });

  testWidgets('the phone field carries the shared +62 prefix', (tester) async {
    await open(tester);

    expect(find.byType(PhonePrefix), findsOneWidget);
  });

  testWidgets('a valid form creates the nasabah and confirms', (tester) async {
    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await open(tester);

    await fill(tester);
    await save(tester);

    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.json['kode'], 'NAS-9');
    expect(post.json['no_hp'], '+6281234567890');
    expect(post.json['jenis_kelamin'], 'perempuan');
    expect(find.text('Nasabah baru berhasil ditambahkan.'), findsOneWidget);
    expect(find.byType(TambahNasabahBottomSheet), findsNothing);
    await settleToasts(tester);
  });

  group('tanggal lahir is optional (PIL-478)', () {
    /// [fill] without the date picker step, which is the whole point.
    Future<void> fillWithoutDate(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Siti Aminah');
      await tester.enterText(fields.at(1), 'NAS-9');
      await tester.ensureVisible(find.text('— Pilih —'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perempuan').last);
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(2), 'siti@x.test');
      await tester.enterText(fields.at(4), '81234567890');
      await tester.enterText(fields.at(5), 'Jl. Melati Nomor 5');
    }

    testWidgets('a nasabah is created with tanggal_lahir sent as null',
        (tester) async {
      api.on('POST', _path, status: 201, json: nasabahRow('9'));
      await open(tester);

      await fillWithoutDate(tester);
      await save(tester);

      final post = api.requests.firstWhere((r) => r.method == 'POST');
      expect(post.json.containsKey('tanggal_lahir'), isTrue);
      expect(post.json['tanggal_lahir'], isNull);
      expect(find.text('Nasabah baru berhasil ditambahkan.'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('a missing date is never named as a refused field',
        (tester) async {
      await open(tester);

      // Nothing filled at all: the fields that are required still report
      // themselves, and tanggal_lahir is not among them any more.
      await save(tester);

      expect(names(), isNot(contains('nasabah_tambah_ditolak_tanggal_lahir')));
      final rejected = analytics.events
          .where((e) => e.name == 'nasabah_tambah_ditolak')
          .expand((e) => e.properties.values.map((v) => v.toString()))
          .join(' ');
      expect(rejected, isNot(contains('tanggal_lahir')));
      await settleToasts(tester);
    });
  });

  testWidgets('an empty form flags the required fields', (tester) async {
    await open(tester);

    await save(tester);

    expect(find.text('Bagian ini wajib diisi.'), findsWidgets);
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a duplicate code in the loaded list is caught before saving',
      (tester) async {
    api.on('GET', _path, json: nasabahPage([nasabahRow('2')]));
    await open(tester);
    final scopedNotifier = ProviderScope.containerOf(
      tester.element(find.byType(TambahNasabahBottomSheet)),
      listen: false,
    ).read(nasabahProvider.notifier);
    await tester.runAsync(scopedNotifier.loadNasabah);
    await tester.pumpAndSettle();

    await fill(tester, kode: 'nas-2');
    await save(tester);

    expect(find.text('ID Nasabah Sudah Digunakan'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await settleToasts(tester);

    // Editing the code clears the red border state.
    await tester.enterText(find.byType(TextFormField).at(1), 'NAS-3');
    await tester.pump();
  });

  testWidgets('a duplicate code reported by the server is shown as a toast',
      (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'kode': ['Kode sudah dipakai bank lain']
      },
    });
    await open(tester);

    await fill(tester);
    await save(tester);

    expect(find.text('Kode sudah dipakai bank lain'), findsOneWidget);
    expect(find.byType(TambahNasabahBottomSheet), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('an email error from the server is inline and clears on edit',
      (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'email': ['Email sudah terdaftar']
      },
    });
    await open(tester);
    await fill(tester);

    await save(tester);
    expect(find.text('Email sudah terdaftar'), findsOneWidget);

    api.on('POST', _path, status: 201, json: nasabahRow('9'));
    await tester.enterText(find.byType(TextFormField).at(2), 'lain@x.test');
    await tester.pump();
    await save(tester);
    expect(find.text('Nasabah baru berhasil ditambahkan.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a phone error from the server is inline', (tester) async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'no_hp': ['Nomor sudah dipakai']
      },
    });
    await open(tester);
    await fill(tester);

    await save(tester);

    expect(find.text('Nomor sudah dipakai'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('any other failure is reported as a toast', (tester) async {
    api.on('POST', _path, status: 500, json: {});
    await open(tester);
    await fill(tester);

    await save(tester);

    expect(find.text('Gagal Menyimpan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('the close button dismisses the form', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.byType(TambahNasabahBottomSheet), findsNothing);
  });
}
