import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';

import '../../../../support/auth_support.dart';

void main() {
  // Text styles built with google_fonts use these family names. Without the
  // real files the test measures with a placeholder font and any greeting
  // looks too wide.
  setUpAll(() async {
    const families = {
      'Poppins_regular': 'PoppinsRegular',
      'Poppins_600': 'PoppinsSemiBold',
      'Poppins_700': 'PoppinsBold',
    };
    for (final entry in families.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load('assets/fonts/${entry.value}.ttf'));
      await loader.load();
    }
  });

  testWidgets('a long name wraps onto a second line instead of being cut off',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<AuthenticationBloc>.value(
        value: authBlocIn(
          Authenticated(authEntity: testAuth(name: 'Pengurus PILAH E2E')),
        ),
        child: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: DashboardHeader()),
        ),
      ),
    ));

    final greeting = tester.renderObject<RenderParagraph>(
      find.textContaining('Selamat datang'),
    );
    final style = greeting.text.style!;
    final lineHeight = style.fontSize! * style.height!;
    expect((greeting.size.height / lineHeight).round(), 2);
  });

  testWidgets('the avatar is announced as a button that opens the profile',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<AuthenticationBloc>.value(
        value: authBlocIn(
          Authenticated(authEntity: testAuth(name: 'Siti Aminah')),
        ),
        child: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: DashboardHeader()),
        ),
      ),
    ));

    final avatar = find.ancestor(
      of: find.byType(CircleAvatar),
      matching: find.byType(AppTapTarget),
    );
    expect(
      tester.getSemantics(avatar),
      isSemantics(label: 'Buka profil', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
