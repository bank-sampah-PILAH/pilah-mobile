import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';

class MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

/// Urutan field pada form, dipakai untuk membaca status aktifnya.
const _nama = 0;
const _nomorAnggota = 1;
const _email = 2;
const _tanggalLahir = 3;
const _whatsapp = 4;
const _alamat = 5;

const _pesan403 = 'Nasabah dengan akun hanya bisa diubah pada data keanggotaan';
const _pesan403NonAktif = 'Nasabah nonaktif tidak bisa diedit';

/// Respons yang dikirim backend ketika profil nasabah berakun diubah
/// (PIL-223): 403 dengan satu pesan pada kunci `error`.
NetworkException _tolak403() => NetworkException.handleBadResponse(
      Response(
        requestOptions: RequestOptions(path: '/api/v1/nasabah/nasabah-1'),
        statusCode: 403,
        data: {'error': _pesan403},
      ),
    );

/// Respons 403 lain pada endpoint yang sama: nasabah nonaktif, dikirim
/// sebelum `profil_terkunci` sempat diperiksa (pilah-be/api/views.py:487-488).
/// Beda alasan, sama-sama 403; klien harus membedakannya lewat pesannya.
NetworkException _tolak403NonAktif() => NetworkException.handleBadResponse(
      Response(
        requestOptions: RequestOptions(path: '/api/v1/nasabah/nasabah-1'),
        statusCode: 403,
        data: {'error': _pesan403NonAktif},
      ),
    );

NasabahEntity _nasabah({bool punyaAkun = false, String status = 'approved'}) =>
    NasabahEntity(
      id: 'nasabah-1',
      idNasabah: 'NAS-0001',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      phone: '+628111111111',
      balance: 'Rp 450.000',
      isActive: true,
      address: 'Jl. Mawar No. 12',
      initials: 'BS',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      tanggalDaftar: '12/05/2026',
      status: status,
      punyaAkun: punyaAkun,
    );

Widget _host(NasabahCubit cubit, NasabahEntity nasabah) => MaterialApp(
      home: BlocProvider<NasabahCubit>.value(
        value: cubit,
        child: Scaffold(body: EditNasabahBottomSheet(nasabah: nasabah)),
      ),
    );

/// `TextField.enabled` bernilai null bila tidak diatur, dan Flutter
/// memperlakukannya sebagai aktif.
bool _aktif(WidgetTester tester, int urutan) =>
    tester
        .widgetList<TextField>(find.byType(TextField))
        .elementAt(urutan)
        .enabled ??
    true;

void main() {
  late MockNasabahCubit cubit;

  setUpAll(() {
    registerFallbackValue(NasabahRequest(
      kode: '',
      nama: '',
      email: '',
      jenisKelamin: '',
      tanggalLahir: '',
      noHp: '',
      alamat: '',
    ));
  });

  setUp(() {
    cubit = MockNasabahCubit();
    // Form membaca cubit lewat `context.read` di dalam validator, dan
    // BlocProvider ikut berlangganan streamnya.
    whenListen(
      cubit,
      const Stream<NasabahState>.empty(),
      initialState: const NasabahLoaded(nasabahList: []),
    );
  });

  Future<void> pump(WidgetTester tester, NasabahEntity nasabah) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(cubit, nasabah));
  }

  group('Form ubah nasabah menghormati profil milik pemilik akun (PIL-206)',
      () {
    testWidgets('nasabah berakun: field profil global dimatikan',
        (tester) async {
      await pump(tester, _nasabah(punyaAkun: true));

      expect(_aktif(tester, _nama), isFalse);
      expect(_aktif(tester, _email), isFalse);
      expect(_aktif(tester, _tanggalLahir), isFalse);
      expect(_aktif(tester, _whatsapp), isFalse);
      expect(_aktif(tester, _alamat), isFalse);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .onChanged,
        isNull,
        reason: 'jenis kelamin juga profil global',
      );
    });

    testWidgets('nasabah berakun: nomor anggota tetap dapat diubah',
        (tester) async {
      // Nomor anggota adalah data keanggotaan milik bank sampah, jadi pengurus
      // harus tetap dapat memperbaikinya (PIL-223).
      await pump(tester, _nasabah(punyaAkun: true));

      expect(_aktif(tester, _nomorAnggota), isTrue);
    });

    testWidgets('nasabah berakun: alasannya dijelaskan pada form',
        (tester) async {
      await pump(tester, _nasabah(punyaAkun: true));

      expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets('nasabah tanpa akun: seluruh field tetap dapat diubah',
        (tester) async {
      await pump(tester, _nasabah(punyaAkun: false));

      for (final urutan in [
        _nama,
        _nomorAnggota,
        _email,
        _tanggalLahir,
        _whatsapp,
        _alamat
      ]) {
        expect(_aktif(tester, urutan), isTrue);
      }
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });

    testWidgets('nasabah tanpa akun: jenis kelamin dapat dipilih ulang',
        (tester) async {
      await pump(tester, _nasabah(punyaAkun: false));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perempuan').last);
      await tester.pumpAndSettle();

      expect(find.text('Perempuan'), findsOneWidget);
    });

    testWidgets('data tanpa penanda penautan tetap dapat diubah sepenuhnya',
        (tester) async {
      await pump(tester, _nasabah());

      expect(_aktif(tester, _nama), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });

  testWidgets('nomor anggota yang dipakai nasabah lain ditolak di form',
      (tester) async {
    // Nomor anggota tetap milik pengurus, jadi validasi duplikatnya harus
    // tetap berjalan dan tidak boleh menganggap nasabah ini duplikat dirinya.
    when(() => cubit.state).thenReturn(NasabahLoaded(nasabahList: [
      _nasabah(),
      NasabahEntity(
        id: 'nasabah-2',
        idNasabah: 'NAS-0002',
        name: 'Siti Aminah',
        phone: '+628222222222',
        balance: 'Rp 0',
        isActive: true,
        address: 'Jl. Melati No. 3',
        initials: 'SA',
        avatarColor: const Color(0xFFEAF5EC),
        textColor: const Color(0xFF2F6B45),
        jenisKelamin: 'Perempuan',
        tanggalLahir: '02/02/1992',
      ),
    ]));

    await pump(tester, _nasabah());
    await tester.enterText(
        find.byType(TextField).at(_nomorAnggota), 'NAS-0002');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('ID Nasabah ini sudah digunakan.'), findsOneWidget);
    verifyNever(() => cubit.updateNasabah(any(), any()));
  });

  group('Penanda penautan yang sudah basi (PIL-206)', () {
    testWidgets('penolakan 403 mengunci form, bukan mengundang coba ulang',
        (tester) async {
      // Nasabah bisa menautkan akunnya setelah daftar dimuat, sehingga penanda
      // di klien sudah basi dan form terbuka. Begitu server menolak, form harus
      // ikut terkunci; membiarkannya terbuka mengundang pengurus mengetik ulang
      // hasil yang sama.
      when(() => cubit.updateNasabah(any(), any()))
          .thenAnswer((_) async => _tolak403());

      await pump(tester, _nasabah(punyaAkun: false));
      expect(_aktif(tester, _nama), isTrue);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(_aktif(tester, _nama), isFalse);
      expect(_aktif(tester, _nomorAnggota), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets(
        '403 nasabah nonaktif tidak mengunci form sebagai profil berakun',
        (tester) async {
      // pilah-be memeriksa is_active sebelum profil_terkunci (views.py:487-488)
      // dan memakai 403 untuk keduanya. Nasabah nonaktif tanpa akun bukan
      // profil berakun; menyamakan keduanya lewat status code saja salah
      // mengunci field dan salah menjelaskan alasannya ke pengurus.
      when(() => cubit.updateNasabah(any(), any()))
          .thenAnswer((_) async => _tolak403NonAktif());

      await pump(tester, _nasabah(punyaAkun: false));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(_aktif(tester, _nama), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });

    testWidgets('kegagalan lain tidak ikut mengunci form', (tester) async {
      // Hanya 403 profil yang berarti profilnya bukan milik pengurus. Galat
      // lain, misalnya jaringan, harus tetap membolehkan perbaikan.
      when(() => cubit.updateNasabah(any(), any()))
          .thenAnswer((_) async => NetworkException(message: 'jaringan putus'));

      await pump(tester, _nasabah(punyaAkun: false));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(_aktif(tester, _nama), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });
}
