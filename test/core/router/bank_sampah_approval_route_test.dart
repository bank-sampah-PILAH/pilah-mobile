import '../../support/stub_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/role_handoff_page.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/auth_support.dart';
import '../../support/nasabah_approval_support.dart';

class _MockAppealMembershipUseCase extends Mock
    implements AppealMembershipUseCase {}

const _first = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati No. 5',
  status: MembershipStatus.approved,
  isActive: true,
);

const _second = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.pending,
  isActive: true,
);

void main() {
  late TestNasabahApprovalNotifier approvalNotifier;

  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());

    approvalNotifier = TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalLoaded([_first, _second]),
    );

    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    // The beranda page resolves the pengumuman section from the service
    // locator, so the stub API behind it needs the same registration.
    final pengumumanApi = StubApi();
    pengumumanApi.on('GET', '/api/v1/nasabah/me/pengumuman/beranda',
        json: {'items': [], 'unread_count': 0});
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(pengumumanApi.network));
    addTearDown(() => di.unregister<NasabahPengumumanRepository>());

    final appealUseCase = _MockAppealMembershipUseCase();
    if (di.isRegistered<AppealMembershipUseCase>()) {
      di.unregister<AppealMembershipUseCase>();
    }
    di.registerFactory<AppealMembershipUseCase>(() => appealUseCase);
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    if (di.isRegistered<AppealMembershipUseCase>()) {
      di.unregister<AppealMembershipUseCase>();
    }
  });

  testWidgets(
      'nasabah dashboard entry point reaches the approval list and detail routes',
      (tester) async {
    final auth = TestAuthenticationNotifier(
      initialState: Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Ayu Lestari',
          email: 'ayu@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );

    final router = AppRouterConfig.getRouter();
    router.go(RoleHandoffPage.nasabahDashboardRoute);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nasabahApprovalProvider.overrideWith(() => approvalNotifier),
          authenticationProvider.overrideWith(() => auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Lihat Status Approval Bank Sampah'), findsOneWidget);

    await tester.tap(find.text('Lihat Status Approval Bank Sampah'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval Bank Sampah'), findsOneWidget);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);

    await tester.tap(find.text('Bank Sampah Lestari'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Persetujuan'), findsOneWidget);
    final detailPage = tester.widget<ApprovalBankSampahDetailPage>(
      find.byType(ApprovalBankSampahDetailPage),
    );
    expect(detailPage.membership.id, 'membership-2');
  });
}
