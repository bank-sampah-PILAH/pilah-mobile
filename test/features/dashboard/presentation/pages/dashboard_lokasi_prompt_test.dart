import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unnecessary_import
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/dashboard_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  late StubApi api;
  late DashboardNotifier dashboard;
  late TestProfileNotifier profile;

  /// ProviderScope overrides shared by every pump below. The dashboard loads
  /// on open, its analytics report goes to a fake client, and the lokasi
  /// prompt reads the bank through [profile].
  void arrange({Map<String, dynamic>? bank}) {
    api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: const {});
    api.on('GET', '/api/v1/bank-sampah/me', json: bank ?? bankJson());
    dashboard = buildDashboardNotifier(api);
    profile = buildProfileNotifier(api);
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(() => dashboard),
          recentActivityProvider.overrideWith(
            () => _IdleActivityNotifier(_UnusedGetTransaksi(), _UnusedPencairan()),
          ),
          profileProvider.overrideWith(() => profile),
          authenticationProvider.overrideWith(
            () => authNotifierIn(Authenticated(authEntity: testAuth())),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    // The post-frame callback fires the loads, resolves the prompt's
    // ensureBank() read, and (if any) animates the sheet in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'a bank without coordinates gets the completion prompt once, on open',
      (tester) async {
    arrange();
    await pumpPage(tester);

    expect(find.text('Lengkapi lokasi bank sampah'), findsOneWidget);
    // It fired exactly one bank-sampah/me read — the prompt's own lookup —
    // not duplicate one-off fetches per open.
    expect(
      api.requests.where((r) => r.path == '/api/v1/bank-sampah/me').length,
      1,
    );
  });

  testWidgets('a bank that already has coordinates is never prompted',
      (tester) async {
    arrange(bank: bankJson(latitude: '-6.362829', longitude: '106.828655'));
    await pumpPage(tester);

    expect(find.text('Lengkapi lokasi bank sampah'), findsNothing);
  });

  testWidgets('dismissing with Nanti leaves it gone for this session',
      (tester) async {
    arrange();
    await pumpPage(tester);
    expect(find.text('Lengkapi lokasi bank sampah'), findsOneWidget);

    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();

    expect(find.text('Lengkapi lokasi bank sampah'), findsNothing);
  });

  testWidgets('a failed bank lookup means no prompt and no error surface',
      (tester) async {
    arrange();
    api.fail('GET', '/api/v1/bank-sampah/me');
    await pumpPage(tester);

    expect(find.text('Lengkapi lokasi bank sampah'), findsNothing);
  });
}



class _UnusedGetTransaksi extends Mock implements GetTransaksiUseCase {}

class _UnusedPencairan extends Mock implements PencairanUseCases {}

class _IdleActivityNotifier extends RecentActivityNotifier {
  _IdleActivityNotifier(super.getTransaksiUseCase, super.pencairanUseCases);

  @override
  RecentActivityState build() => const RecentActivityLoaded([]);

  @override
  Future<void> load({bool silent = false}) async {}
}
