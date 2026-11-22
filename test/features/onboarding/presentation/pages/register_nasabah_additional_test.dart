import 'package:dio/dio.dart';
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
import '../../../../support/pump_app.dart';

/// PIL-539: the registration form opened from "Bank sampah saya" by a nasabah
/// who already belongs to a bank sampah.
class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

class _FakeRegisterNasabahRequest extends Fake
    implements RegisterNasabahRequest {}

class _FakeCompleteProfileRequest extends Fake
    implements CompleteProfileRequest {}

const _duplicate = 'Anda sudah terdaftar sebagai nasabah di bank sampah ini';

DioException _refusal(String message) => DioException(
      requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
        statusCode: 400,
        data: {'error': message},
      ),
    );

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
  setUpAll(() {
    registerFallbackValue(_FakeRegisterNasabahRequest());
    registerFallbackValue(_FakeCompleteProfileRequest());
  });

  late TestAuthenticationNotifier auth;
  late Future<bool?> pushed;
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
    pushed = router.push<bool>(RegisterNasabahScreen.additionalRoute);
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

  group('the bank picker', () {
    const bankA = BankSampahDirectoryEntity(
      id: 'bank-a',
      nama: 'Bank Sampah Melati',
      alamat: 'Jl. Melati',
      kota: 'Bogor',
      fotoLogo: '',
    );
    const bankC = BankSampahDirectoryEntity(
      id: 'bank-c',
      nama: 'Bank Sampah Kenanga',
      alamat: 'Jl. Kenanga',
      kota: 'Depok',
      fotoLogo: '',
    );

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists a bank already joined, marked, and does not pick it',
        (tester) async {
      when(() => dataSource.listBankSampahDirectory())
          .thenAnswer((_) async => [bankA, _bankB]);
      await pumpFromList(tester);
      await openPicker(tester);

      expect(find.text('Bank Sampah Melati'), findsWidgets);
      expect(find.text('Sudah tergabung'), findsOneWidget);

      await tester.tap(find.text('Sudah tergabung'));
      await tester.pumpAndSettle();

      expect(find.text('Cari nama bank sampah...'), findsOneWidget);
    });

    testWidgets('marks a pending or rejected application too', (tester) async {
      when(() => dataSource.listMyMemberships()).thenAnswer((_) async => [
            _membershipA,
            const NasabahMembershipEntity(
              id: 'membership-b',
              bankSampahId: 'bank-b',
              bankSampahNama: 'Bank Sampah Mawar',
              bankSampahKota: 'Depok',
              status: 'pending',
              isActive: false,
            ),
            const NasabahMembershipEntity(
              id: 'membership-c',
              bankSampahId: 'bank-c',
              bankSampahNama: 'Bank Sampah Kenanga',
              bankSampahKota: 'Depok',
              status: 'rejected',
              isActive: false,
            ),
          ]);
      when(() => dataSource.listBankSampahDirectory())
          .thenAnswer((_) async => [bankA, _bankB, bankC]);
      await pumpFromList(tester);
      await openPicker(tester);

      expect(find.text('Sudah tergabung'), findsOneWidget);
      expect(find.text('Menunggu persetujuan'), findsOneWidget);
      expect(find.text('Pernah ditolak'), findsOneWidget);
    });

    testWidgets('picks a bank not joined yet', (tester) async {
      when(() => dataSource.listBankSampahDirectory())
          .thenAnswer((_) async => [bankA, _bankB]);
      await pumpFromList(tester);
      await openPicker(tester);

      await tester.tap(find.text('Bank Sampah Mawar'));
      await tester.pumpAndSettle();

      expect(find.text('Cari nama bank sampah...'), findsNothing);
      expect(find.text('Bank Sampah Mawar'), findsOneWidget);
    });
  });

  group('applying', () {
    Future<void> pickBankB(WidgetTester tester) async {
      await tester.tap(find.text('Tap untuk pilih bank sampah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Sampah Mawar'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'sends only the membership request and returns to Bank sampah saya',
        (tester) async {
      when(() => dataSource.registerNasabah(any())).thenAnswer(
          (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'));
      await pumpFromList(tester);
      await pickBankB(tester);

      await tester.tap(find.text('Ajukan Pendaftaran'));
      await pumpToast(tester);

      final request = verify(() => dataSource.registerNasabah(captureAny()))
          .captured
          .single as RegisterNasabahRequest;
      expect(request.bankSampahId, 'bank-b');
      verifyNever(() => dataSource.completeProfile(any()));
      expect(find.text('BANK SAMPAH SAYA'), findsOneWidget);
      expect(find.text('Pengajuan terkirim'), findsOneWidget);
      expect(await pushed, isTrue);
      // The account is already signed in and onboarded: applying to another
      // bank does not touch its session.
      expect(auth.calls, isNot(contains('refreshUser')));
      await settleToasts(tester);
    });

    testWidgets('a duplicate application shows the reason and stays',
        (tester) async {
      when(() => dataSource.registerNasabah(any()))
          .thenAnswer((_) async => throw _refusal(_duplicate));
      await pumpFromList(tester);
      await pickBankB(tester);

      await tester.tap(find.text('Ajukan Pendaftaran'));
      await pumpToast(tester);

      expect(find.text(_duplicate), findsOneWidget);
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
      expect(find.text('BANK SAMPAH SAYA'), findsNothing);
      await settleToasts(tester);
    });

    testWidgets('asks for a bank before sending anything', (tester) async {
      await pumpFromList(tester);

      await tester.tap(find.text('Ajukan Pendaftaran'));
      await tester.pumpAndSettle();

      expect(find.text('Bank sampah wajib dipilih'), findsOneWidget);
      verifyNever(() => dataSource.registerNasabah(any()));
    });
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
