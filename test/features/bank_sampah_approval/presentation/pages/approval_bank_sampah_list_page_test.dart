import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';

class _MockNasabahApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

const _pending = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  status: MembershipStatus.pending,
  isActive: true,
);

const _approved = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  status: MembershipStatus.approved,
  isActive: true,
);

Widget _wrap(NasabahApprovalCubit cubit) => MaterialApp(
      home: BlocProvider<NasabahApprovalCubit>.value(
        value: cubit,
        child: const ApprovalBankSampahListView(),
      ),
    );

void main() {
  late _MockNasabahApprovalCubit cubit;

  setUp(() {
    cubit = _MockNasabahApprovalCubit();
  });

  testWidgets('renders one card per membership with the right status badge',
      (tester) async {
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_pending, _approved]));

    await tester.pumpWidget(_wrap(cubit));

    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
    expect(find.text('Jakarta'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
  });

  testWidgets('pulling to refresh reloads silently', (tester) async {
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_pending, _approved]));
    when(() => cubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(cubit));
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    verify(() => cubit.load(silent: true)).called(1);
  });

  testWidgets('renders EmptyView when there are no memberships',
      (tester) async {
    when(() => cubit.state).thenReturn(const NasabahApprovalLoaded([]));

    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('renders skeletons while loading', (tester) async {
    when(() => cubit.state).thenReturn(const NasabahApprovalLoading());

    await tester.pumpWidget(_wrap(cubit));
    // SkeletonListItem runs its own Timer.periodic animation loop, so settle
    // would time out waiting for it to go idle.
    await tester.pump();

    expect(find.byType(SkeletonListItem), findsWidgets);
  });

  testWidgets('renders EmptyView with the message on error', (tester) async {
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalError('Gagal memuat'));

    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Gagal memuat'), findsOneWidget);
  });
}
