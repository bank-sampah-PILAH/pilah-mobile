import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_nasabah_page.dart';
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
    if (di.isRegistered<RiwayatPencairanCubit>()) {
      di.unregister<RiwayatPencairanCubit>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() async {
    if (di.isRegistered<InviteTokenStore>()) {
      await di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<RiwayatPencairanCubit>()) {
      await di.unregister<RiwayatPencairanCubit>();
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
    addTearDown(router.dispose);

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
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
