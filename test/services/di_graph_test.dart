import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import 'di_registrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lists every registration in the generated graph', () {
    // CI regenerates di.config.dart; a registration missing from the list
    // below would go unresolved here and uncovered on SonarCloud.
    final generated = File('lib/services/di.config.dart').readAsStringSync();
    final count = RegExp(r'gh\.(factory|lazySingleton|singleton)<')
        .allMatches(generated)
        .length;

    expect(diRegistrations.length, count);
  });

  for (final env in [AppKey.devEnv, AppKey.prodEnv]) {
    group('the generated graph for $env', () {
      setUp(() => configureDependencies(environment: env));
      tearDown(() => di.reset());

      test('builds every registration', () {
        for (final (label, onlyIn, resolve) in diRegistrations) {
          if (onlyIn != null && onlyIn != env) continue;
          expect(resolve, returnsNormally, reason: label);
        }
      });

      test('registers the beranda announcement repository', () {
        expect(
          di<NasabahPengumumanRepository>(),
          isA<NasabahPengumumanRepository>(),
        );
      });
    });
  }
}
