import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

Color? _circleColor(WidgetTester tester, Finder inside) {
  final decorated = tester.widget<Container>(
    find
        .ancestor(of: inside, matching: find.byType(Container))
        .first,
  );
  return (decorated.decoration! as BoxDecoration).color;
}

void main() {
  group('OnboardingHeader', () {
    testWidgets('shows the title and subtitle on the green banner',
        (tester) async {
      await _pump(
        tester,
        OnboardingHeader(
          title: 'Lengkapi Profil Anda',
          subtitle: 'Data ini digunakan untuk verifikasi.',
          onExit: () {},
        ),
      );

      expect(find.text('Lengkapi Profil Anda'), findsOneWidget);
      expect(find.text('Data ini digunakan untuk verifikasi.'), findsOneWidget);
      final banner = tester.widget<Container>(find.byType(Container).first);
      expect((banner.decoration! as BoxDecoration).color, AppColors.greenDark);
    });

    testWidgets('the logout button calls onExit', (tester) async {
      var exited = 0;
      await _pump(
        tester,
        OnboardingHeader(title: 'T', subtitle: 'S', onExit: () => exited++),
      );

      await tester.tap(find.byTooltip('Keluar'));

      expect(exited, 1);
    });
  });

  group('OnboardingStepper', () {
    testWidgets('step one is current: its number shows, step two is greyed',
        (tester) async {
      await _pump(
        tester,
        const OnboardingStepper(
          currentStep: 1,
          secondStepLabel: 'Pilih Bank Sampah',
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('Profil Diri'), findsOneWidget);
      expect(find.text('Pilih Bank Sampah'), findsOneWidget);
      expect(_circleColor(tester, find.text('1')), AppColors.greenDark);
      expect(_circleColor(tester, find.text('2')), AppColors.fill);
    });

    testWidgets('step two is current: step one shows a check mark',
        (tester) async {
      await _pump(
        tester,
        const OnboardingStepper(
          currentStep: 2,
          secondStepLabel: 'Data Bank Sampah',
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.text('Data Bank Sampah'), findsOneWidget);
      expect(_circleColor(tester, find.text('2')), AppColors.greenDark);
    });
  });

  group('OnboardingFormField', () {
    testWidgets('puts a required label above the field', (tester) async {
      await _pump(
        tester,
        const OnboardingFormField(
          label: 'NAMA LENGKAP',
          child: TextField(key: Key('field')),
        ),
      );

      expect(
        find.textContaining('NAMA LENGKAP', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('*', findRichText: true), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('field'))).dy,
        greaterThan(
          tester
              .getBottomLeft(find.textContaining('NAMA LENGKAP',
                  findRichText: true))
              .dy,
        ),
      );
    });

    testWidgets('shows the description between label and field',
        (tester) async {
      await _pump(
        tester,
        const OnboardingFormField(
          label: 'BANK SAMPAH',
          description: 'Tempat Anda menabung',
          child: SizedBox(key: Key('field'), height: 10),
        ),
      );

      expect(find.text('Tempat Anda menabung'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Tempat Anda menabung')).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('field'))).dy),
      );
    });

    testWidgets('has no description line when none is given', (tester) async {
      await _pump(
        tester,
        const OnboardingFormField(label: 'X', child: SizedBox()),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('OnboardingFormCard', () {
    testWidgets('wraps its children in a form that validates them',
        (tester) async {
      final key = GlobalKey<FormState>();
      await _pump(
        tester,
        OnboardingFormCard(
          formKey: key,
          children: [
            TextFormField(validator: (_) => 'salah'),
          ],
        ),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('salah'), findsOneWidget);
    });
  });
}
