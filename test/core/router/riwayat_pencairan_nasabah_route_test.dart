import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_nasabah_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockUseCases extends Mock implements PencairanUseCases {}

void main() {
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));

  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<PencairanCubit>()) di.unregister<PencairanCubit>();
    if (di.isRegistered<RiwayatPencairanCubit>()) {
      di.unregister<RiwayatPencairanCubit>();
    }
    if (di.isRegistered<EditPencairanCubit>()) {
      di.unregister<EditPencairanCubit>();
    }
    if (di.isRegistered<RevisiPencairanCubit>()) {
      di.unregister<RevisiPencairanCubit>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() async {
    if (di.isRegistered<InviteTokenStore>()) {
      await di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<PencairanCubit>()) {
      await di.unregister<PencairanCubit>();
    }
    if (di.isRegistered<RiwayatPencairanCubit>()) {
      await di.unregister<RiwayatPencairanCubit>();
    }
    if (di.isRegistered<EditPencairanCubit>()) {
      await di.unregister<EditPencairanCubit>();
    }
    if (di.isRegistered<RevisiPencairanCubit>()) {
      await di.unregister<RevisiPencairanCubit>();
    }
  });

  testWidgets('router opens the Nasabah payout history page', (tester) async {
    final useCases = _MockUseCases();
    when(() => useCases.getRiwayat(any())).thenAnswer(
        (_) async => const Right<NetworkException, List<Pencairan>>([]));
    di.registerFactory<RiwayatPencairanCubit>(
      () => RiwayatPencairanCubit(useCases),
    );

    final authBloc = _MockAuthenticationBloc();
    whenListen(
      authBloc,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationLoading(),
    );

    final router = AppRouterConfig.getRouter();
    router.go(RiwayatPencairanNasabahPage.route);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: authBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Riwayat Pencairan'), findsOneWidget);
    verify(() => useCases.getRiwayat(any())).called(1);

    await tester.pumpWidget(
      MaterialApp(
        home: RiwayatPencairanNasabahPage(key: UniqueKey()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Pencairan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('router builds every pengurus payout page with its extra',
      (tester) async {
    final useCases = _MockUseCases();
    when(() => useCases.getSaldo('n-1'))
        .thenAnswer((_) async => const Right<NetworkException, int>(500000));
    when(() => useCases.getRiwayat(any())).thenAnswer(
        (_) async => const Right<NetworkException, List<Pencairan>>([]));
    when(() => useCases.getRevisi('p-1')).thenAnswer(
      (_) async => Right(
        RiwayatRevisiPencairan(
          pencairan: _pencairan,
          revisi: const [],
        ),
      ),
    );
    di.registerFactory<PencairanCubit>(() => PencairanCubit(useCases));
    di.registerFactory<RiwayatPencairanCubit>(
      () => RiwayatPencairanCubit(useCases),
    );
    di.registerFactory<EditPencairanCubit>(
      () => EditPencairanCubit(useCases),
    );
    di.registerFactory<RevisiPencairanCubit>(
      () => RevisiPencairanCubit(useCases),
    );

    final authBloc = _MockAuthenticationBloc();
    whenListen(
      authBloc,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationLoading(),
    );
    final router = AppRouterConfig.getRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: authBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(CatatPencairanPage.route,
        extra: const CatatPencairanArgs(
          nasabahId: 'n-1',
          nasabahNama: 'Ayu Nasabah',
        ));
    await tester.pumpAndSettle();
    expect(find.text('Catat Pencairan'), findsNWidgets(2));
    expect(find.text('Ayu Nasabah'), findsOneWidget);

    router.go(RiwayatPencairanPage.route);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pencairan'), findsOneWidget);

    router.go(EditPencairanPage.route, extra: _pencairan);
    await tester.pumpAndSettle();
    expect(find.text('Edit Pencairan'), findsOneWidget);
    expect(find.text('Ayu Nasabah'), findsOneWidget);

    router.go(RevisiPencairanPage.route, extra: 'p-1');
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Perubahan'), findsOneWidget);
    expect(find.text('Versi sekarang'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final _pencairan = Pencairan(
  id: 'p-1',
  nasabahId: 'n-1',
  nasabahNama: 'Ayu Nasabah',
  bankSampahNama: 'Bank Sampah Melati',
  nominal: 200000,
  metode: MetodePencairan.tunai,
  tanggal: DateTime(2026, 9, 22, 9),
  keterangan: 'Ambil di kasir',
  status: 'tercatat',
  saldoSebelum: 500000,
  saldoSesudah: 300000,
);
