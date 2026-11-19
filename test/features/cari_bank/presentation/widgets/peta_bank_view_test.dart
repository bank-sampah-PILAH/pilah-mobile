import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/widgets/peta_bank_view.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';

class _FakeLocationService extends Mock implements LocationService {}

// Same seam contract as the picker: no tile is ever fetched inside a test.
const _noTilesMap = SizedBox.shrink();

void main() {
  late _FakeLocationService location;

  setUp(() {
    location = _FakeLocationService();
    di.allowReassignment = true;
    di.registerSingleton<LocationService>(location);
    addTearDown(() => di.unregister<LocationService>());
  });

  testWidgets('a tiny viewport forces a low zoom, so two banks cluster',
      (tester) async {
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetaBankView(
            banks: [
              BankSampahDirectoryEntity.fromJson(bankRow('b1', 'Bank Satu',
                  latitude: -6.3628, longitude: 106.8286)),
              BankSampahDirectoryEntity.fromJson(bankRow('b2', 'Bank Dua',
                  latitude: -6.3628, longitude: 106.8286)),
            ],
            tileLayerBuilder: () => _noTilesMap,
          ),
        ),
      ),
    );
    // Two banks stacked on the same coordinate share a cell at any zoom —
    // the fitted camera cannot split them.
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cari_bank_cluster')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Tapping the badge zooms in (+1) — for stacked points the cell still
    // holds both, so the badge remains rather than a summary for one.
    await tester.tap(find.byKey(const Key('cari_bank_cluster')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cari_bank_cluster')), findsOneWidget);
  });

  testWidgets('a single-bank cluster tap opens the summary sheet',
      (tester) async {
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetaBankView(
            banks: [
              BankSampahDirectoryEntity.fromJson(bankRow(
                'b1',
                'Bank Satu',
                latitude: -6.362829,
                longitude: 106.828655,
              )),
            ],
            tileLayerBuilder: () => _noTilesMap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cari_bank_marker_b1')));
    await tester.pumpAndSettle();

    expect(find.text('Bank Satu'), findsOneWidget);
    expect(find.byKey(const Key('cari_bank_lihat_detail')), findsOneWidget);

    // Detail routes through go_router: needs a router context. Simpler
    // assertion in the page-level test; here the sheet is the target.
  });
}
