import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Right;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_paged_list_view.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_table.dart';
import '../../../../support/mock_sinkron_profil_nasabah_use_case.dart';

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockGetActiveNasabahUseCase extends Mock
    implements GetActiveNasabahUseCase {}

class _MockGetNasabahRingkasanUseCase extends Mock
    implements GetNasabahRingkasanUseCase {}

class _MockAddNasabahUseCase extends Mock implements AddNasabahUseCase {}

class _MockUpdateNasabahUseCase extends Mock implements UpdateNasabahUseCase {}

class _MockActivateNasabahUseCase extends Mock
    implements ActivateNasabahUseCase {}

class _MockDeactivateNasabahUseCase extends Mock
    implements DeactivateNasabahUseCase {}

class _MockApproveNasabahUseCase extends Mock
    implements ApproveNasabahUseCase {}

class _MockRejectNasabahUseCase extends Mock implements RejectNasabahUseCase {}

NasabahEntity _nasabah(int nomor) => NasabahEntity(
      id: 'n-$nomor',
      idNasabah: 'NAS-${nomor.toString().padLeft(4, '0')}',
      name: 'Nasabah $nomor',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

void main() {
  late _MockGetNasabahUseCase getUseCase;
  late NasabahCubit cubit;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    cubit = NasabahCubit(
      getUseCase,
      _MockGetActiveNasabahUseCase(),
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
      MockSinkronProfilNasabahUseCase(),
    );
  });

  tearDown(() => cubit.close());

  // Below the medium breakpoint, so the page keeps its phone list.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(590, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget host() => MaterialApp(
        home: BlocProvider<NasabahCubit>.value(
          value: cubit,
          child: const NasabahPage(),
        ),
      );

  if (!kIsWeb) {
    testWidgets('renders the paged list and forwards the load-more request',
        (tester) async {
      when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetNasabahParams;
        return Right(_halaman(params.page));
      });

      usePhone(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.byType(NasabahPagedListView), findsOneWidget);
      expect(find.text('Nasabah 1'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();

      // Halaman kedua diminta lewat callback milik halaman, bukan oleh widget
      // daftar sendiri, jadi ini menguji sambungannya.
      final params = verify(() => getUseCase.execute(captureAny()))
          .captured
          .cast<GetNasabahParams>();
      expect(params.map((p) => p.page), contains(2));
      expect(find.text('Nasabah 21'), findsOneWidget);
    });
  }

  if (kIsWeb) {
    testWidgets('desktop web loads selected server pages', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetNasabahParams;
        return Right(_webHalaman(params.page));
      });

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.byType(NasabahTable), findsOneWidget);
      expect(find.text('Menampilkan 1–10 dari 25 nasabah'), findsOneWidget);
      expect(find.text('Nasabah 1'), findsOneWidget);
      expect(find.text('Nasabah 11'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Halaman 2'));
      await tester.pumpAndSettle();
      expect(find.text('Menampilkan 11–20 dari 25 nasabah'), findsOneWidget);
      expect(find.text('Nasabah 1'), findsNothing);
      expect(find.text('Nasabah 11'), findsOneWidget);

      final params = verify(() => getUseCase.execute(captureAny()))
          .captured
          .cast<GetNasabahParams>();
      expect(params.map((p) => p.page), [1, 2]);
      expect(params.map((p) => p.pageSize), [10, 10]);
    });

    testWidgets('compact web paginates cards without infinite loading',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetNasabahParams;
        return Right(_webHalaman(params.page));
      });

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.byType(NasabahPagedListView), findsOneWidget);
      expect(find.byType(WebPaginationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Tambah Nasabah'), findsOneWidget);
      expect(
          tester
              .widget<NasabahPagedListView>(
                find.byType(NasabahPagedListView),
              )
              .hasMore,
          isFalse);
      await tester.tap(find.bySemanticsLabel('Halaman 2'));
      await tester.pumpAndSettle();
      expect(find.text('Nasabah 11'), findsOneWidget);
      expect(find.text('Nasabah 1'), findsNothing);
    });
  }

  testWidgets('keeps current rows and selection visible while switching tabs',
      (tester) async {
    final inactiveResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    when(() => getUseCase.execute(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      if (params.status == 'tidak_aktif') return inactiveResponse.future;
      return Future.value(Right(_halaman(1)));
    });

    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('Nasabah 1'), findsOneWidget);

    await tester.tap(find.text('Tidak Aktif'));
    await tester.pump();

    expect(find.byType(NasabahPagedListView), findsOneWidget);
    expect(find.text('Nasabah 1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Tidak Aktif')).style?.color,
      Colors.white,
    );
    expect(
      tester.widget<Text>(find.text('Aktif')).style?.color,
      isNot(Colors.white),
    );

    inactiveResponse.complete(Right(_halaman(2)));
    await tester.pumpAndSettle();

    expect(find.text('Nasabah 21'), findsOneWidget);
    expect(find.text('Nasabah 1'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('keeps the chosen tab selected during the initial load',
      (tester) async {
    final activeResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    final inactiveResponse =
        Completer<Either<NetworkException, HalamanNasabah>>();
    when(() => getUseCase.execute(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      return params.status == 'aktif'
          ? activeResponse.future
          : inactiveResponse.future;
    });

    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.tap(find.text('Tidak Aktif'));
    await tester.pump();

    expect(
      tester.widget<Text>(find.text('Tidak Aktif')).style?.color,
      Colors.white,
    );
    expect(
      tester.widget<Text>(find.text('Aktif')).style?.color,
      isNot(Colors.white),
    );

    inactiveResponse.complete(Right(_halaman(2)));
    await tester.pumpAndSettle();
    activeResponse.complete(Right(_halaman(1)));
    await tester.pumpAndSettle();

    expect(find.text('Nasabah 21'), findsOneWidget);
  });
}

/// Halaman berisi 20 baris; halaman pertama masih menyisakan halaman lanjutan.
HalamanNasabah _halaman(int halaman) {
  final mulai = (halaman - 1) * 20 + 1;
  return HalamanNasabah(
    items: [for (var i = mulai; i < mulai + 20; i++) _nasabah(i)],
    totalCount: 40,
    hasMore: halaman < 2,
  );
}

HalamanNasabah _webHalaman(int halaman) {
  final mulai = (halaman - 1) * 10 + 1;
  final akhir = halaman == 3 ? 25 : mulai + 9;
  return HalamanNasabah(
    items: [for (var i = mulai; i <= akhir; i++) _nasabah(i)],
    totalCount: 25,
    hasMore: halaman < 3,
  );
}
