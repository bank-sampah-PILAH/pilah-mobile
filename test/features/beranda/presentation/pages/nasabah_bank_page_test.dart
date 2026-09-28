import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/nasabah_bank_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

/// Counts calls to [bank] so a pull-to-refresh test can assert the load ran
/// again, without caring how many times the widget tree rebuilds.
class _CountingNasabahRepository extends PreviewNasabahRepository {
  int bankCalls = 0;

  @override
  Future<NasabahBank> bank(String membershipId) {
    bankCalls++;
    return super.bank(membershipId);
  }
}

void main() {
  testWidgets('menarik layar ke bawah memuat ulang detail bank (PIL-285)',
      (tester) async {
    final auth = _Auth();
    final repository = _CountingNasabahRepository();
    di.registerSingleton<NasabahRepository>(repository);
    whenListen(auth, const Stream<AuthenticationStates>.empty(),
        initialState: Authenticated(
            authEntity: AuthEntity(
          id: 'nasabah-285',
          name: 'Siti Aminah',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'test-token',
          role: 'nasabah',
          nextStep: 'dashboard',
        )));
    addTearDown(() async {
      await auth.close();
      await di.unregister<NasabahRepository>();
    });

    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
        value: auth, child: const MaterialApp(home: NasabahBankPage())));
    await tester.pumpAndSettle();

    // PreviewNasabahRepository.home() (membership resolution) itself calls
    // bank(''), plus NasabahResource's own initial load, so 2 calls happen
    // before any pull — see PreviewNasabahRepository.home().
    final callsBeforeRefresh = repository.bankCalls;
    expect(find.byTooltip('Muat ulang'), findsNothing,
        reason: 'the manual refresh button is replaced by pull-to-refresh');

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pumpAndSettle();

    expect(repository.bankCalls, callsBeforeRefresh + 1);
  });
}
