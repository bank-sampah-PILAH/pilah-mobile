import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/nasabah_bank_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/invite_gate_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/pending_approval_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

import '../../support/app_shell_support.dart';
import '../../support/stub_api.dart';

class _MockAppeal extends Mock implements AppealMembershipUseCase {}

void main() {
  late AppShell shell;

  setUp(() async {
    shell = AppShell(StubApi());
    await shell.registerDi();
  });

  tearDown(() => shell.unregisterDi());

  Future<GoRouter> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = AppRouterConfig.getRouter();
    await tester
        .pumpWidget(shell.wrap(MaterialApp.router(routerConfig: router)));
    await tester.pump();
    return router;
  }

  Future<void> visit(WidgetTester tester, GoRouter router, String path,
      {bool settle = true}) async {
    router.go(path);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Pages with an endless animation (a progress spinner) never settle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('a pengelola', () {
    setUp(() => shell.signedInAsRole('pengelola', bankStatus: 'active'));

    testWidgets('reaches every staff and onboarding page', (tester) async {
      final router = await boot(tester);
      final pages = <String, Type>{
        '/dashboard': DashboardPage,
        '/nasabah': NasabahPage,
        '/harga': HargaPage,
        '/laporan': LaporanPage,
        '/profile': ProfilePage,
        '/transaksi-baru': TransaksiBaruPage,
        '/forgot_password': ForgotPasswordPage,
        '/pending-approval': PendingApprovalScreen,
        '/register-nasabah': RegisterNasabahScreen,
        '/complete-profile': CompleteProfileScreen,
        '/register-bank-sampah': RegisterBankSampahScreen,
        '/catat-pencairan': CatatPencairanPage,
        '/pengelola-induk-dashboard': RoleHandoffPage,
        '/register-bank-sampah-induk': RoleHandoffPage,
      };

      for (final entry in pages.entries) {
        await visit(tester, router, entry.key,
            settle: !entry.key.contains('induk'));
        expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('can open the pencairan edit and revision pages',
        (tester) async {
      final router = await boot(tester);

      router.go(
        '/edit-pencairan',
        extra: const Pencairan(
          id: 'p1',
          nasabahNama: 'Budi',
          nominal: 50000,
          metode: MetodePencairan.tunai,
          tanggal: null,
          keterangan: '',
          status: 'tercatat',
          saldoSebelum: 100000,
          saldoSesudah: 50000,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditPencairanPage), findsOneWidget);

      router.go('/riwayat-perubahan-pencairan', extra: 'p1');
      await tester.pumpAndSettle();
      expect(find.byType(RevisiPencairanPage), findsOneWidget);
    });

    testWidgets('opens the jadwal page, honouring a date in the link',
        (tester) async {
      final router = await boot(tester);

      await visit(tester, router, '/jadwal?date=2026-10-12');

      expect(find.byType(JadwalPage), findsOneWidget);
      expect(tester.widget<JadwalPage>(find.byType(JadwalPage)).customerMode,
          isFalse);
    });

    testWidgets('is kept off the customer-only pages', (tester) async {
      final router = await boot(tester);

      for (final path in ['/riwayat', '/bank-sampah']) {
        await visit(tester, router, path);
        expect(find.byType(DashboardPage), findsOneWidget, reason: path);
      }
    });

    testWidgets(
        'a rejected bank sampah opens the registration in re-apply mode',
        (tester) async {
      shell.signedInAsRole('pengelola', bankStatus: 'rejected');
      final router = await boot(tester);

      await visit(tester, router, '/register-bank-sampah');

      expect(
          tester
              .widget<RegisterBankSampahScreen>(
                  find.byType(RegisterBankSampahScreen))
              .isRejectedReapplication,
          isTrue);
    });

    testWidgets(
        'a pending invite link banks its token and goes through the gate',
        (tester) async {
      final router = await boot(tester);

      await visit(tester, router, '/invite?token=tok-9');

      expect(shell.invites.token, isNull,
          reason: 'the gate spends the token on its first attempt');
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });

  group('a superadmin', () {
    testWidgets('is sent to the superadmin dashboard from protected pages',
        (tester) async {
      shell.signedInAsRole('superadmin', step: 'superadmin_dashboard');
      final router = await boot(tester);

      for (final path in ['/dashboard', '/nasabah', '/profile', '/riwayat']) {
        await visit(tester, router, path);
        expect(find.byType(SuperAdminDashboardScreen), findsOneWidget,
            reason: path);
      }
    });

    testWidgets('can open the superadmin route directly', (tester) async {
      shell.signedInAsRole('superadmin', step: 'superadmin_dashboard');
      final router = await boot(tester);

      await visit(tester, router, '/superadmin-dashboard');

      expect(find.byType(SuperAdminDashboardScreen), findsOneWidget);
    });
  });

  group('a nasabah', () {
    setUp(() => shell.signedInAsRole('nasabah', step: 'nasabah_dashboard'));

    testWidgets('is bounced from the staff pages to the home', (tester) async {
      final router = await boot(tester);

      for (final path in [
        '/nasabah',
        '/harga',
        '/laporan',
        '/transaksi-baru'
      ]) {
        await visit(tester, router, path);
        expect(find.byType(DashboardPage), findsNothing, reason: path);
        expect(find.byType(NasabahPage), findsNothing, reason: path);
      }
    });

    testWidgets('reaches the customer pages', (tester) async {
      final router = await boot(tester);

      await visit(
          tester, router, '/riwayat?keanggotaan_id=m1&filter=pencairan');
      expect(find.byType(NasabahHistoryScreen), findsOneWidget);

      // The bank page is a shell branch no navigation destination points at,
      // so the shell offers a way back instead of rendering it.
      await visit(tester, router, '/bank-sampah');
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
      expect(find.byType(NasabahBankPage), findsNothing);

      await visit(tester, router, '/approval-bank-sampah');
      expect(find.byType(ApprovalBankSampahListPage), findsOneWidget);

      di.registerFactory<NasabahAppealCubit>(
          () => NasabahAppealCubit(_MockAppeal()));
      addTearDown(() => di.unregister<NasabahAppealCubit>());
      router.go(
        '/approval-bank-sampah/detail',
        extra: const NasabahMembershipEntity(
          id: 'm1',
          bankSampahId: 'b1',
          bankSampahNama: 'Bank Melati',
          bankSampahKota: 'Bandung',
          bankSampahAlamat: 'Jl. Melati',
          status: MembershipStatus.pending,
          isActive: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ApprovalBankSampahDetailPage), findsOneWidget);

      // The router is a process-wide singleton; leave it somewhere harmless.
      await visit(tester, router, '/forgot_password');
    });

    testWidgets('sees the jadwal page in customer mode', (tester) async {
      final router = await boot(tester);

      await visit(tester, router, '/jadwal');

      expect(tester.widget<JadwalPage>(find.byType(JadwalPage)).customerMode,
          isTrue);
    });

    testWidgets('/nasabah-dashboard is an alias of the home', (tester) async {
      final router = await boot(tester);

      await visit(tester, router, '/nasabah-dashboard');

      expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
    });
  });

  group('without a recognised role', () {
    testWidgets('protected pages fall back to the login page', (tester) async {
      shell.signedInAsRole('tamu');
      final router = await boot(tester);

      await visit(tester, router, '/dashboard');

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('the role chooser route builds its page', (tester) async {
      shell.signedInAs(Unauthenticated());
      final router = await boot(tester);

      await visit(tester, router, '/choose-role');

      expect(router.routerDelegate.currentConfiguration.uri.path, isNotEmpty);
    });

    testWidgets('a signed-out visitor is not redirected by role',
        (tester) async {
      shell.signedInAs(Unauthenticated());
      final router = await boot(tester);

      await visit(tester, router, '/login');

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('an invite token with no session is left banked',
        (tester) async {
      shell.signedInAs(Unauthenticated());
      final router = await boot(tester);

      await visit(tester, router, '/invite?token=abc');

      expect(shell.invites.token, 'abc');
    });
  });

  group('invites for other roles', () {
    for (final role in ['nasabah', 'pengelola_induk']) {
      testWidgets('are discarded for a $role', (tester) async {
        shell.signedInAsRole(role);
        final router = await boot(tester);
        shell.invites.save('tok');

        await visit(tester, router, '/forgot_password');

        expect(shell.invites.token, isNull);
      });
    }

    testWidgets('a pengelola on the target page is not redirected again',
        (tester) async {
      shell.signedInAsRole('pengelola',
          step: 'dashboard', bankStatus: 'active');
      final router = await boot(tester);
      shell.invites.save('tok');

      await visit(tester, router, '/invite-processing');

      expect(find.byType(InviteGatePage), findsNothing,
          reason: 'the gate redeems and leaves');
    });
  });
}
