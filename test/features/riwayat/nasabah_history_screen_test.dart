import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../support/auth_support.dart';
import '../../support/pencairan_support.dart';
import '../../support/stub_api.dart';

/// Serves the balance card through [NasabahRepository] — the contract the
/// screen's saldo column reads directly.
class _Repository extends PreviewNasabahRepository {
  _Repository({this.updatedAt});

  final DateTime? updatedAt;

  @override
  Future<NasabahBalance> balance(String membershipId) async =>
      NasabahBalance('12500.50', updatedAt);
}

/// The setoran tab now loads through [RiwayatHistoryCubit], so the fake
/// rides behind the same repository the cubit consumes in production.
class _RiwayatRepository implements RiwayatRepository {
  final detailRequests = <(String, String)>[];

  @override
  Future<Either<NetworkException, RiwayatHistory>> history(
    String membershipId, {
    int page = 1,
  }) async =>
      Right(NasabahHistory([
        NasabahActivity('t1', DateTime(2026, 9, 23), 'setoran', '5000.00'),
      ], false));

  @override
  Future<Either<NetworkException, RiwayatSetoranDetail>> setoranDetail(
    String membershipId,
    String transactionId,
  ) async {
    detailRequests.add((membershipId, transactionId));
    return Right(
      NasabahSetoranDetail(
        date: DateTime(2026, 9, 23),
        type: 'setoran',
        amount: '5000.00',
        note: 'Setoran rutin',
        balanceAfter: '12500.50',
        items: const [
          NasabahSetoranItem(
              name: 'Plastik PET',
              weight: '1.000',
              price: '5000.00',
              subtotal: '5000.00'),
        ],
      ),
    );
  }
}

void main() {
  late _RiwayatRepository riwayatRepository;

  Future<void> pumpScreen(WidgetTester tester, _Repository repo) async {
    riwayatRepository = _RiwayatRepository();
    di.registerSingleton<NasabahRepository>(repo);
    di.registerFactory<RiwayatRepository>(() => riwayatRepository);
    di.registerFactory<RiwayatHistoryCubit>(() => RiwayatHistoryCubit(
          GetRiwayatHistoryUseCase(riwayatRepository),
          GetRiwayatSetoranDetailUseCase(riwayatRepository),
        ));
    di.registerFactory<RiwayatPencairanCubit>(
        () => RiwayatPencairanCubit(buildPencairanUseCases(StubApi())));
    addTearDown(() async {
      await di.unregister<NasabahRepository>();
      await di.unregister<RiwayatRepository>();
      await di.unregister<RiwayatHistoryCubit>();
      await di.unregister<RiwayatPencairanCubit>();
    });
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<AuthenticationBloc>.value(
        value: authBlocIn(Authenticated(authEntity: testAuth(role: 'nasabah'))),
        child: const NasabahHistoryScreen(membershipId: 'm1'),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows when the balance was last updated', (tester) async {
    await pumpScreen(tester, _Repository(updatedAt: DateTime(2026, 9, 20, 9)));

    expect(find.text('Diperbarui 20/09/2026'), findsOneWidget);
  });

  testWidgets('says "Saldo saat ini" when no update time is known',
      (tester) async {
    await pumpScreen(tester, _Repository());

    expect(find.text('Saldo saat ini'), findsOneWidget);
  });

  testWidgets('opening a setoran loads its detail for this membership',
      (tester) async {
    await pumpScreen(tester, _Repository());

    await tester.tap(find.textContaining('5.000'));
    await tester.pumpAndSettle();

    expect(riwayatRepository.detailRequests, [('m1', 't1')]);
    expect(find.text('Plastik PET'), findsOneWidget);
  });
}
