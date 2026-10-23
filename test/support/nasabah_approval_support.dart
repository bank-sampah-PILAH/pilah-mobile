import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';

class TestNasabahApprovalNotifier extends NasabahApprovalNotifier {
  TestNasabahApprovalNotifier({
    required this.initialState,
    GetNasabahMembershipsUseCase? useCase,
  }) : super(useCase ?? _staticUseCase(_memberships(initialState)));

  final NasabahApprovalState initialState;
  final loadCalls = <bool>[];

  @override
  NasabahApprovalState build() => initialState;

  @override
  Future<void> load({bool silent = false}) {
    loadCalls.add(silent);
    return super.load(silent: silent);
  }

  void setStateForTest(NasabahApprovalState next) => state = next;
}

List<NasabahMembershipEntity> _memberships(NasabahApprovalState state) =>
    state is NasabahApprovalLoaded ? state.memberships : const [];

GetNasabahMembershipsUseCase _staticUseCase(
    List<NasabahMembershipEntity> memberships) {
  final useCase = _StaticMembershipsUseCase();
  when(() => useCase.execute()).thenAnswer((_) async => Right(memberships));
  return useCase;
}

class _StaticMembershipsUseCase extends Mock
    implements GetNasabahMembershipsUseCase {}
