import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_flow_layout.dart';

void main() {
  for (final size in [
    const Size(375, 812),
    const Size(768, 1024),
    const Size(1440, 900),
    const Size(812, 375)
  ]) {
    testWidgets('keeps actions visible and content scrollable at $size',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var submitted = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: OnboardingFlowLayout(
          title: 'Daftarkan Bank Sampah',
          subtitle: 'Lengkapi data untuk verifikasi.',
          onExit: () {},
          progress: const OnboardingProgress(currentStep: 2),
          actions: OnboardingActions(
              primary: AppButton(
            label: 'Ajukan Pendaftaran',
            onPressed: () => submitted = true,
          )),
          child: Column(
              children: List.generate(
                  20,
                  (index) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Kolom $index'),
                      ))),
        )),
      ));
      expect(find.byKey(const ValueKey('onboarding-sidebar')),
          size.width >= 840 ? findsOneWidget : findsNothing);
      await tester.tap(find.text('Ajukan Pendaftaran'));
      expect(submitted, isTrue);
      await tester.drag(find.byKey(const ValueKey('onboarding-content-scroll')),
          const Offset(0, -2000));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.text('Kolom 19'));
      final actions =
          tester.getRect(find.byKey(const ValueKey('onboarding-actions')));
      expect(last.bottom, lessThan(actions.top));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'reflows paired fields with large text and keeps actions above the keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2),
            viewInsets: const EdgeInsets.only(bottom: 250)),
        child: child!,
      ),
      home: Scaffold(
          body: OnboardingFlowLayout(
        title: 'Lengkapi Profil Anda',
        subtitle: 'Data diri untuk verifikasi.',
        onExit: () {},
        progress: const OnboardingProgress(currentStep: 1),
        actions: OnboardingActions(
          primary: AppButton(label: 'Lanjutkan', onPressed: () {}),
          secondary: AppButton(label: 'Kembali', onPressed: () {}),
        ),
        child: const OnboardingFieldPair(
            first: Text('Jenis kelamin'), second: Text('Tanggal lahir')),
      )),
    ));
    expect(
        tester.getRect(find.text('Tanggal lahir')).top,
        greaterThanOrEqualTo(
            tester.getRect(find.text('Jenis kelamin')).bottom));
    expect(
        tester.getRect(find.byKey(const ValueKey('onboarding-actions'))).bottom,
        lessThanOrEqualTo(562));
  });
}
