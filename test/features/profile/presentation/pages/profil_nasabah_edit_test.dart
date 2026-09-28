import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

/// Records updateProfile calls and echoes them back like a real PATCH would.
class _Repository extends PreviewNasabahRepository {
  _Repository(this._identity);
  NasabahIdentity _identity;
  final updateCalls = <Map<String, dynamic>>[];
  Object? failNextUpdateWith;

  @override
  Future<NasabahIdentity> profile() async => _identity;

  @override
  Future<NasabahIdentity> updateProfile({
    String? nama,
    String? noHp,
    String? jenisKelamin,
    DateTime? tanggalLahir,
    String? alamat,
  }) async {
    updateCalls.add({
      if (nama != null) 'nama': nama,
      if (noHp != null) 'no_hp': noHp,
      if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
      if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
      if (alamat != null) 'alamat': alamat,
    });
    final failure = failNextUpdateWith;
    if (failure != null) {
      failNextUpdateWith = null;
      throw failure;
    }
    _identity = NasabahIdentity(
      _identity.id,
      nama ?? _identity.name,
      _identity.email,
      _identity.role,
      noHp: noHp ?? _identity.noHp,
      jenisKelamin: jenisKelamin ?? _identity.jenisKelamin,
      tanggalLahir: tanggalLahir ?? _identity.tanggalLahir,
      alamat: alamat ?? _identity.alamat,
    );
    return _identity;
  }
}

void main() {
  late _Auth auth;
  late _Repository repository;

  Future<void> open(WidgetTester tester, {NasabahIdentity? identity}) async {
    auth = _Auth();
    repository = _Repository(identity ??
        const NasabahIdentity('u', 'Siti Aminah', 'siti@example.test',
            'nasabah',
            noHp: '081234567890',
            jenisKelamin: 'perempuan',
            alamat: 'Jl. Melati No. 1'));
    di.registerSingleton<NasabahRepository>(repository);
    whenListen(auth, const Stream<AuthenticationStates>.empty(),
        initialState: Authenticated(
            authEntity: AuthEntity(
          id: 'u',
          name: 'Siti Aminah',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'tok',
          role: 'nasabah',
          nextStep: 'dashboard',
        )));
    addTearDown(() async {
      await auth.close();
      await di.unregister<NasabahRepository>();
    });
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
        value: auth, child: const MaterialApp(home: ProfilNasabahPage())));
    await tester.pumpAndSettle();
  }

  testWidgets('profil menampilkan semua bidang profil dari respons server',
      (tester) async {
    await open(tester,
        identity: NasabahIdentity('u', 'Siti Aminah', 'siti@example.test',
            'nasabah',
            noHp: '081234567890',
            jenisKelamin: 'perempuan',
            tanggalLahir: DateTime(1998, 5, 17),
            alamat: 'Jl. Melati No. 1'));
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Perempuan'), findsOneWidget);
    expect(find.text('17/05/1998'), findsOneWidget);
    expect(find.text('Jl. Melati No. 1'), findsOneWidget);
  });

  testWidgets(
      'menyunting nomor HP dan menyimpan mengirim body parsial yang benar',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();

    final noHpField = find.widgetWithText(TextField, '081234567890');
    expect(noHpField, findsOneWidget);
    await tester.enterText(noHpField, '089900001111');
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls.single, {'no_hp': '089900001111'});
  });

  testWidgets('memilih Laki-laki pada kontrol jenis kelamin dan menyimpan',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Laki-laki'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laki-laki'));
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls.single, {'jenis_kelamin': 'laki-laki'});
  });

  testWidgets('penyimpanan yang berhasil menampilkan nilai baru',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();

    final noHpField = find.widgetWithText(TextField, '081234567890');
    await tester.enterText(noHpField, '089900001111');
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('089900001111'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsNothing);
  });

  testWidgets(
      'kesalahan validasi saat menyimpan ditampilkan tanpa membuat halaman crash',
      (tester) async {
    await open(tester);
    repository.failNextUpdateWith =
        const NasabahApiException('Nomor HP tidak valid.');
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();

    final noHpField = find.widgetWithText(TextField, '081234567890');
    await tester.enterText(noHpField, 'bukan-nomor');
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nomor HP tidak valid.'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });
}
