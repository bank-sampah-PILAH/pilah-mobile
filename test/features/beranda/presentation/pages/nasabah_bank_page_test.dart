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

class _Repository extends PreviewNasabahRepository {
  @override
  Future<NasabahBank> bank(String membershipId) async => const NasabahBank(
        'Bank Sampah Melati',
        'Jl. Melati No. 3',
        'Depok',
        '081234567890',
        logoUrl: 'https://example.test/media/logo.png',
        organizationType: 'unit',
      );
}

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

Authenticated _session() => Authenticated(
        authEntity: const AuthEntity(
      id: 'a',
      name: 'Siti',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'token',
      role: 'nasabah',
      nextStep: 'dashboard',
    ));

void main() {
  late _Auth auth;

  setUp(() {
    auth = _Auth();
    whenListen(auth, const Stream<AuthenticationStates>.empty(),
        initialState: _session());
  });

  tearDown(() async {
    await auth.close();
    await di.unregister<NasabahRepository>();
  });

  testWidgets('shows the bank logo, name, address, city and phone', (
    tester,
  ) async {
    di.registerSingleton<NasabahRepository>(_Repository());
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
        value: auth, child: const MaterialApp(home: NasabahBankPage())));
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah Melati'), findsOneWidget);
    expect(find.text('Jl. Melati No. 3'), findsOneWidget);
    expect(find.text('Depok'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'https://example.test/media/logo.png'),
        findsOneWidget);
  });

  testWidgets('menarik layar ke bawah memuat ulang detail bank (PIL-285)',
      (tester) async {
    final repository = _CountingNasabahRepository();
    di.registerSingleton<NasabahRepository>(repository);
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
