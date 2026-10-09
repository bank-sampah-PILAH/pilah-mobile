import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_history_screen.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../support/auth_support.dart';
import '../../support/pencairan_support.dart';
import '../../support/stub_api.dart';

class _Repository extends PreviewNasabahRepository {
  _Repository({this.updatedAt});

  final DateTime? updatedAt;
  final detailRequests = <(String, String)>[];

  @override
  Future<NasabahBalance> balance(String membershipId) async =>
      NasabahBalance('12500.50', updatedAt);

  @override
  Future<NasabahHistory> history(String membershipId, {int page = 1}) async =>
      NasabahHistory([
        NasabahActivity('t1', DateTime(2026, 9, 23), 'setoran', '5000.00'),
      ], false);

  @override
  Future<NasabahSetoranDetail> setoranDetail(
      String membershipId, String transactionId) async {
    detailRequests.add((membershipId, transactionId));
    return NasabahSetoranDetail(
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
    );
  }
}

void main() {
  late _Repository repository;

  Future<void> pumpScreen(WidgetTester tester, _Repository repo) async {
    repository = repo;
    di.registerSingleton<NasabahRepository>(repository);
    di.registerFactory<RiwayatPencairanCubit>(
        () => RiwayatPencairanCubit(buildPencairanUseCases(StubApi())));
    addTearDown(() async {
      await di.unregister<NasabahRepository>();
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

    expect(repository.detailRequests, [('m1', 't1')]);
    expect(find.text('Plastik PET'), findsOneWidget);
  });
}
