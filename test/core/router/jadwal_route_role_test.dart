import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
  });

  testWidgets('authenticated nasabah receives the read-only jadwal route',
      (tester) async {
    final authenticationBloc = _MockAuthenticationBloc();
    final jadwalCubit = _MockJadwalCubit();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    when(() => authenticationBloc.state).thenReturn(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    when(() => jadwalCubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => jadwalCubit.loadJadwal()).thenAnswer((_) async {});

    final router = AppRouterConfig.getRouter();
    router.go(JadwalPage.route);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: authenticationBloc),
          BlocProvider<JadwalCubit>.value(value: jadwalCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Terbitkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);
  });
}
