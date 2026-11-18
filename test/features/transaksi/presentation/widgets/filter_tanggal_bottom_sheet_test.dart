import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/widgets/app_calendar_range_picker.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/filter_tanggal_bottom_sheet.dart';

class _UnusedGetAktivitas implements GetAktivitasUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedExportTransaksi implements ExportTransaksiUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FilterNotifier extends RiwayatAktivitasNotifier {
  _FilterNotifier(this.initialState)
      : super(_UnusedGetAktivitas(), _UnusedExportTransaksi());

  final RiwayatAktivitasState initialState;
  DateTimeRange? appliedRange;

  @override
  RiwayatAktivitasState build() => initialState;

  @override
  void applyCustomRange(DateTime start, DateTime end) {
    appliedRange = DateTimeRange(start: start, end: end);
  }
}

void main() {
  testWidgets('normalizes and applies a reversed stored date range',
      (tester) async {
    final start = DateTime(2026, 10, 1);
    final end = DateTime(2026, 10, 4);
    late _FilterNotifier notifier;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showAdaptiveSurface<void>(
                    context,
                    builder: (_) => const FilterTanggalBottomSheet(),
                  );
                },
                child: const Text('Open filter'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        riwayatAktivitasProvider.overrideWith(() => notifier = _FilterNotifier(
              RiwayatAktivitasState(
                dariTanggal: end,
                sampaiTanggal: start,
              ),
            )),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.tap(find.text('Open filter'));
    await tester.pumpAndSettle();

    final calendar = tester.widget<AppCalendarRangePicker>(
      find.byType(AppCalendarRangePicker),
    );
    expect(calendar.initialRange, DateTimeRange(start: start, end: end));

    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(notifier.appliedRange, DateTimeRange(start: start, end: end));
    expect(find.text('Open filter'), findsOneWidget);
  });
}
