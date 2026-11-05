import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';

import '../../../../support/fake_analytics_client.dart';
import '../../../../support/jadwal_provider_support.dart';

JadwalEntity _schedule({String status = 'draft'}) {
  final today = DateUtils.dateOnly(DateTime.now());
  return JadwalEntity(
    id: 'jadwal-1',
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: today.add(const Duration(hours: 9)),
    selesaiPada: today.add(const Duration(hours: 11)),
    lokasi: 'Balai Warga',
    status: status,
  );
}

Widget _app(JadwalNotifier notifier, FakeAnalyticsClient analytics) =>
    ProviderScope(
      overrides: [
        jadwalProvider.overrideWith(() => notifier),
        analyticsClientProvider.overrideWithValue(analytics),
      ],
      child: const MaterialApp(home: JadwalPage()),
    );

TestJadwalNotifier _notifier(
  JadwalState state, {
  Future<NetworkException?> Function(String id, String action)? onChangeStatus,
  Future<NetworkException?> Function(JadwalEntity)? onSave,
}) =>
    TestJadwalNotifier(
      repository: UnusedJadwalRepository(),
      initialState: state,
      onChangeStatus: onChangeStatus,
      onSaveJadwal: onSave,
    );

void main() {
  late FakeAnalyticsClient analytics;

  setUp(() => analytics = FakeAnalyticsClient());

  List<String> names() => analytics.events.map((e) => e.name).toList();

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
    final button = find.byType(ElevatedButton).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('opening the form for a new schedule starts a flow',
      (tester) async {
    await tester.pumpWidget(_app(_notifier(JadwalLoaded(const [])), analytics));
    await tester.pumpAndSettle();

    await openForm(tester);

    expect(names(), ['jadwal_form_dibuka']);
    expect(analytics.events.single.properties['mode'], 'baru');
  });

  testWidgets('saving a schedule reports it with its kind and audience',
      (tester) async {
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded(const []), onSave: (_) async => null),
      analytics,
    ));
    await tester.pumpAndSettle();
    await openForm(tester);

    await submit(tester);

    expect(names(), ['jadwal_form_dibuka', 'jadwal_dibuat']);
    final created = analytics.events.last.properties;
    expect(created['jenis'], 'penimbangan');
    expect(created['cakupan'], 'semua');
    expect(created['percobaan_ke'], 1);
    // The place and the notes the pengurus typed never leave the app.
    expect(
        created.values.whereType<String>(), isNot(contains(contains('Balai'))));
  });

  testWidgets('a schedule saved after the form was closed is still reported',
      (tester) async {
    final saving = Completer<NetworkException?>();
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded(const []), onSave: (_) => saving.future),
      analytics,
    ));
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
    final button = find.byType(ElevatedButton).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    // The pengurus leaves the form while the request is still running.
    Navigator.of(tester.element(find.byKey(const ValueKey('jadwal-form'))))
        .pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jadwal-form')), findsNothing);
    saving.complete(null);
    await tester.pumpAndSettle();

    expect(names(), contains('jadwal_dibuat'));
  });

  testWidgets('a schedule the server refuses is not reported as created',
      (tester) async {
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded(const []),
          onSave: (_) async => GeneralException(message: 'gagal')),
      analytics,
    ));
    await tester.pumpAndSettle();
    await openForm(tester);

    await submit(tester);

    expect(names(), isNot(contains('jadwal_dibuat')));
  });

  testWidgets('publishing a draft is reported, with the status it had',
      (tester) async {
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded([_schedule()]),
          onChangeStatus: (_, __) async => null),
      analytics,
    ));
    await tester.pump();

    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    final changed =
        analytics.events.singleWhere((e) => e.name == 'jadwal_status_diubah');
    expect(changed.properties,
        {'aksi': 'terbitkan', 'status_sebelumnya': 'draft'});
  });

  testWidgets('a status change the server refuses is not reported',
      (tester) async {
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded([_schedule()]),
          onChangeStatus: (_, __) async => GeneralException(message: 'gagal')),
      analytics,
    ));
    await tester.pump();

    await tester.tap(find.text('Terbitkan'));
    await tester.pumpAndSettle();

    expect(names(), isNot(contains('jadwal_status_diubah')));
  });

  testWidgets('cancelling asks first, and only a confirmed one is reported',
      (tester) async {
    await tester.pumpWidget(_app(
      _notifier(JadwalLoaded([_schedule()]),
          onChangeStatus: (_, __) async => null),
      analytics,
    ));
    await tester.pump();

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(names(), isNot(contains('jadwal_status_diubah')));

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();

    final changed =
        analytics.events.singleWhere((e) => e.name == 'jadwal_status_diubah');
    expect(changed.properties['aksi'], 'batalkan');
  });
}
