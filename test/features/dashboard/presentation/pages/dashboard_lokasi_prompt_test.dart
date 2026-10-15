import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/dashboard_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/stub_api.dart';

class _ActivityCubit extends MockCubit<RecentActivityState>
    implements RecentActivityCubit {}

void main() {
  late StubApi api;
  late DashboardCubit dashboard;
  late _ActivityCubit activity;
  late ProfileCubit profile;

  void arrange({Map<String, dynamic>? bank}) {
    api = StubApi();
    api.on('GET', '/api/v1/dashboard/stats', json: const {});
    api.on('GET', '/api/v1/bank-sampah/me', json: bank ?? bankJson());
    dashboard = buildDashboardCubit(api);
    addTearDown(dashboard.close);
    activity = _ActivityCubit();
    whenListen(activity, const Stream<RecentActivityState>.empty(),
        initialState: RecentActivityLoaded(const []));
    when(() => activity.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
    profile = buildProfileCubit(api);
    addTearDown(profile.close);
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: activity),
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<AuthenticationBloc>(
            create: (_) => authBlocIn(
              Authenticated(authEntity: testAuth()),
            ),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    // initState fires the cubits, the post-frame callback resolves
    // ensureBank()'s GET, and the prompt (if any) animates in.
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
