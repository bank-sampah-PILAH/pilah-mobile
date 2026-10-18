import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_date_picker.dart';

void main() {
  testWidgets('shows the branded Indonesian calendar and returns its date',
      (tester) async {
    DateTime? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showAppDatePicker(
              context: context,
              initialDate: DateTime(2026, 10, 14),
              firstDate: DateTime(2026, 10, 1),
              lastDate: DateTime(2026, 10, 31),
            ),
            child: const Text('Buka kalender'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Buka kalender'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    final pickerTheme = DatePickerTheme.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    expect(pickerTheme.headerBackgroundColor, AppColors.greenDark);
    expect(pickerTheme.headerForegroundColor, Colors.white);
    expect(
      pickerTheme.todayForegroundColor!.resolve(const {WidgetState.selected}),
      Colors.white,
    );
    expect(
      pickerTheme.todayBackgroundColor!.resolve(const {WidgetState.selected}),
      AppColors.greenDark,
    );
    expect(
      pickerTheme.todayForegroundColor!.resolve(const <WidgetState>{}),
      AppColors.greenDark,
    );
    expect(
      pickerTheme.todayBackgroundColor!.resolve(const <WidgetState>{}),
      AppColors.greenLight,
    );
    expect(
      pickerTheme.todayForegroundColor!.resolve(const {WidgetState.disabled}),
      AppColors.grey100,
    );
    expect(
      pickerTheme.todayBackgroundColor!.resolve(const {WidgetState.disabled}),
      isNull,
    );
    expect(
      pickerTheme.yearForegroundColor!.resolve(const {WidgetState.disabled}),
      AppColors.grey100,
    );
    expect(
      pickerTheme.yearForegroundColor!.resolve(const {WidgetState.selected}),
      Colors.white,
    );
    expect(
      pickerTheme.yearBackgroundColor!.resolve(const {WidgetState.selected}),
      AppColors.greenDark,
    );

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OKE'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 10, 20));
  });
}
