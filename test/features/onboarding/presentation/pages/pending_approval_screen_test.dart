import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

const _nasabahAuth = AuthEntity(
  name: 'Nasabah PILAH',
  email: 'nasabah@example.com',
  photoUrl: '',
  token: 'token',
  role: 'nasabah',
);

const _pengelolaAuth = AuthEntity(
  name: 'Pengelola PILAH',
  email: 'pengelola@example.com',
  photoUrl: '',
  token: 'token',
  role: 'pengelola',
);

void main() {
  late _MockAuthBloc auth;

  Future<void> pump(WidgetTester tester, AuthEntity authEntity) async {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: Authenticated(authEntity: authEntity),
    );
    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: auth,
        child: const MaterialApp(home: PendingApprovalScreen()),
      ),
    );
  }

  testWidgets('a nasabah sees membership-application copy, not institution copy',
      (tester) async {
    await pump(tester, _nasabahAuth);

    expect(find.textContaining('institusi'), findsNothing);
    expect(find.textContaining('bank sampah'), findsNothing);
    expect(find.textContaining('keanggotaan'), findsWidgets);
  });

  testWidgets('a pengelola still sees the original institution copy',
      (tester) async {
    await pump(tester, _pengelolaAuth);

    expect(find.textContaining('institusi'), findsWidgets);
  });
}
