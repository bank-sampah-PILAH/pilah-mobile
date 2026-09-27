import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
