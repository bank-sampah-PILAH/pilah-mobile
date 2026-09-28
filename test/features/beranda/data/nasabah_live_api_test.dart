import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

class _Environment extends Mock implements AppEnvironment {}

class _Tokens extends Mock implements NetworkUtils {}

// Opt-in only: a disposable Django server supplies the fixture path.
void main() {
  const fixturePath = String.fromEnvironment('PILAH_SMOKE_FIXTURE');
  const profileOnly = bool.fromEnvironment('PILAH_SMOKE_PROFILE');
  test('authenticated repository interoperates with live Django', () async {
    final fixture = jsonDecode(await File(fixturePath).readAsString())
        as Map<String, dynamic>;
    final environment = _Environment();
    final tokens = _Tokens();
    when(() => environment.baseUrl).thenReturn(fixture['baseUrl'] as String);
    when(() => tokens.accessToken).thenReturn(fixture['token'] as String);
    final network =
        NetworkService(environment: environment, networkUtils: tokens);
    // Avoid logging even disposable JWTs in test output.
    network.dio.interceptors.clear();
    addTearDown(() => network.dio.close(force: true));
    final repository = NasabahRepository(network);
    if (profileOnly) {
      final identity = await repository.profile();
      expect(identity.name, 'API Smoke Nasabah');
      expect(identity.email, 'smoke@example.test');
    } else {
      final home = await repository.home();
      expect(home.identity.name, 'API Smoke Nasabah');
      expect(home.balance.amount, '12500.50');
      expect(home.activities.length, 5);
      expect((await repository.bank(home.membershipId)).name, 'Smoke Melati');
      expect((await repository.balance(home.membershipId)).amount, '12500.50');
      final first = await repository.history(home.membershipId);
      final second = await repository.history(home.membershipId, page: 2);
      expect(first.activities.length, 20);
      expect(first.hasNext, isTrue);
      expect(second.activities.length, 1);
      expect(second.hasNext, isFalse);
    }
    when(() => tokens.accessToken).thenReturn('');
    await expectLater(
        profileOnly ? repository.profile() : repository.home(),
        throwsA(isA<NasabahApiException>().having(
            (e) => e.message, 'unauthorized', contains('Sesi berakhir'))));
  }, skip: fixturePath.isEmpty ? 'Requires disposable Django fixture' : false);
}
