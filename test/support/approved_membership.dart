import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _ApprovedMembershipCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

NasabahApprovalCubit registerApprovedMembership() {
  final cubit = _ApprovedMembershipCubit();
  whenListen(cubit, const Stream<NasabahApprovalState>.empty(),
      initialState: const NasabahApprovalLoaded([
        NasabahMembershipEntity(
          id: 'membership',
          bankSampahId: 'bank',
          bankSampahNama: 'Bank Sampah Melati',
          bankSampahKota: 'Bandung',
          bankSampahAlamat: 'Jl. Melati',
          status: MembershipStatus.approved,
          isActive: true,
        ),
      ]));
  when(() => cubit.load(silent: any(named: 'silent'))).thenAnswer((_) async {});
  di.registerFactory<NasabahApprovalCubit>(() => cubit);
  return cubit;
}

Future<void> unregisterApprovedMembership(NasabahApprovalCubit cubit) async {
  await di.unregister<NasabahApprovalCubit>();
  await cubit.close();
}
