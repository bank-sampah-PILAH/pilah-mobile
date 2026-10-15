import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

const _profile = '/api/v1/onboarding/profile';
const _accept = '/api/v1/invites/accept';

const _routes = [
  '/dashboard',
  '/register-bank-sampah',
  '/pending-approval',
  '/superadmin-dashboard',
  '/register-nasabah',
  '/nasabah-dashboard',
  '/register-bank-sampah-induk',
  '/pengelola-induk-dashboard',
  '/login',
];

AuthEntity _account({
  String role = 'pengelola',
  String? bankStatus,
  String name = '',
  String noHp = '',
  String jenisKelamin = '',
  String? tanggalLahir,
  String alamat = '',
}) =>
    AuthEntity(
      id: 'u1',
      name: name,
      email: 'u@x.test',
      photoUrl: '',
      token: 't',
      role: role,
      nextStep: 'complete_profile',
      bankSampahStatus: bankStatus,
      noHp: noHp,
      jenisKelamin: jenisKelamin,
      tanggalLahir: tanggalLahir,
      alamat: alamat,
    );

void main() {
  late StubApi api;
  late OnboardingCubit onboarding;
  late InviteTokenStore store;
  late MockAuthBloc auth;

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    api = StubApi();
    onboarding = buildOnboardingCubit(api);
    store = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(store);
  });

  tearDown(() async {
    await onboarding.close();
    await di.unregister<InviteTokenStore>();
  });

  Future<void> open(
    WidgetTester tester,
    AuthEntity account, {
    bool inviteMode = false,
    MockAuthBloc? bloc,
  }) async {
    auth = bloc ?? authBlocIn(Authenticated(authEntity: account));
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<OnboardingCubit>.value(value: onboarding),
        ],
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: CompleteProfileScreen(isInviteMode: inviteMode),
      ),
      extraRoutes: _routes,
      size: const Size(800, 2600),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester,
      {bool alamat = false, String nama = 'Siti Rahayu'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), nama);
    await tester.ensureVisible(find.text('Pilih jenis kelamin'));
    await tester.tap(find.text('Pilih jenis kelamin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perempuan').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(fields.at(1));
    await tester.tap(fields.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(2), '81234567890');
    if (alamat) await tester.enterText(fields.at(3), 'Jl. Melati No. 1');
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byType(ElevatedButton).first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await pumpToast(tester);
  }

  testWidgets('an empty form flags the required fields', (tester) async {
    await open(tester, _account());

    await submit(tester);

    expect(find.text('Nama minimal 3 karakter'), findsOneWidget);
    expect(find.text('Tanggal lahir wajib diisi'), findsOneWidget);
    expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    expect(api.requests, isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a malformed phone number is rejected', (tester) async {
    await open(tester, _account(bankStatus: 'active'));
    await fill(tester);
    await tester.enterText(find.byType(TextFormField).at(2), '123');

    await submit(tester);

    expect(find.text('Format nomor tidak valid.'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a nasabah must give an address, then banks the draft',
      (tester) async {
    await open(tester, _account(role: 'nasabah'));
    await fill(tester);

    await submit(tester);
    expect(find.text('Alamat wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), 'Jl. Melati 1');
    await submit(tester);

    expect(find.text('route:/register-nasabah'), findsOneWidget);
    expect(onboarding.profileDraft!.alamat, 'Jl. Melati 1');
    expect(api.requests, isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a new pengelola banks the draft and moves to registration',
      (tester) async {
    await open(tester, _account());
    await fill(tester);

    await submit(tester);

    expect(find.text('route:/register-bank-sampah'), findsOneWidget);
    expect(onboarding.profileDraft!.jenisKelamin, 'perempuan');
    expect(api.requests, isEmpty);
    await settleToasts(tester);
  });

  group('an existing account saves right away and follows next_step', () {
    const cases = {
      'dashboard': 'route:/dashboard',
      'register_bank_sampah': 'route:/register-bank-sampah',
      'approval_pending': 'route:/pending-approval',
      'superadmin_dashboard': 'route:/superadmin-dashboard',
      'register_nasabah': 'route:/register-nasabah',
      'nasabah_dashboard': 'route:/nasabah-dashboard',
      'register_bank_sampah_induk': 'route:/register-bank-sampah-induk',
      'pengelola_induk_dashboard': 'route:/pengelola-induk-dashboard',
      'something_new': 'route:/register-bank-sampah',
    };
    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        api.on('PUT', _profile, json: {'next_step': entry.key});
        await open(tester, _account(bankStatus: 'active'));
        await fill(tester);

        await submit(tester);

        expect(find.text(entry.value), findsOneWidget);
        verify(() => auth.add(any(that: isA<RefreshUserRequested>())))
            .called(1);
        await settleToasts(tester);
      });
    }
  });

  testWidgets('a rejected save shows the message and keeps the form',
      (tester) async {
    api.on('PUT', _profile, status: 422, json: {
      'errors': {
        'no_hp': ['Nomor sudah dipakai']
      }
    });
    await open(tester, _account(bankStatus: 'active'));
    await fill(tester);

    await submit(tester);

    expect(find.text('Nomor sudah dipakai'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    await settleToasts(tester);
  });

  group('invite mode', () {
    Future<void> openInvite(WidgetTester tester,
        {String? bankStatus, String profileStep = 'dashboard'}) async {
      store.save('tok-1');
      api.on('PUT', _profile, json: {'next_step': profileStep});
      await open(tester, _account(bankStatus: bankStatus), inviteMode: true);
      await fill(tester);
      expect(find.text('Simpan & Masuk Dashboard'), findsOneWidget);
    }

    testWidgets('joining the inviting bank lands on the dashboard',
        (tester) async {
      api.on('POST', _accept,
          json: {'next_step': 'dashboard', 'nama': 'Bank A'});
      await openInvite(tester);

      await submit(tester);

      expect(find.text('route:/dashboard'), findsOneWidget);
      expect(store.hasToken, isFalse);
      expect(find.text('Berhasil bergabung ke Bank Sampah Bank A'),
          findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('being a member already says so', (tester) async {
      api.on('POST', _accept, json: {'outcome': 'already_member'});
      await openInvite(tester);

      await submit(tester);

      expect(find.text('route:/dashboard'), findsOneWidget);
      expect(find.text('Sudah Terdaftar'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('another bank keeps the account on its own route',
        (tester) async {
      api.on('POST', _accept,
          status: 400,
          json: {'error': 'Akun ini sudah tergabung dengan bank sampah'});
      await openInvite(tester,
          bankStatus: 'pending', profileStep: 'approval_pending');

      await submit(tester);

      expect(find.text('route:/pending-approval'), findsOneWidget);
      expect(find.text('Pengajuan Sedang Ditinjau'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('an invalid link is reported and the token is retired',
        (tester) async {
      api.on('POST', _accept,
          status: 400, json: {'error': 'Tautan undangan tidak valid'});
      await openInvite(tester);

      await submit(tester);

      expect(find.text('Tautan undangan tidak valid'), findsOneWidget);
      expect(store.hasToken, isFalse);
      await settleToasts(tester);
    });

    testWidgets('a network failure keeps the token for a retry',
        (tester) async {
      api.fail('POST', _accept);
      await openInvite(tester);

      await submit(tester);

      expect(find.text('Gagal Bergabung'), findsOneWidget);
      expect(store.hasToken, isTrue);
      expect(find.byType(TextFormField), findsWidgets);
      await settleToasts(tester);
    });

    testWidgets(
        'a token arriving while the form is open switches to invite mode',
        (tester) async {
      await open(tester, _account(bankStatus: 'active'));
      expect(find.text('Simpan Profil & Lanjut'), findsOneWidget);

      store.save('late-token');
      await tester.pump();

      expect(find.text('Simpan & Masuk Dashboard'), findsOneWidget);
    });
  });

  group('prefilling', () {
    testWidgets('restores a banked draft', (tester) async {
      onboarding.saveProfileDraft(const CompleteProfileDraftForTest().request);
      await open(tester, _account());

      expect(
          find.widgetWithText(TextFormField, 'Budi Santoso'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '17/04/1990'), findsOneWidget);
      expect(find.text('Laki-laki'), findsOneWidget);
    });

    testWidgets('an unparsable draft date leaves the date empty',
        (tester) async {
      onboarding.saveProfileDraft(
          const CompleteProfileDraftForTest(tanggal: 'bukan-tanggal').request);
      await open(tester, _account());

      expect(find.widgetWithText(TextFormField, '17/04/1990'), findsNothing);
    });

    testWidgets('uses the account\'s saved profile when there is no draft',
        (tester) async {
      await open(
          tester,
          _account(
            role: 'nasabah',
            name: 'Siti Aminah',
            noHp: '+6281234567890',
            jenisKelamin: 'perempuan',
            tanggalLahir: '1998-05-17',
            alamat: 'Jl. Melati 1',
          ));

      expect(find.widgetWithText(TextFormField, 'Siti Aminah'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '81234567890'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '17/05/1998'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Jl. Melati 1'), findsOneWidget);
    });

    testWidgets('a local-format phone number loses its leading zero',
        (tester) async {
      await open(tester, _account(noHp: '081234567890', tanggalLahir: 'x'));

      expect(find.widgetWithText(TextFormField, '81234567890'), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('system back asks before logging out', (tester) async {
      await open(tester, _account());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Batal Lengkapi Profil?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      verifyNever(() => auth.add(any(that: isA<LogoutRequested>())));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();
      verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
    });

    testWidgets('signing out routes to the login page', (tester) async {
      final bloc = MockAuthBloc();
      whenListen(
          bloc, Stream<AuthenticationStates>.fromIterable([Unauthenticated()]),
          initialState: Authenticated(authEntity: _account()));

      await open(tester, _account(), bloc: bloc);

      expect(find.text('route:/login'), findsOneWidget);
    });
  });
}

/// A banked draft with overridable date, as the wizard would leave behind.
class CompleteProfileDraftForTest {
  const CompleteProfileDraftForTest({this.tanggal = '1990-04-17'});

  final String tanggal;

  CompleteProfileRequest get request => CompleteProfileRequest(
        nama: 'Budi Santoso',
        jenisKelamin: 'laki-laki',
        tanggalLahir: tanggal,
        noHp: '81234567890',
        alamat: 'Jl. Draft',
      );
}
