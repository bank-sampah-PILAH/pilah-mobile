import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/image_picker_channel.dart';
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

  Future<void> openPage(
    WidgetTester tester, {
    MockAuthBloc? bloc,
    Size size = const Size(800, 2400),
    bool? isWeb,
  }) async {
    await pumpRouted(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: bloc ?? auth),
          BlocProvider<ProfileCubit>.value(value: cubit),
        ],
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: ProfilePage(isWeb: isWeb),
      ),
      extraRoutes: ['/login'],
      size: size,
      pushed: true,
    );
    await tester.pumpAndSettle();
  }

  group('in the web shell', () {
    testWidgets('there is no back button: the rail is the way out',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      expect(find.byType(AppBackHeader), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('Profil & Pengaturan'), findsOneWidget);
    });

    testWidgets('the page keeps the content width and the web gutter',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      // (1440 - 1200) / 2 of margin plus the 32 gutter.
      const left = 120.0 + 32;
      expect(tester.getTopLeft(find.text('Profil & Pengaturan')).dx, left);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Bank Sampah BTH'), 'Bank Baru');
      await tester.pumpAndSettle();
      final save =
          tester.getRect(find.widgetWithText(AppButton, 'Simpan Pengaturan'));
      expect(save.right, 1440 - left,
          reason: 'the action bar stops at the content edge too');
    });

    testWidgets('the settings scroll across the window, content in a column',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      final scroll = find.ancestor(
        of: find.text('PROFIL BANK SAMPAH'),
        matching: find.byType(SingleChildScrollView),
      );
      expect(tester.getSize(scroll.first).width, 1440,
          reason: 'so the scrollbar is at the window edge');
      // Inside the card that starts at the column's left edge (120 + 32).
      expect(tester.getTopLeft(find.text('PROFIL BANK SAMPAH')).dx,
          closeTo(120.0 + 32, 16));
    });

    testWidgets('Keluar sits in the account card, small, above the settings',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      final keluar = find.widgetWithText(AppButton, 'Keluar dari Aplikasi');
      expect(keluar, findsOneWidget, reason: 'only one, not also at the end');
      expect(tester.getTopLeft(keluar).dy,
          lessThan(tester.getTopLeft(find.text('PROFIL BANK SAMPAH')).dy));
      expect(tester.getTopLeft(keluar).dx,
          greaterThan(tester.getTopRight(find.text('siti@example.test')).dx),
          reason: 'to the right of the identity');
      expect(tester.getSize(keluar).width, lessThan(300));
    });

    testWidgets('Keluar still asks first and signs out on confirm',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      final keluar = find.widgetWithText(AppButton, 'Keluar dari Aplikasi');
      await tester.ensureVisible(keluar);
      await tester.pumpAndSettle();
      await tester.tap(keluar);
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsOneWidget);

      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();
      verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
    });

    testWidgets('Simpan is hidden until something changes, then right aligned',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);
      final save = find.widgetWithText(AppButton, 'Simpan Pengaturan');

      expect(save, findsNothing, reason: 'nothing has changed yet');
      expect(find.text('Perubahan belum disimpan'), findsNothing);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Bank Sampah BTH'), 'Bank Baru');
      await tester.pumpAndSettle();

      expect(save, findsOneWidget);
      expect(find.text('Perubahan belum disimpan'), findsOneWidget);
      expect(tester.getRect(save).right, 120.0 + 1200 - 32);
      expect(tester.getSize(save).width, lessThan(400));
    });

    testWidgets('changing a field back leaves nothing to save', (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);
      final field = find.widgetWithText(TextFormField, 'Bank Sampah BTH');

      await tester.enterText(field, 'Bank Baru');
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Bank Baru'), 'Bank Sampah BTH');
      await tester.pumpAndSettle();

      expect(find.text('Perubahan belum disimpan'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Simpan Pengaturan'), findsNothing);
    });

    testWidgets('the tabs sit at the left, not spread over the page',
        (tester) async {
      await openPage(tester, size: const Size(1440, 900), isWeb: true);

      expect(tester.getTopLeft(find.text('Pengaturan Umum')).dx, lessThan(400));
      expect(tester.getTopLeft(find.text('Manajemen Tim')).dx, lessThan(600));
    });

    testWidgets('a phone-sized app still has its back header', (tester) async {
      await openPage(tester, size: const Size(390, 844), isWeb: false);

      expect(find.byType(AppBackHeader), findsOneWidget);
    });
  });

  testWidgets('a signed-out visitor is asked to sign in', (tester) async {
    await openPage(tester, bloc: authBlocIn(Unauthenticated()));

    expect(
        find.text('Silakan masuk untuk melihat profil Anda.'), findsOneWidget);
  });

  testWidgets('shows the stored bank profile in editable fields',
      (tester) async {
    await openPage(tester);

    expect(find.widgetWithText(AppBackHeader, 'Profil & Pengaturan'),
        findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Bank Sampah BTH'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kel. Kukusan'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, '+6281234567890'), findsOneWidget);
    expect(find.text('Simpan Pengaturan'), findsNothing,
        reason: 'nothing to save until a field changes');
  });

  testWidgets('shows the signed-in account email in the profile',
      (tester) async {
    await openPage(tester);

    expect(find.text('siti@example.test'), findsOneWidget);
  });

  group('on a phone', () {
    testWidgets('Keluar is the last thing on the page, full width',
        (tester) async {
      await openPage(tester, size: const Size(390, 844), isWeb: false);

      final keluar = find.widgetWithText(AppButton, 'Keluar dari Aplikasi');
      expect(keluar, findsOneWidget);
      expect(
          tester.getTopLeft(keluar).dy,
          greaterThan(
              tester.getBottomLeft(find.text('TEMPLATE NOTIFIKASI WA')).dy));
      expect(tester.getSize(keluar).width, greaterThan(300));
    });

    testWidgets('Simpan is hidden until something changes', (tester) async {
      await openPage(tester, size: const Size(390, 844), isWeb: false);
      final save = find.widgetWithText(AppButton, 'Simpan Pengaturan');

      expect(save, findsNothing);
      expect(find.text('Perubahan belum disimpan'), findsNothing);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Bank Sampah BTH'), 'Bank Baru');
      await tester.pumpAndSettle();

      expect(save, findsOneWidget);
      expect(find.text('Perubahan belum disimpan'), findsOneWidget);
      expect(tester.getSize(save).width, greaterThan(300),
          reason: 'full width on a phone');
    });

    testWidgets('the account card is white like the web one', (tester) async {
      await openPage(tester, size: const Size(390, 844), isWeb: false);

      final behindEmail = find.ancestor(
        of: find.text('siti@example.test'),
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == AppColors.greenDark),
      );
      expect(behindEmail, findsNothing);
    });
  });

  testWidgets('desktop places bank settings beside the WhatsApp template',
      (tester) async {
    await openPage(tester, size: const Size(1440, 900));

    final bankSection = tester.getTopLeft(find.text('PROFIL BANK SAMPAH'));
    final waSection = tester.getTopLeft(find.text('TEMPLATE NOTIFIKASI WA'));

    expect(waSection.dx, greaterThan(bankSection.dx));
  });

  testWidgets('mobile stacks bank settings above the WhatsApp template',
      (tester) async {
    await openPage(tester, size: const Size(390, 844));

    final bankSection = tester.getTopLeft(find.text('PROFIL BANK SAMPAH'));
    final waSection = tester.getTopLeft(find.text('TEMPLATE NOTIFIKASI WA'));

    expect(waSection.dx, bankSection.dx);
    expect(waSection.dy, greaterThan(bankSection.dy));
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
    await tester.pump();
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

    // Simpan waits for a change.
    await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
    await tester.pump();
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

    // Simpan waits for a change.
    await tester.enterText(find.byType(TextFormField).at(0), 'Nama Baru');
    await tester.pump();
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
      ..writeAsBytesSync(tinyPng);
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
    await pumpReal(tester);
    await tester.pumpAndSettle();

    expect(cubit.state.selectedLogoBytes, tinyPng);
    expect(cubit.state.selectedLogoFilename, 'profile_page_logo.jpg');
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('an unreadable picked logo reports a recoverable error',
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
    await pumpReal(tester);
    await pumpToast(tester);

    expect(find.text('Foto tidak dapat dibaca. Silakan coba lagi.'),
        findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(cubit.state.selectedLogoBytes, isNull);
    await settleToasts(tester);
  });

  testWidgets('a picker failure keeps the previously selected logo',
      (tester) async {
    await openPage(tester);
    final bytes = Uint8List.fromList(tinyPng);
    cubit.emit(cubit.state.copyWith(
        selectedLogoBytes: bytes, selectedLogoFilename: 'previous.png'));
    await tester.pumpAndSettle();
    when(() => picker.pickImage(source: any(named: 'source')))
        .thenThrow(StateError('picker unavailable'));

    await tester.tap(find.byType(ClipOval));
    await pumpToast(tester);

    expect(find.text('Foto tidak dapat dibaca. Silakan coba lagi.'),
        findsOneWidget);
    expect(cubit.state.selectedLogoBytes, bytes);
    expect(cubit.state.selectedLogoFilename, 'previous.png');
    final preview =
        tester.widget<ClipOval>(find.byType(ClipOval)).child as Image;
    expect((preview.image as MemoryImage).bytes, bytes);
    await settleToasts(tester);
  });

  testWidgets('previews a browser-selected logo from its bytes',
      (tester) async {
    await openPage(tester);
    expect(cubit.state.status.toString(), 'ProfileStatus.loaded');
    cubit.emit(cubit.state.copyWith(
      selectedLogoBytes: Uint8List.fromList(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+b3ioAAAAASUVORK5CYII=')),
      selectedLogoFilename: 'bank-logo.png',
    ));
    expect(cubit.state.selectedLogoBytes, isNotNull);
    await tester.pumpAndSettle();

    expect(cubit.state.selectedLogoBytes, isNotNull);
    expect(
      tester.widget<ClipOval>(find.byType(ClipOval)).child,
      isA<Image>(),
    );
  });

  testWidgets('a browser logo decode error uses the placeholder',
      (tester) async {
    await openPage(tester);
    cubit.emit(cubit.state.copyWith(
      selectedLogoBytes: Uint8List.fromList(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+b3ioAAAAASUVORK5CYII=')),
      selectedLogoFilename: 'bank-logo.png',
    ));
    expect(cubit.state.selectedLogoBytes, isNotNull);
    await tester.pumpAndSettle();

    final logo = tester.widget<ClipOval>(find.byType(ClipOval)).child as Image;
    expect(logo.image, isA<MemoryImage>());
    final fallback = logo.errorBuilder!(
      tester.element(find.byType(ClipOval)),
      StateError('invalid logo bytes'),
      StackTrace.current,
    );
    expect(fallback, isA<Center>());
    final placeholder = fallback as Center;
    expect(placeholder.child, isA<Icon>());
    expect((placeholder.child as Icon).icon, Icons.home_outlined);
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
    expect(find.text('Pengurus Utama'), findsOneWidget);
    expect(find.text('Pengurus'), findsWidgets);
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
        find.text('Belum ada pengurus lain yang tergabung.'), findsOneWidget);
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

  testWidgets('a bank sampah operator is labelled Pengurus, not Pengelola',
      (tester) async {
    await openPage(tester);

    expect(find.text('Pengurus'), findsOneWidget);
    expect(find.text('Pengelola'), findsNothing);
  });

  testWidgets('logging out asks first, then signs out on confirm',
      (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Keluar dari Aplikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun?'), findsOneWidget);
    verifyNever(() => auth.add(any(that: isA<LogoutRequested>())));

    await tester.tap(find.text('Ya, Keluar'));
    await tester.pumpAndSettle();

    verify(() => auth.add(any(that: isA<LogoutRequested>()))).called(1);
  });

  testWidgets('cancelling the logout keeps the session', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Keluar dari Aplikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => auth.add(any(that: isA<LogoutRequested>())));
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
