import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/nasabah_verification_home.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

class _MockApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

NasabahMembershipEntity _membership(MembershipStatus status) =>
    NasabahMembershipEntity(
      id: 'membership-${status.name}',
      bankSampahId: 'bank',
      bankSampahNama: 'Bank Sampah Melati',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Melati',
      status: status,
      isActive: false,
    );

void main() {
  late _MockApprovalCubit cubit;

  setUp(() {
    cubit = _MockApprovalCubit();
    when(() => cubit.load(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
  });

  Future<void> pumpHome(WidgetTester tester, NasabahApprovalState state,
      {String name = 'Siti'}) async {
    when(() => cubit.state).thenReturn(state);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<NasabahApprovalCubit>.value(
          value: cubit,
          child: Scaffold(body: NasabahVerificationHome(name: name)),
        ),
      ),
      GoRoute(
        path: RegisterNasabahScreen.route,
        builder: (_, __) => const Scaffold(body: Text('form pengajuan')),
      ),
      GoRoute(
        path: ApprovalBankSampahDetailPage.route,
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(),
            child:
                Text('detail ${(state.extra! as NasabahMembershipEntity).id}'),
          ),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('greets the nasabah, or a generic nasabah without a name',
      (tester) async {
    await pumpHome(tester, const NasabahApprovalLoading());
    expect(find.text('Halo, Siti'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpHome(tester, const NasabahApprovalInitial(), name: '');
    expect(find.text('Halo, Nasabah'), findsOneWidget);
  });

  testWidgets('a failed status load can be retried', (tester) async {
    await pumpHome(tester, const NasabahApprovalError('Jaringan terputus'));
    expect(find.text('Status belum bisa dimuat'), findsOneWidget);
    expect(find.text('Jaringan terputus'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();

    verify(() => cubit.load()).called(1);
  });

  testWidgets('with no membership it offers to apply for one', (tester) async {
    await pumpHome(tester, const NasabahApprovalLoaded([]));
    expect(find.text('Belum ada pengajuan'), findsOneWidget);

    await tester.tap(find.text('Ajukan keanggotaan'));
    await tester.pumpAndSettle();

    expect(find.text('form pengajuan'), findsOneWidget);
  });

  testWidgets('shows a pending request first and refreshes after its detail',
      (tester) async {
    await pumpHome(
        tester,
        NasabahApprovalLoaded([
          _membership(MembershipStatus.approved),
          _membership(MembershipStatus.rejected),
          _membership(MembershipStatus.pending),
        ]));
    expect(find.text('Pengajuan sedang ditinjau'), findsOneWidget);

    await tester.ensureVisible(find.text('Lihat detail pengajuan'));
    await tester.tap(find.text('Lihat detail pengajuan'));
    await tester.pumpAndSettle();
    expect(find.text('detail membership-pending'), findsOneWidget);

    await tester.tap(find.text('detail membership-pending'));
    await tester.pumpAndSettle();

    verify(() => cubit.load(silent: true)).called(1);
  });

  testWidgets('falls back to a rejected, then to any other membership',
      (tester) async {
    await pumpHome(
        tester,
        NasabahApprovalLoaded([
          _membership(MembershipStatus.approved),
          _membership(MembershipStatus.rejected),
        ]));
    expect(find.text('Pengajuan belum disetujui'), findsOneWidget);

    await pumpHome(tester,
        NasabahApprovalLoaded([_membership(MembershipStatus.approved)]));
    expect(find.text('Keanggotaan belum aktif'), findsOneWidget);
  });

  testWidgets('pulling down reloads the status silently', (tester) async {
    await pumpHome(
        tester, NasabahApprovalLoaded([_membership(MembershipStatus.pending)]));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(() => cubit.load(silent: true)).called(1);
  });
}
