import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';

NasabahEntity _nasabah() => NasabahEntity(
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
      punyaAkun: true,
    );

NasabahRingkasan _ringkasan({List<String> berbeda = const []}) =>
    NasabahRingkasan(
      jumlahTransaksi: 2,
      totalKg: '3,5',
      profilAkun: const NasabahProfilAkun(
        nama: 'Budi Santosa',
        jenisKelamin: 'Laki-laki',
        tanggalLahir: '01/01/1990',
        alamat: 'Jl. Melati No. 99',
        noHp: '+628999999999',
      ),
      profilBerbeda: berbeda,
    );

class _MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

Widget _host(NasabahCubit cubit) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider<NasabahCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DetailNasabahBottomSheet(
                    nasabah: _nasabah(),
                    nasabahCubit: cubit,
                  ),
                ),
                child: const Text('Buka detail'),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late _MockNasabahCubit cubit;

  setUp(() {
    cubit = _MockNasabahCubit();
    whenListen(
      cubit,
      const Stream<NasabahState>.empty(),
      initialState: const NasabahLoaded(nasabahList: []),
    );
  });

  Future<void> bukaDetail(WidgetTester tester, NasabahRingkasan r) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => cubit.fetchRingkasan(any())).thenAnswer((_) async => r);
    await tester.pumpWidget(_host(cubit));
    await tester.tap(find.text('Buka detail'));
    await tester.pumpAndSettle();
  }

  group('Detail nasabah menampilkan profil yang diisikan nasabah sendiri', () {
    testWidgets('menandai field yang berbeda dan menampilkan nilai akunnya',
        (tester) async {
      await bukaDetail(tester, _ringkasan(berbeda: ['nama', 'no_hp']));

      expect(find.text('Data akun berbeda'), findsOneWidget);
      expect(find.text('Budi Santosa'), findsOneWidget);
      expect(find.text('+628999999999'), findsOneWidget);
      // Field yang sama tidak diulang.
      expect(find.text('Jl. Melati No. 99'), findsNothing);
      expect(find.text('Samakan dengan data akun'), findsOneWidget);
    });

    testWidgets('tanpa perbedaan tidak menampilkan bagian itu', (tester) async {
      await bukaDetail(tester, _ringkasan());

      expect(find.text('Data akun berbeda'), findsNothing);
      expect(find.text('Samakan dengan data akun'), findsNothing);
    });

    testWidgets('menyamakan hanya setelah pengurus mengonfirmasi',
        (tester) async {
      when(() => cubit.sinkronProfil(any())).thenAnswer((_) async => null);
      await bukaDetail(tester, _ringkasan(berbeda: ['no_hp']));

      await tester.tap(find.text('Samakan dengan data akun'));
      await tester.pumpAndSettle();
      verifyNever(() => cubit.sinkronProfil(any()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Samakan'));
      await tester.pumpAndSettle();

      verify(() => cubit.sinkronProfil('nasabah-1')).called(1);
    });

    testWidgets('membatalkan tidak mengubah catatan', (tester) async {
      await bukaDetail(tester, _ringkasan(berbeda: ['no_hp']));

      await tester.tap(find.text('Samakan dengan data akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.sinkronProfil(any()));
    });
  });
}
