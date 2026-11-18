import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_appeal_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';

class _MockAppealMembershipUseCase extends Mock
    implements AppealMembershipUseCase {}

Widget _wrap(
  NasabahMembershipEntity membership,
  AppealMembershipUseCase useCase,
) =>
    ProviderScope(
      overrides: [
        nasabahAppealProvider.overrideWith(
          () => NasabahAppealNotifier(useCase),
        ),
      ],
      child: MaterialApp(
        home: ApprovalBankSampahDetailView(membership: membership),
      ),
    );

/// A minimal two-route GoRouter (matching the style already used in
/// `approval_bank_sampah_navigation_test.dart`) so a real `context.pop(true)`
/// on appeal success can be exercised and observed by checking which route
/// is left onstage, rather than just asserting the `Navigator` popped —
/// the list page relies on that `true` result to decide whether to reload.
GoRouter _routerWithDetail(
    NasabahMembershipEntity membership, AppealMembershipUseCase useCase) {
  return GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        path: '/list',
        builder: (context, state) => const Text('Daftar Approval'),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) => ProviderScope(
          overrides: [
            nasabahAppealProvider.overrideWith(
              () => NasabahAppealNotifier(useCase),
            ),
          ],
          child: ApprovalBankSampahDetailView(membership: membership),
        ),
      ),
    ],
  );
}

void main() {
  late _MockAppealMembershipUseCase cubit;

  setUp(() => cubit = _MockAppealMembershipUseCase());

  testWidgets('shows current status and the rejection reason when rejected',
      (tester) async {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(membership, cubit));

    // Once in the app bar, once on the bank sampah card — matching the list
    // card's identity display (icon, name, kota · alamat).
    expect(find.text('Bank Sampah Sejahtera'), findsNWidgets(2));
    expect(find.byIcon(Icons.recycling), findsOneWidget);
    expect(find.text('Bandung · Jl. Merdeka No. 10'), findsOneWidget);
    expect(find.text('Ditolak'), findsWidgets);
    expect(find.text('Dokumen tidak lengkap'), findsOneWidget);
  });

  testWidgets('renders riwayat chronologically after the submitted step',
      (tester) async {
    final membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.approved,
      isActive: true,
      // The API sends newest-first; the timeline should read top-to-bottom in
      // chronological order for a clear application history.
      riwayat: [
        ApprovalLogEntity(
          status: ApprovalLogStatus.approved,
          catatan: 'Data lengkap',
          createdAt: DateTime(2026, 9, 25, 8),
        ),
        ApprovalLogEntity(
          status: ApprovalLogStatus.rejected,
          catatan: 'Dokumen tidak lengkap',
          createdAt: DateTime(2026, 9, 20, 10),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(membership, cubit));

    expect(find.text('Data lengkap'), findsOneWidget);
    expect(find.text('Dokumen tidak lengkap'), findsOneWidget);
    expect(find.text('Pengajuan dikirim'), findsOneWidget);
    expect(find.text('Keanggotaan disetujui'), findsNothing,
        reason: 'the final decision already appears in the approval history');
    final newestDy = tester.getTopLeft(find.text('Data lengkap')).dy;
    final oldestDy = tester.getTopLeft(find.text('Dokumen tidak lengkap')).dy;
    expect(oldestDy, lessThan(newestDy));
  });

  testWidgets('shows submitted and current waiting steps for a new application',
      (tester) async {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.pending,
      isActive: true,
    );

    await tester.pumpWidget(_wrap(membership, cubit));

    expect(find.text('Pengajuan dikirim'), findsOneWidget);
    expect(find.text('Menunggu verifikasi pengurus'), findsOneWidget);
  });

  testWidgets('long decision notes fit a 375px phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka',
      status: MembershipStatus.pending,
      isActive: true,
      riwayat: [
        ApprovalLogEntity(
          status: ApprovalLogStatus.appealed,
          catatan:
              'Dokumen dan alamat sudah saya perbaiki untuk pengajuan ulang.',
          createdAt: DateTime(2026, 9, 25, 8),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(membership, cubit));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the appeal button only when the membership is rejected',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(rejected, cubit));

    expect(find.text('Ajukan Banding'), findsOneWidget);
  });

  testWidgets('hides the appeal button while pending', (tester) async {
    const pending = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.pending,
      isActive: true,
    );

    await tester.pumpWidget(_wrap(pending, cubit));

    expect(find.text('Ajukan Banding'), findsNothing);
  });

  testWidgets('hides the appeal button once approved', (tester) async {
    const approved = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.approved,
      isActive: true,
    );

    await tester.pumpWidget(_wrap(approved, cubit));

    expect(find.text('Ajukan Banding'), findsNothing);
  });

  testWidgets('offers a show-more toggle for a long rejection reason',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan:
          'Dokumen kartu tanda penduduk yang Anda unggah sebelumnya buram '
          'dan tidak terbaca, mohon diunggah ulang dengan foto yang lebih '
          'jelas dan resolusi tinggi agar dapat kami verifikasi.',
    );

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.pump();

    expect(find.text('Lihat Selengkapnya'), findsOneWidget);
  });

  testWidgets(
      'appears above the Riwayat Persetujuan section when the membership is rejected',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(rejected, cubit));

    final buttonDy = tester.getTopLeft(find.text('Ajukan Banding')).dy;
    final historyHeadingDy =
        tester.getTopLeft(find.text('Riwayat Persetujuan')).dy;
    expect(buttonDy, lessThan(historyHeadingDy));
  });

  testWidgets('tapping the appeal button opens a dialog asking for a message',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.tap(find.text('Ajukan Banding'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Kirim'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('submits the entered message when the dialog is confirmed',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );
    final response = Completer<Either<NetworkException, void>>();
    when(() => cubit.execute(const AppealMembershipParams(
        bankSampahId: 'bank-1',
        pesan: 'Dokumen sudah lengkap'))).thenAnswer((_) => response.future);

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.tap(find.text('Ajukan Banding'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dokumen sudah lengkap');
    await tester.tap(find.text('Kirim'));
    await tester.pump();

    verify(() => cubit.execute(const AppealMembershipParams(
        bankSampahId: 'bank-1', pesan: 'Dokumen sudah lengkap'))).called(1);
    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(const Right(null));
    await tester.pump();
  });

  testWidgets('does not submit when the dialog is cancelled', (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.tap(find.text('Ajukan Banding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.execute(any()));
  });

  testWidgets('shows an error toast without popping when the appeal fails',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );
    when(() => cubit.execute(any())).thenAnswer(
      (_) async =>
          Left(NetworkException(message: 'Bank sampah sedang tidak aktif')),
    );

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.tap(find.text('Ajukan Banding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim'));
    await tester.pump();
    // The toast's entrance animation needs real pumped time, not just a
    // frame — matches app_notification_test.dart's `_raise` helper.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ApprovalBankSampahDetailView), findsOneWidget);
    expect(find.text('Gagal Mengajukan Banding'), findsOneWidget);
    expect(find.text('Bank sampah sedang tidak aktif'), findsOneWidget);

    // Runs the toast's auto-dismiss timer out so none is left pending.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('pops back to the previous route when the appeal succeeds',
      (tester) async {
    const rejected = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );
    when(() => cubit.execute(any())).thenAnswer((_) async => const Right(null));
    final router = _routerWithDetail(rejected, cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('Bank Sampah Sejahtera'), findsNWidgets(2));

    await tester.tap(find.text('Ajukan Banding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval'), findsOneWidget);
    expect(find.byType(ApprovalBankSampahDetailView), findsNothing);
  });
}
