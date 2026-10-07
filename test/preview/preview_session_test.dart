import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/preview/preview_authentication.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';

void main() {
  group('PreviewAuthenticationSession', () {
    test('every sign-in path yields the offline nasabah and starts a session',
        () async {
      final session = PreviewAuthenticationSession();

      final login = await session.postLogin('u', 'p');
      expect(
          login.getOrElse(() => throw 'no'), PreviewAuthenticationSession.auth);
      final google = await session.loginWithGoogle('token');
      expect(google.getOrElse(() => throw 'no'), isA<GoogleSession>());
      final registered = await session.registerGoogleUser(
          registrationToken: 't', role: GoogleRegistrationRole.nasabah);
      expect(registered.isRight(), isTrue);
      expect((await session.saveToken('a', 'r')).isRight(), isTrue);
      expect(await session.hasSession(), isTrue);

      await session.logout();
      expect(await session.hasSession(), isFalse);
      await session.postLogin('u', 'p');
      expect(await session.hasSession(), isTrue);
    });
  });

  group('PreviewNasabahRepository', () {
    test('serves a fixed home with the configured identity', () async {
      final repo = PreviewNasabahRepository(name: 'Budi');
      final home = await repo.home();
      expect(home.identity.name, 'Budi');
      expect(home.membershipId, 'preview-membership');
      expect((await repo.home(membershipId: 'm1')).membershipId, 'm1');
    });

    test('updateProfile overlays the given fields on the current profile',
        () async {
      final repo = PreviewNasabahRepository();
      final updated = await repo.updateProfile(
          nama: 'Baru',
          noHp: '0812',
          jenisKelamin: 'L',
          tanggalLahir: DateTime(2000, 1, 2),
          alamat: 'Jl. X');
      expect(updated.name, 'Baru');
      expect(updated.noHp, '0812');
      expect(updated.alamat, 'Jl. X');
      final untouched = await repo.updateProfile();
      expect(untouched.name, 'Siti Aminah');
    });

    test('is offline: no network and no setoran detail', () {
      final repo = PreviewNasabahRepository();
      expect(() => repo.network, throwsUnsupportedError);
    });
  });
}
