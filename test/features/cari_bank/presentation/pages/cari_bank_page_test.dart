import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/cari_bank_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

class _FakeLocationService extends Mock implements LocationService {}

void main() {
  late StubApi api;
  late CariBankCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildCariBankCubit(api);
    // The page resolves its cubit through the DI container itself.
    di.allowReassignment = true;
    di.registerSingleton<CariBankCubit>(cubit);
    // PetaBankView asks for the user location as its camera start (PIL-330);
    // page tests don't care about it, so a silent null is fine.
    final location = _FakeLocationService();
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    di.registerSingleton<LocationService>(location);
    addTearDown(() => di.unregister<CariBankCubit>());
    addTearDown(() => di.unregister<LocationService>());
  });

  Future<void> pump(WidgetTester tester) => pumpRouted(
        tester,
        CariBankPage(
          // A tile layer that draws nothing: no network tile is ever fetched
          // inside `flutter test`.
          tileLayerBuilder: () => const SizedBox.shrink(),
        ),
        extraRoutes: ['/cari-bank-sampah/detail'],
        size: const Size(600, 1200),
      );

  Future<void> keModePeta(WidgetTester tester) async {
    await tester.tap(find.text('Peta'));
    await tester.pump();
  }

  testWidgets('shows the loaded rows', (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis'),
          bankRow('b2', 'Bank Mawar', kota: 'Bogor'),
        ]));

    await pump(tester);

    // The stub answers within a microtask, so the very first frame can already
    // be past loading; pumpAndSettle guards both timings, then we assert rows.
    await tester.pumpAndSettle();
    expect(find.text('Bank Garis'), findsOneWidget);
    expect(find.text('Depok · Jl. Bank Garis'), findsOneWidget);
    expect(find.text('Bogor · Jl. Bank Mawar'), findsOneWidget);
  });

  testWidgets('an empty result shows the not-found note', (tester) async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bank Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('a failing load shows the message with a retry', (tester) async {
    api.on('GET', _directory, status: 500, json: {});

    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Bank Sampah'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    // Retry hits a healthy backend and shows the list.
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Bank Garis'), findsOneWidget);
  });

  testWidgets('tapping a row routes to the detail page with the bank id',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b9', 'Bank Garis')]));

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bank Garis'));
    await tester.pumpAndSettle();
    expect(find.text('route:/cari-bank-sampah/detail'), findsOneWidget);
  });

  testWidgets('peta mode renders markers only for banks with coordinates',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis',
              latitude: -6.362829, longitude: 106.828655),
          bankRow('b2', 'Bank Tanpa Titik'),
        ]));

    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bank Garis'), findsOneWidget); // daftar dulu

    await keModePeta(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cari_bank_marker_b1')), findsOneWidget);
    expect(find.byKey(const Key('cari_bank_marker_b2')), findsNothing);
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('peta mode with location fix draws the user dot', (tester) async {
    // The page open's own location call already consumed the first stub;
    // PetaBankView asks again on mount — the second answer is the fix that
    // the user dot draws from.
    // The fix sits on the fitted camera (the single bank's own point): the
    // dot is inside the viewport when the layer builds.
    final location = di<LocationService>() as _FakeLocationService;
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -6.362829, longitude: 106.828655));
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis',
              latitude: -6.362829, longitude: 106.828655),
        ]));

    await pump(tester);
    await tester.pumpAndSettle();
    await keModePeta(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cari_bank_titik_saya')), findsOneWidget);
  });

  testWidgets('tapping a marker opens the summary and routes to detail',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis',
              latitude: -6.362829, longitude: 106.828655),
        ]));

    await pump(tester);
    await tester.pumpAndSettle();
    await keModePeta(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cari_bank_marker_b1')));
    await tester.pumpAndSettle();
    expect(find.text('Depok · Jl. Bank Garis'), findsOneWidget);
    expect(find.text('-6.362829, 106.828655'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cari_bank_lihat_detail')));
    await tester.pumpAndSettle();
    expect(find.text('route:/cari-bank-sampah/detail'), findsOneWidget);
  });

  testWidgets('peta mode without any coordinate shows the map-less note',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Tanpa Titik')]));

    await pump(tester);
    await tester.pumpAndSettle();
    await keModePeta(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tidak Ada Bank Dengan Lokasi'), findsOneWidget);
  });

  testWidgets('location buttons show, radius chips after entering mode',
      (tester) async {
    api.on('GET', _directory, json: bankSampahPage([bankRow('b1', 'Bank A')]));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cari_bank_pilih_di_peta')), findsOneWidget);
    expect(find.byKey(const Key('cari_bank_dekat_saya')), findsNothing);

    // Enter location mode from the cubit side (the map-picker flow itself is
    // covered by the 326 picker tests); the page then swaps the buttons for
    // the radius chips and reloads with the trio.
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank A',
              latitude: -6.362829, longitude: 106.828655, jarakKm: '0.85'),
        ]));
    cubit.pilihDariPeta((latitude: -6.362829, longitude: 106.828655));
    // Debounce (300 ms) then load: pumpAndSettle alone can stop before the
    // debounced reload chain fully lands.
    await tester.pump(CariBankCubit.jedaPencarian);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cari_bank_radius_1')), findsNothing);
    expect(find.byKey(const Key('cari_bank_radius_5')), findsNothing);
    expect(find.byKey(const Key('cari_bank_hapus_lokasi')), findsNothing);
    expect(find.byKey(const Key('cari_bank_dekat_saya')), findsNothing);

    // The reload carried the trio.
    expect(api.last.query['latitude'], isNotNull);
    expect(api.last.query['radius_km'], '5.0');
  });

  testWidgets('distance chip renders meters under a kilometer, km over',
      (tester) async {
    api.on(
      'GET',
      _directory,
      json: bankSampahPage([
        bankRow('b1', 'Bank Dekat',
            latitude: -6.362829, longitude: 106.828655, jarakKm: '0.85'),
        bankRow('b2', 'Bank Jauh',
            latitude: -6.4, longitude: 106.9, jarakKm: '5.02'),
      ]),
    );
    cubit.pilihDariPeta((latitude: -6.362829, longitude: 106.828655));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('850 m'), findsOneWidget);
    expect(find.text('5.0 km'), findsOneWidget);
  });

  testWidgets('pilihDariPeta now awaits, but the trio still lands on reload',
      (tester) async {
    api.on('GET', _directory, json: bankSampahPage([bankRow('b1', 'Bank A')]));

    await pump(tester);
    await tester.pumpAndSettle();

    await cubit.pilihDariPeta((latitude: -6.362829, longitude: 106.828655));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.last.query['radius_km'], '5.0');
  });

  testWidgets('scrolling near the end of a long list fetches the next page',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage(
          [
            for (final i in List<int>.generate(12, (n) => n + 1))
              bankRow('b$i', 'Bank $i')
          ],
          count: 20,
          hasNext: true,
        ));

    await pump(tester);
    await tester.pumpAndSettle();

    api.on('GET', _directory,
        json: bankSampahPage(
          [bankRow('b20', 'Bank 20')],
          count: 20,
        ));
    await tester.drag(find.byType(ListView).last, const Offset(0, -800));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(api.requests.last.query['page'], '2');
  });

  testWidgets('a cancelled map pick leaves the origin untouched',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));

    await pump(tester);
    await tester.pumpAndSettle();
    final permintaanSebelum = api.requests.length;

    await tester.tap(find.byKey(const Key('cari_bank_pilih_di_peta')));
    await tester.pumpAndSettle();
    expect(find.byType(MapPickerPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(MapPickerPage), findsNothing);
    expect(api.requests.length, permintaanSebelum);
  });

  testWidgets('a saved pick re-searches with sort=distance and the trio',
      (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')]));

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cari_bank_pilih_di_peta')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('latitude_field')), '-6.36');
    await tester.enterText(find.byKey(const Key('longitude_field')), '106.82');
    await tester.tap(find.byKey(const Key('simpan_lokasi')));
    await tester.pumpAndSettle();

    final terakhir = api.requests.last.query;
    expect(terakhir['latitude'], '-6.36');
    expect(terakhir['longitude'], '106.82');
    expect(terakhir['radius_km'], '5.0');
    expect(terakhir['sort'], 'distance');
  });

  testWidgets('the Daftar pill returns from Peta to the list', (tester) async {
    api.on('GET', _directory,
        json: bankSampahPage([
          bankRow('b1', 'Bank Garis',
              latitude: -6.362829, longitude: 106.828655),
        ]));

    await pump(tester);
    await tester.pumpAndSettle();
    await keModePeta(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cari_bank_marker_b1')), findsOneWidget);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    // The rows are back on the plain scroll view.
    expect(find.text('Depok · Jl. Bank Garis'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });
}
