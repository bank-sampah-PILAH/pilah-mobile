import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

import 'support/app_shell_support.dart';
import 'support/stub_api.dart';

/// Runs the real [App] over the stubbed API. The app resolves its cubits from
/// the service locator, so the shell's instances are registered there.
void main() {
  late AppShell shell;
  late StubApi api;

  setUp(() async {
    api = StubApi();
    shell = AppShell(api);
    await shell.registerDi();
    di.registerFactory<NasabahCubit>(() => shell.nasabah);
    di.registerFactory<HargaCubit>(() => shell.harga);
    di.registerFactory<JadwalCubit>(() => shell.jadwal);
    di.registerFactory<TransaksiCubit>(() => shell.transaksi);
    di.registerFactory<DashboardCubit>(() => shell.dashboard);
    di.registerFactory<RecentActivityCubit>(() => shell.recent);
    di.registerFactory<RiwayatAktivitasCubit>(() => shell.riwayat);
    di.registerFactory<ProfileCubit>(() => shell.profile);
    di.registerFactory<AuthenticationBloc>(() => shell.auth);
    di.registerFactory<OnboardingCubit>(() => shell.onboarding);
  });

  tearDown(() async {
    AppRouterConfig.getRouter().go('/login');
    await di.unregister<NasabahCubit>();
    await di.unregister<HargaCubit>();
    await di.unregister<JadwalCubit>();
    await di.unregister<TransaksiCubit>();
    await di.unregister<DashboardCubit>();
    await di.unregister<RecentActivityCubit>();
    await di.unregister<RiwayatAktivitasCubit>();
    await di.unregister<ProfileCubit>();
    await di.unregister<AuthenticationBloc>();
    await di.unregister<OnboardingCubit>();
    await shell.unregisterDi();
  });

  /// Starts the app on its splash and lets the restored session in [shell.auth]
  /// route it, as the session check does at cold start.
  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App());
    // Unmount first: the providers close their cubits on disposal, which only
    // completes once their listeners are gone.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pump(const Duration(seconds: 1));
    shell.states.add(shell.auth.state);
    await tester.pumpAndSettle();
  }

  String location() =>
      AppRouterConfig.getRouter().routerDelegate.currentConfiguration.uri.path;

  testWidgets(
      'starts the router and lands a signed-in pengelola on the '
      'dashboard', (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);

    expect(location(), '/dashboard');
    expect(find.text('Flutter Pilah Mobile'), findsNothing);
  });

  testWidgets('a rejected session resets the cubits that outlive it',
      (tester) async {
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    await boot(tester);
    shell.onboarding.saveProfileDraft(const CompleteProfileRequest(
      nama: 'Sari Dewi',
      jenisKelamin: 'perempuan',
      tanggalLahir: '1990-04-17',
      noHp: '81234567890',
    ));
    expect(shell.onboarding.hasProfileDraft, isTrue);

    shell.states.add(Unauthenticated());
    await tester.pumpAndSettle();

    expect(shell.onboarding.hasProfileDraft, isFalse);
  });

  group('coming back to the foreground', () {
    Future<void> resume(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    // Resumes without settling, so a slow invite gate stays on screen.
    Future<void> resumeAndPump(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Lets the held-back invite answer arrive so no timer outlives the test.
    Future<void> drainSlowInvite(WidgetTester tester) async {
      api.latency = null;
      await tester.pump(const Duration(hours: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('sends a pengelola holding an unredeemed invite to redeem it',
        (tester) async {
      api.latency = const Duration(hours: 1);
      shell.signedInAsRole('pengelola', step: 'dashboard');
      await boot(tester);
      expect(location(), '/dashboard');

      shell.invites.save('invite-token');
      await resumeAndPump(tester);

      expect(
        api.requests.where((r) => r.path.endsWith('/invites/accept')),
        hasLength(1),
      );
      await drainSlowInvite(tester);
    });

    testWidgets('stays put when it is already on the invite target',
        (tester) async {
      // A slow answer keeps the invite gate on screen, so the second resume
      // finds the app already where the invite belongs.
      api.latency = const Duration(hours: 1);
      shell.signedInAsRole('pengelola', step: 'dashboard');
      await boot(tester);
      shell.invites.save('invite-token');
      await resumeAndPump(tester);
      expect(location(), '/invite-processing');

      shell.invites.save('invite-token');
      await resumeAndPump(tester);

      expect(location(), '/invite-processing');
      await drainSlowInvite(tester);
    });

    testWidgets('does nothing without a banked token', (tester) async {
      shell.signedInAsRole('pengelola', step: 'dashboard');
      await boot(tester);

      await resume(tester);

      expect(location(), '/dashboard');
    });

    testWidgets('does nothing while signed out', (tester) async {
      shell.signedInAs(Unauthenticated());
      await boot(tester);
      final before = location();
      shell.invites.save('invite-token');

      await resume(tester);

      expect(location(), before);
      expect(shell.invites.hasToken, isTrue);
    });

    testWidgets('discards a token the account can never redeem',
        (tester) async {
      shell.signedInAsRole('nasabah', step: 'nasabah_dashboard');
      await boot(tester);
      shell.invites.save('invite-token');

      await resume(tester);

      expect(shell.invites.hasToken, isFalse);
    });

    testWidgets('ignores lifecycle changes other than resuming',
        (tester) async {
      shell.signedInAsRole('pengelola', step: 'dashboard');
      await boot(tester);
      shell.invites.save('invite-token');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(location(), '/dashboard');
    });
  });
}
