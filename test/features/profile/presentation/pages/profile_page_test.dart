import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late StubApi api;
  late ProfileCubit cubit;
  late MockImagePicker picker;
  late MockImageCropper cropper;
  late MockAuthBloc auth;

  setUpAll(() {
    registerFallbackValue(_FakeAuthEvent());
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(ImageCompressFormat.jpg);
    registerFallbackValue(const CropAspectRatio(ratioX: 1, ratioY: 1));
  });

  setUp(() {
    api = StubApi();
    stubProfile(api);
    picker = MockImagePicker();
    cropper = MockImageCropper();
    cubit = buildProfileCubit(api, picker: picker, cropper: cropper);
    auth = authBlocIn(Authenticated(authEntity: testAuth()));
  });

  tearDown(() => cubit.close());

  Future<void> openPage(WidgetTester tester, {MockAuthBloc? bloc}) async {
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: bloc ?? auth),
          BlocProvider<ProfileCubit>.value(value: cubit),
        ],
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: ProfilePage(),
      ),
      extraRoutes: ['/login'],
      size: const Size(800, 2400),
      pushed: true,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a signed-out visitor is asked to sign in', (tester) async {
    await openPage(tester, bloc: authBlocIn(Unauthenticated()));

    expect(
        find.text('Silakan masuk untuk melihat profil Anda.'), findsOneWidget);
  });

  testWidgets('shows the stored bank profile in editable fields',
      (tester) async {
    await openPage(tester);

    expect(find.text('Profil & Pengaturan'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Bank Sampah BTH'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kel. Kukusan'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, '+6281234567890'), findsOneWidget);
    expect(find.text('Simpan Pengaturan'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    api.on('GET', '/api/v1/bank-sampah/me',
        status: 500, json: <String, dynamic>{});
    await openPage(tester);
    expect(find.text('Coba Lagi'), findsOneWidget);

    stubProfile(api);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(
        find.widgetWithText(TextFormField, 'Bank Sampah BTH'), findsOneWidget);
  });

  testWidgets('validates the bank fields before saving', (tester) async {
    await openPage(tester);
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'ab');
    await tester.enterText(fields.at(1), 'pendek');
    await tester.enterText(fields.at(2), ' ');
    await tester.tap(find.text('Simpan Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama minimal 3 karakter'), findsOneWidget);
    expect(
        find.text('Alamat wajib diisi (minimal 10 karakter)'), findsOneWidget);
    expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  testWidgets('saves the bank profile and the template together',
      (tester) async {
    api.on('PUT', '/api/v1/bank-sampah/me',
        json: {...bankJson(), 'nama': 'Nama Baru'});
    api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});
    await openPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
    await tester.tap(find.text('Simpan Pengaturan'));
    await pumpToast(tester);

    expect(find.text('Pengaturan berhasil disimpan'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'PUT'), hasLength(2));
    await settleToasts(tester);
  });

  testWidgets('a rejected bank update stops before the template',
      (tester) async {
    api.on('PUT', '/api/v1/bank-sampah/me', status: 422, json: {
      'errors': {
        'no_hp_pic': ['Nomor tidak valid']
      }
    });
    await openPage(tester);

    await tester.tap(find.text('Simpan Pengaturan'));
    await pumpToast(tester);

    expect(find.text('Nomor tidak valid'), findsOneWidget);
    expect(
        api.requests
            .where((r) => r.path.contains('wa-template') && r.method == 'PUT'),
        isEmpty);
    await settleToasts(tester);
  });

  testWidgets('a rejected template is reported after the bank saved',
      (tester) async {
    api.on('PUT', '/api/v1/bank-sampah/me', json: bankJson());
    api.on('PUT', '/api/v1/pengaturan/wa-template', status: 422, json: {
      'errors': {
        'template': ['Template kosong']
      }
    });
    await openPage(tester);

    await tester.tap(find.text('Simpan Pengaturan'));
    await pumpToast(tester);

    expect(find.text('Template kosong'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('tapping a variable chip inserts it into the template',
      (tester) async {
    await openPage(tester);
    await tester.scrollUntilVisible(find.text('{Nama}'), 300,
        scrollable: find.byType(Scrollable).first);

    await tester.tap(find.text('{Nama}'));
    await tester.pump();

    expect(find.textContaining('Halo {nama}{Nama}'), findsOneWidget);
  });

  testWidgets('picking a logo shows the cropped image', (tester) async {
    final file = File('${Directory.systemTemp.path}/profile_page_logo.jpg')
      ..writeAsBytesSync(List.filled(8, 0));
    addTearDown(() => file.deleteSync());
    when(() => picker.pickImage(source: any(named: 'source')))
        .thenAnswer((_) async => XFile(file.path));
    when(() => cropper.cropImage(
          sourcePath: any(named: 'sourcePath'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          aspectRatio: any(named: 'aspectRatio'),
          compressFormat: any(named: 'compressFormat'),
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        )).thenAnswer((_) async => CroppedFile(file.path));
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedLogoFile?.path, file.path);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('an unreadable picked logo falls back to the placeholder',
      (tester) async {
    when(() => picker.pickImage(source: any(named: 'source')))
        .thenAnswer((_) async => XFile('/no/such/logo.jpg'));
    when(() => cropper.cropImage(
          sourcePath: any(named: 'sourcePath'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          aspectRatio: any(named: 'aspectRatio'),
          compressFormat: any(named: 'compressFormat'),
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        )).thenAnswer((_) async => CroppedFile('/no/such/logo.jpg'));
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('a stored logo is shown from its URL', (tester) async {
    stubProfile(api, bank: bankJson(logo: 'https://img.test/logo.png'));
    await openPage(tester);
    // The test HTTP client refuses the fetch; the placeholder takes over.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final urls = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<NetworkImage>()
        .map((n) => n.url);
    expect(urls, contains('https://img.test/logo.png'));
  });

  testWidgets('the team tab lists members and copies the invite link',
      (tester) async {
    api.on('POST', '/api/v1/team/invite',
        json: {'invite_url': 'https://pilah.test/invite/abc'});
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await openPage(tester);

    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
    expect(find.text('Siti'), findsOneWidget);
    expect(find.text('Anda'), findsOneWidget);
    expect(find.text('Pengelola Utama'), findsOneWidget);
    expect(find.text('Pengelola'), findsWidgets);
    expect(find.text('Simpan Pengaturan'), findsNothing);

    await tester.tap(find.text('Salin Link Undangan'));
    await pumpToast(tester);

    expect(copied, 'https://pilah.test/invite/abc');
    expect(find.text('Link undangan disalin ke clipboard!'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a failed invite shows the error and copies nothing',
      (tester) async {
    api.on('POST', '/api/v1/team/invite',
        status: 403, json: {'error': 'Hanya pengelola utama'});
    await openPage(tester);

    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salin Link Undangan'));
    await pumpToast(tester);

    expect(find.text('Hanya pengelola utama'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('only the primary pengelola can invite; empty roster note',
      (tester) async {
    stubProfile(api, team: {'members': []});
    await openPage(tester);

    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();

    expect(find.text('Salin Link Undangan'), findsNothing);
    expect(
        find.text('Belum ada pengelola lain yang tergabung.'), findsOneWidget);
  });

  testWidgets('a member without a name shows their email', (tester) async {
    stubProfile(api, team: {
      'members': [
        {'id': 'm9', 'nama': '', 'email': 'anon@x.test'},
      ],
    });
    await openPage(tester);

    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();

    expect(find.text('anon@x.test'), findsOneWidget);
  });

  testWidgets('logging out is requested from the settings tab', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Keluar dari Aplikasi'));
    await tester.pump();

    verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
  });

  testWidgets('leaves for the login page once signed out', (tester) async {
    final bloc = MockAuthBloc();
    whenListen(
        bloc, Stream<AuthenticationStates>.fromIterable([Unauthenticated()]),
        initialState: Authenticated(authEntity: testAuth()));

    await openPage(tester, bloc: bloc);
    await tester.pumpAndSettle();

    expect(find.text('route:/login'), findsOneWidget);
  });

  testWidgets('the back button returns to the previous page', (tester) async {
    await openPage(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('route:/'), findsOneWidget);
  });

  testWidgets('pulling the team tab refreshes the roster', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('Manajemen Tim'));
    await tester.pumpAndSettle();
    final before = api.requests.length;

    await tester.fling(find.text('Siti'), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    expect(api.requests.length, greaterThan(before));
  });

  testWidgets('pull to refresh reloads without a spinner', (tester) async {
    await openPage(tester);
    final before = api.requests.length;

    await tester.fling(find.text('Siti Aminah'), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    expect(api.requests.length, greaterThan(before));
  });
}
