import 'package:bloc_test/bloc_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

class MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

AuthEntity testAuth({
  String name = 'Siti Aminah',
  String? bank = 'Bank Sampah Melati',
  String? role = 'pengelola',
}) =>
    AuthEntity(
      id: 'u1',
      name: name,
      email: 'siti@example.test',
      photoUrl: '',
      token: 'tok',
      bankSampahNama: bank,
      role: role,
    );

/// An auth bloc already sitting in [state].
MockAuthBloc authBlocIn(AuthenticationStates state) {
  final bloc = MockAuthBloc();
  whenListen(bloc, const Stream<AuthenticationStates>.empty(),
      initialState: state);
  return bloc;
}
