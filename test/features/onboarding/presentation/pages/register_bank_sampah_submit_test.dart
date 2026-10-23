import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/image_picker_channel.dart';
import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _draft = CompleteProfileRequest(
  nama: 'Siti',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1998-05-17',
  noHp: '81234567890',
);

void main() {
  late StubApi api;
  late ProviderContainer onboarding;
  late TestAuthenticationNotifier auth;

  setUp(() {
    api = StubApi();
    onboarding = buildOnboardingContainer(buildOnboardingDataSource(api));
    auth = authNotifierIn(AuthenticationInitial());
  });

  tearDown(() => onboarding.dispose());

  Future<void> open(WidgetTester tester,
      {bool pushed = false, TestAuthenticationNotifier? authNotifier}) async {
    await pumpRouted(
      tester,
      UncontrolledProviderScope(
        container: onboarding,
        child: withAuthenticationProvider(
          authNotifier ?? auth,
          // A non-const instance so the constructor itself runs.
          // ignore: prefer_const_constructors
          RegisterBankSampahScreen(),
        ),
      ),
      extraRoutes: [
        '/login',
        '/dashboard',
        '/pending-approval',
        '/complete-profile'
      ],
      size: const Size(800, 2600),
      pushed: pushed,
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester,
      {String nama = 'Bank Melati',
      String alamat = 'Jl. Melati No. 1',
      String hp = '81234567890',
      bool withPhoto = true}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), nama);
    await tester.enterText(fields.at(1), alamat);
    await tester.enterText(fields.at(2), hp);
    if (withPhoto) {
      await tester.ensureVisible(find.text('Pilih foto'));
      await tester.tap(find.text('Pilih foto'));
      await pumpReal(tester);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('an empty form flags every field including the photo',
      (tester) async {
    await open(tester);

    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    expect(find.text('Nama minimal 3 karakter'), findsOneWidget);
    expect(find.text('Alamat wajib diisi'), findsOneWidget);
    expect(find.text('Nomor Telepon wajib diisi'), findsOneWidget);
    expect(find.text('Foto kegiatan wajib diunggah'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a malformed phone number is rejected', (tester) async {
    mockImagePicker(writeTinyPng('bank_a.png').path);
    await open(tester);

    await fillForm(tester, hp: '12345');
    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await tester.pumpAndSettle();

    expect(find.text('Format nomor tidak valid.'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a valid form registers and waits for review', (tester) async {
    final calls = mockImagePicker(writeTinyPng('bank_b.png').path);
    api.on('POST', '/api/v1/onboarding/bank-sampah',
        json: {'next_step': 'approval_pending'});
    await open(tester);

    await fillForm(tester);
    expect(calls.single.arguments['imageQuality'], 50);
    final preview = tester.widget<Image>(find.byType(Image));
    expect(preview.image, isA<MemoryImage>());
    expect((preview.image as MemoryImage).bytes, tinyPng);
    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await pumpReal(tester);
    await tester.pumpAndSettle();

    expect(api.last.path, '/api/v1/onboarding/bank-sampah');
    expect(auth.calls, contains('refreshUser'));
    expect(find.text('route:/pending-approval'), findsOneWidget);
  });

  testWidgets('an already-active account goes to the dashboard',
      (tester) async {
    mockImagePicker(writeTinyPng('bank_c.png').path);
    api.on('POST', '/api/v1/onboarding/bank-sampah',
        json: {'next_step': 'dashboard'});
    await open(tester);

    await fillForm(tester);
    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await pumpReal(tester);
    await tester.pumpAndSettle();

    expect(find.text('route:/dashboard'), findsOneWidget);
  });

  testWidgets('a server rejection keeps the photo and allows retry',
      (tester) async {
    mockImagePicker(writeTinyPng('bank_d.png').path);
    api.on('POST', '/api/v1/onboarding/bank-sampah',
        status: 413, json: {'error': 'Foto terlalu besar'});
    await open(tester);

    await fillForm(tester);
    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await pumpReal(tester);
    await pumpToast(tester);

    expect(find.text('Foto terlalu besar'), findsOneWidget);
    expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        tinyPng);
    await settleToasts(tester);

    api.on('POST', '/api/v1/onboarding/bank-sampah',
        json: {'next_step': 'pending_approval'});
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await pumpReal(tester);
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(2));
    expect(find.text('route:/pending-approval'), findsOneWidget);
  });

  testWidgets('an unreadable photo shows an error and can be replaced',
      (tester) async {
    final missing = writeTinyPng('unreadable_bank_photo.png')..deleteSync();
    mockImagePicker(missing.path);
    await open(tester);

    await fillForm(tester, withPhoto: false);
    await tester.ensureVisible(find.text('Pilih foto'));
    await tester.tap(find.text('Pilih foto'));
    await pumpReal(tester);
    await pumpToast(tester);

    expect(find.text('Foto tidak dapat dibaca. Silakan coba lagi.'),
        findsOneWidget);
    expect(find.text('Pilih foto'), findsOneWidget);
    expect(api.requests, isEmpty);
    await settleToasts(tester);

    mockImagePicker(writeTinyPng('replacement_bank_photo.png').path);
    await fillForm(tester);

    expect(find.text('Pilih foto'), findsNothing);
    expect(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
        tinyPng);
  });

  testWidgets('the banked profile is sent first when coming from step one',
      (tester) async {
    mockImagePicker(writeTinyPng('bank_e.png').path);
    onboarding.read(onboardingProvider.notifier).saveProfileDraft(_draft);
    api.on('PUT', '/api/v1/onboarding/profile', json: {});
    api.on('POST', '/api/v1/onboarding/bank-sampah',
        json: {'next_step': 'approval_pending'});
    await open(tester);

    await fillForm(tester);
    await tester.ensureVisible(find.text('Ajukan Pendaftaran'));
    await tester.tap(find.text('Ajukan Pendaftaran'));
    await pumpReal(tester);
    await tester.pumpAndSettle();

    expect(api.requests.map((r) => r.method), ['PUT', 'POST']);
  });

  testWidgets('a cancelled pick leaves the photo empty', (tester) async {
    mockImagePicker(null);
    await open(tester);

    await fillForm(tester);

    expect(find.text('Pilih foto'), findsOneWidget);
  });

  testWidgets('a picked photo can be removed again', (tester) async {
    mockImagePicker(writeTinyPng('bank_f.png').path);
    await open(tester);
    await fillForm(tester);
    expect(find.text('Pilih foto'), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.close));
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byIcon(Icons.close)),
      isSemantics(label: 'Hapus foto', isButton: true, hasTapAction: true),
    );
    handle.dispose();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Pilih foto'), findsOneWidget);
    expect(find.text('Foto kegiatan wajib diunggah'), findsOneWidget);
  });

  testWidgets('the header logout asks before leaving', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari Pendaftaran?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(auth.calls, isNot(contains('logout')));

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Keluar'));
    await tester.pumpAndSettle();
    expect(auth.calls, contains('logout'));
  });

  testWidgets('system back when reached directly asks before leaving',
      (tester) async {
    await open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari Pendaftaran?'), findsOneWidget);
  });

  testWidgets('Kembali mid-wizard returns to the profile screen',
      (tester) async {
    onboarding.read(onboardingProvider.notifier).saveProfileDraft(_draft);
    await open(tester, pushed: true);

    await tester.ensureVisible(find.text('Kembali'));
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('route:/'), findsOneWidget);
  });

  testWidgets('system back mid-wizard pops to the profile screen',
      (tester) async {
    onboarding.read(onboardingProvider.notifier).saveProfileDraft(_draft);
    await open(tester, pushed: true);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('route:/'), findsOneWidget);
  });

  testWidgets(
      'system back mid-wizard with nothing to pop goes to the profile form',
      (tester) async {
    onboarding.read(onboardingProvider.notifier).saveProfileDraft(_draft);
    await open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('route:/complete-profile'), findsOneWidget);
  });

  testWidgets('signing out routes to the login page', (tester) async {
    final signedOut = authNotifierIn(AuthenticationInitial());

    await open(tester, authNotifier: signedOut);
    signedOut.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('route:/login'), findsOneWidget);
  });
}
