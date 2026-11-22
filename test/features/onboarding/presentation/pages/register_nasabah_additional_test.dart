import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';

/// PIL-539: the registration form opened from "Bank sampah saya" by a nasabah
/// who already belongs to a bank sampah.
class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

const _listRoute = '/approval-bank-sampah';

const _bankB = BankSampahDirectoryEntity(
  id: 'bank-b',
  nama: 'Bank Sampah Mawar',
  alamat: 'Jl. Mawar',
  kota: 'Depok',
  fotoLogo: '',
);

const _membershipA = NasabahMembershipEntity(
  id: 'membership-a',
  bankSampahId: 'bank-a',
  bankSampahNama: 'Bank Sampah Melati',
  bankSampahKota: 'Bogor',
  status: 'approved',
  isActive: true,
);

void main() {
  late TestAuthenticationNotifier auth;
  late _MockOnboardingDataSource dataSource;
  late ProviderContainer container;

  setUp(() {
    auth = authNotifierIn(AuthenticationInitial());
    dataSource = _MockOnboardingDataSource();
    container = buildOnboardingContainer(dataSource);
    when(() => dataSource.listBankSampahDirectory())
        .thenAnswer((_) async => [_bankB]);
    when(() => dataSource.listMyMemberships())
        .thenAnswer((_) async => [_membershipA]);
  });

  tearDown(() => container.dispose());

  Future<GoRouter> pumpFromList(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: _listRoute,
      routes: [
        GoRoute(
          path: _listRoute,
          builder: (_, __) => const Scaffold(body: Text('BANK SAMPAH SAYA')),
        ),
        GoRoute(
          path: RegisterNasabahScreen.additionalRoute,
          builder: (_, __) =>
              const RegisterNasabahScreen(mode: RegisterNasabahMode.additional),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: withAuthenticationProvider(
          auth,
          MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    router.push(RegisterNasabahScreen.additionalRoute);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('opens as a page of the app, not as an onboarding step',
      (tester) async {
    await pumpFromList(tester);

    expect(find.text('Ajukan bank sampah baru'), findsOneWidget);
    expect(find.text('Profil Diri'), findsNothing);
    expect(find.byTooltip('Keluar'), findsNothing);
  });

  testWidgets('an existing membership does not lock the form', (tester) async {
    await pumpFromList(tester);

    expect(find.textContaining('hanya dapat terdaftar di 1 bank sampah'),
        findsNothing);
    expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    await tester.tap(find.text('Tap untuk pilih bank sampah'));
    await tester.pumpAndSettle();
    expect(find.text('Cari nama bank sampah...'), findsOneWidget);
  });

  testWidgets('back returns to Bank sampah saya without asking to log out',
      (tester) async {
    await pumpFromList(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('BANK SAMPAH SAYA'), findsOneWidget);
    expect(find.text('Keluar dari Pendaftaran?'), findsNothing);
    expect(auth.calls, isNot(contains('logout')));
  });

  testWidgets('system back also returns without asking to log out',
      (tester) async {
    await pumpFromList(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('BANK SAMPAH SAYA'), findsOneWidget);
    expect(find.text('Keluar dari Pendaftaran?'), findsNothing);
  });
}
