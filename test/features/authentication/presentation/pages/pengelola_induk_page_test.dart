import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/pengelola_induk_page.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

void main() {
  setUpAll(() => registerFallbackValue(LogoutRequested()));

  testWidgets('shows the signed-in role and provides logout', (tester) async {
    final auth = _MockAuthBloc();
    whenListen(auth, const Stream<AuthenticationStates>.empty(),
        initialState: AuthenticationInitial());
    addTearDown(auth.close);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<AuthenticationBloc>.value(
        value: auth,
        child: const PengelolaIndukPage(),
      ),
    ));

    expect(find.text('Pengelola Induk'), findsOneWidget);
    await tester.tap(find.text('Keluar'));
    verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
  });
}
