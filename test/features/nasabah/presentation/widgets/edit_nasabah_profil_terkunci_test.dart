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

/// Respons yang dikirim backend ketika profil nasabah berakun diubah
/// (PIL-223): 403 dengan satu pesan pada kunci `error`.
NetworkException _tolak403() => NetworkException.handleBadResponse(
      Response(
        requestOptions: RequestOptions(path: '/api/v1/nasabah/nasabah-1'),
        statusCode: 403,
        data: {'error': _pesan403},
      ),
    );

Map<String, dynamic> _customerData({bool? punyaAkun}) => {
      'id': 'nasabah-1',
      'name': 'Budi Santoso',
      'idNasabah': 'NAS-0001',
      'email': 'budi@example.com',
      'jenisKelamin': 'Laki-laki',
      'tanggalLahir': '01/01/1990',
      'phone': '+628111111111',
      'address': 'Jl. Mawar No. 12',
      if (punyaAkun != null) 'punyaAkun': punyaAkun,
    };

Widget _host(NasabahCubit cubit, Map<String, dynamic> data) => MaterialApp(
      home: BlocProvider<NasabahCubit>.value(
        value: cubit,
        child: Scaffold(body: EditNasabahBottomSheet(customerData: data)),
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

  setUp(() {
    cubit = MockNasabahCubit();
    when(() => cubit.state).thenReturn(const NasabahLoaded(nasabahList: []));
  });

  Future<void> pump(WidgetTester tester, Map<String, dynamic> data) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(cubit, data));
  }

  group('Form ubah nasabah menghormati profil milik pemilik akun (PIL-206)',
      () {
    testWidgets('nasabah berakun: field profil global dimatikan',
        (tester) async {
      await pump(tester, _customerData(punyaAkun: true));

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
      await pump(tester, _customerData(punyaAkun: true));

      expect(_aktif(tester, _nomorAnggota), isTrue);
    });

    testWidgets('nasabah berakun: alasannya dijelaskan pada form',
        (tester) async {
      await pump(tester, _customerData(punyaAkun: true));

      expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets('nasabah tanpa akun: seluruh field tetap dapat diubah',
        (tester) async {
      await pump(tester, _customerData(punyaAkun: false));

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
      await pump(tester, _customerData(punyaAkun: false));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perempuan').last);
      await tester.pumpAndSettle();

      expect(find.text('Perempuan'), findsOneWidget);
    });

    testWidgets('data tanpa penanda penautan tetap dapat diubah sepenuhnya',
        (tester) async {
      await pump(tester, _customerData());

      expect(_aktif(tester, _nama), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });

  group('Penanda penautan yang sudah basi (PIL-206)', () {
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

    testWidgets('penolakan 403 mengunci form, bukan mengundang coba ulang',
        (tester) async {
      // Nasabah bisa menautkan akunnya setelah daftar dimuat, sehingga penanda
      // di klien sudah basi dan form terbuka. Begitu server menolak, form harus
      // ikut terkunci; membiarkannya terbuka mengundang pengurus mengetik ulang
      // hasil yang sama.
      when(() => cubit.updateNasabah(any(), any()))
          .thenAnswer((_) async => _tolak403());

      await pump(tester, _customerData(punyaAkun: false));
      expect(_aktif(tester, _nama), isTrue);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(_aktif(tester, _nama), isFalse);
      expect(_aktif(tester, _nomorAnggota), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets('kegagalan lain tidak ikut mengunci form', (tester) async {
      // Hanya 403 profil yang berarti profilnya bukan milik pengurus. Galat
      // lain, misalnya jaringan, harus tetap membolehkan perbaikan.
      when(() => cubit.updateNasabah(any(), any()))
          .thenAnswer((_) async => NetworkException(message: 'jaringan putus'));

      await pump(tester, _customerData(punyaAkun: false));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(_aktif(tester, _nama), isTrue);
      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });
}
