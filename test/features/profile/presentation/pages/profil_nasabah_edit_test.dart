import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';

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
  late TestAuthenticationNotifier auth;
  late _Repository repository;

  Future<void> open(WidgetTester tester, {NasabahIdentity? identity}) async {
    auth = authNotifierIn(Authenticated(
        authEntity: AuthEntity(
      id: 'u',
      name: 'Siti Aminah',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'tok',
      role: 'nasabah',
      nextStep: 'dashboard',
    )));
    repository = _Repository(identity ??
        const NasabahIdentity(
            'u', 'Siti Aminah', 'siti@example.test', 'nasabah',
            noHp: '081234567890',
            jenisKelamin: 'perempuan',
            alamat: 'Jl. Melati No. 1'));
    di.registerSingleton<NasabahRepository>(repository);
    addTearDown(() async {
      await di.unregister<NasabahRepository>();
    });
    await tester.pumpWidget(withAuthenticationProvider(
        auth, const MaterialApp(home: ProfilNasabahPage())));
    await tester.pumpAndSettle();
  }

  testWidgets('profil menampilkan semua bidang profil dari respons server',
      (tester) async {
    await open(tester,
        identity: NasabahIdentity(
            'u', 'Siti Aminah', 'siti@example.test', 'nasabah',
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

  testWidgets('the gender options announce which one is selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await open(
      tester,
      identity: NasabahIdentity(
          'u', 'Siti Aminah', 'siti@example.test', 'nasabah',
          noHp: '081234567890', jenisKelamin: 'perempuan'),
    );
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Laki-laki'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Perempuan')),
      isSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Laki-laki')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
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

  testWidgets('batal membuang perubahan dan kembali ke tampilan profil',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, '081234567890'), '0899');

    await tester.ensureVisible(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan Perubahan'), findsNothing);
    expect(find.text('081234567890'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
  });

  testWidgets('memilih tanggal lahir lalu menyimpan mengirimnya',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih tanggal lahir'), findsOneWidget);

    await tester.ensureVisible(find.text('Pilih tanggal lahir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih tanggal lahir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih tanggal lahir'), findsNothing);
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls.single.keys, ['tanggal_lahir']);
  });

  testWidgets('membatalkan pemilih tanggal tidak mengubah apa pun',
      (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pilih tanggal lahir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih tanggal lahir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih tanggal lahir'), findsOneWidget);
  });

  testWidgets('galat tak terduga menampilkan pesan umum', (tester) async {
    await open(tester);
    repository.failNextUpdateWith = StateError('putus');
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, '081234567890'), '0899');

    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(
        find.text('Perubahan gagal disimpan. Periksa koneksi dan coba lagi.'),
        findsOneWidget);
  });

  testWidgets('tanggal lahir yang tidak diubah tidak ikut dikirim',
      (tester) async {
    await open(tester,
        identity: NasabahIdentity(
            'u', 'Siti Aminah', 'siti@example.test', 'nasabah',
            noHp: '081234567890',
            jenisKelamin: 'perempuan',
            tanggalLahir: DateTime(1998, 5, 17),
            alamat: 'Jl. Melati No. 1'));
    await tester.tap(find.byTooltip('Ubah profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, '081234567890'), '0899');

    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls.single, {'no_hp': '0899'});
  });
}
