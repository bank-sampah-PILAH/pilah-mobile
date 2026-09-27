import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';

class _MockNasabahAppealCubit extends MockCubit<NasabahAppealState>
    implements NasabahAppealCubit {}

Widget _wrap(NasabahMembershipEntity membership, NasabahAppealCubit cubit) =>
    MaterialApp(
      home: BlocProvider<NasabahAppealCubit>.value(
        value: cubit,
        child: ApprovalBankSampahDetailView(membership: membership),
      ),
    );

/// A minimal two-route GoRouter (matching the style already used in
/// `approval_bank_sampah_navigation_test.dart`) so a real `context.pop(true)`
/// on appeal success can be exercised and observed by checking which route
/// is left onstage, rather than just asserting the `Navigator` popped —
/// the list page relies on that `true` result to decide whether to reload.
GoRouter _routerWithDetail(
    NasabahMembershipEntity membership, NasabahAppealCubit cubit) {
  return GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        path: '/list',
        builder: (context, state) => const Text('Daftar Approval'),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) => BlocProvider<NasabahAppealCubit>.value(
          value: cubit,
          child: ApprovalBankSampahDetailView(membership: membership),
        ),
      ),
    ],
  );
}

void main() {
  late _MockNasabahAppealCubit cubit;

  setUp(() {
    cubit = _MockNasabahAppealCubit();
    when(() => cubit.state).thenReturn(const NasabahAppealIdle());
    whenListen(cubit, const Stream<NasabahAppealState>.empty(),
        initialState: const NasabahAppealIdle());
  });

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

    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);
    expect(find.text('Ditolak'), findsWidgets);
    expect(find.text('Dokumen tidak lengkap'), findsOneWidget);
  });

  testWidgets('renders riwayat entries in the order the backend sent them',
      (tester) async {
    final membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.approved,
      isActive: true,
      // Newest-first, exactly as the backend sends riwayat_persetujuan: the
      // most recent decision (25 Sep, approved) comes before the older one
      // (20 Sep, rejected). A test fixture in chronological order wouldn't
      // catch an accidental re-sort into oldest-first.
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
    final newestDy = tester.getTopLeft(find.text('Data lengkap')).dy;
    final oldestDy = tester.getTopLeft(find.text('Dokumen tidak lengkap')).dy;
    expect(newestDy, lessThan(oldestDy));
  });

  testWidgets('renders a waiting message with no timeline for an empty riwayat',
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

    expect(find.text('Menunggu keputusan pengurus'), findsOneWidget);
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

  testWidgets('tapping the appeal button submits the bank sampah id',
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
    when(() => cubit.submit('bank-1')).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(rejected, cubit));
    await tester.tap(find.text('Ajukan Banding'));

    verify(() => cubit.submit('bank-1')).called(1);
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
    final states = StreamController<NasabahAppealState>();
    addTearDown(states.close);
    whenListen(cubit, states.stream, initialState: const NasabahAppealIdle());

    await tester.pumpWidget(_wrap(rejected, cubit));

    states.add(const NasabahAppealFailure('Bank sampah sedang tidak aktif'));
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
    final states = StreamController<NasabahAppealState>();
    addTearDown(states.close);
    whenListen(cubit, states.stream, initialState: const NasabahAppealIdle());
    final router = _routerWithDetail(rejected, cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);

    states.add(const NasabahAppealSuccess());
    await tester.pumpAndSettle();

    expect(find.text('Daftar Approval'), findsOneWidget);
    expect(find.byType(ApprovalBankSampahDetailView), findsNothing);
  });
}
