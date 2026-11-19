import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/widgets/bank_marker_cluster.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

import '../../../../support/cari_bank_support.dart';

void main() {
  List<BankSampahDirectoryEntity> banks(List<Map<String, dynamic>> rows) =>
      rows.map(BankSampahDirectoryEntity.fromJson).toList();

  test('separate banks far apart share no cluster even at low zoom', () {
    final kelompok = kelompokkanBank(
      banks([
        bankRow('b1', 'Depok', latitude: -6.36, longitude: 106.82),
        bankRow('b2', 'Medan', latitude: 3.58, longitude: 98.67),
      ]),
      5,
    );
    expect(kelompok, hasLength(2));
    expect(
      kelompok.map((k) => k.banks.single.id),
      unorderedEquals(['b1', 'b2']),
    );
  });

  test('nearby banks cluster at a low zoom, split at a high one', () {
    final rows = [
      bankRow('b1', 'Depok 1', latitude: -6.3620, longitude: 106.8210),
      bankRow('b2', 'Depok 2', latitude: -6.3635, longitude: 106.8230),
    ];
    // Zoom 6: a cell spans 2/64 ≈ 0.03°, both banks fall in it.
    final low = kelompokkanBank(banks(rows), 6);
    expect(low, hasLength(1));
    // The marker sits on the centroid.
    expect(low.single.center.latitude, closeTo(-6.36275, 1e-4));
    // Zoom 11: a cell is 2/2048 ≈ 0.001°, and the pair is wider apart.
    final high = kelompokkanBank(banks(rows), 11);
    expect(high, hasLength(2));
  });

  test('banks without coordinates never appear', () {
    final kelompok = kelompokkanBank(
      banks([
        bankRow('b1', 'Tanpa Koordinat'),
        bankRow('b2', 'Depok', latitude: -6.36, longitude: 106.82),
      ]),
      5,
    );
    expect(kelompok, hasLength(1));
    expect(kelompok.single.banks.single.id, 'b2');
  });

  test('empty or coordinate-less input clusters to nothing', () {
    expect(kelompokkanBank(const [], 5), isEmpty);
    expect(
      kelompokkanBank(banks([bankRow('b1', 'Tanpa Koordinat')]), 5),
      isEmpty,
    );
  });
}
