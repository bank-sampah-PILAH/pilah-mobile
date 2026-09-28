import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

Authenticated _session() => Authenticated(
        authEntity: const AuthEntity(
      id: 'nasabah-284',
      name: 'Siti Aminah',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'test-token',
      role: 'nasabah',
      nextStep: 'dashboard',
    ));

void main() {
  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  late _MockAuthBloc auth;
  late StreamController<AuthenticationStates> states;

  setUp(() {
    auth = _MockAuthBloc();
    states = StreamController<AuthenticationStates>();
    whenListen(auth, states.stream, initialState: _session());
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository(
        name: 'Siti Aminah', email: 'siti@example.test'));
  });

  tearDown(() async {
    await states.close();
    await auth.close();
    await di.unregister<NasabahRepository>();
  });

  testWidgets('tapping logout dispatches LogoutRequested to AuthenticationBloc',
      (tester) async {
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
        value: auth, child: const MaterialApp(home: ProfilNasabahPage())));
    await tester.pumpAndSettle();

    final logoutButton = find.text('Keluar');
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pump();

    verify(() =>
            auth.add(any<AuthenticationEvent>(that: isA<LogoutRequested>())))
        .called(1);
  });

  // Post-logout navigation to LoginPage is MainPage's shell listener's job
  // (lib/features/main/presentation/pages/main_page.dart), not this page's —
  // covered by profil_nasabah_test.dart's real-router assertion and by
  // role_navigation_test.dart. This page's only job on Unauthenticated is to
  // stop treating the session as a nasabah session, which the tests above
  // and in profil_nasabah_test.dart already cover.
}
