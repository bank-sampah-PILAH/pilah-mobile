import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_state.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';

/// PendingBankCard only touches the cubit when its approve/reject buttons are
/// tapped, so a bare stub is enough to render it.
class _StubSuperadminCubit extends Cubit<SuperadminState>
    implements SuperadminCubit {
  _StubSuperadminCubit() : super(SuperadminInitial());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BankSampahEntity _bank({String kota = '', String alamat = ''}) =>
    BankSampahEntity(
      id: 'b1',
      nama: 'Bank Sampah BTH',
      alamat: alamat,
      kota: kota,
      noHpPic: '+628123456789',
      fotoKegiatan: null,
      status: 'active',
      createdAt: DateTime(2026, 7, 1),
      pengelolaNama: 'Ibu Sari',
      pengelolaEmail: 'sari@example.com',
      pengelolaNoHp: '+628123456789',
    );

Future<void> _pumpCard(WidgetTester tester, BankSampahEntity bank) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: ApprovedBankCard(bank: bank)),
    ),
  ));
}

void main() {
  group('bank card location line', () {
    testWidgets('shows the city when one is on record', (tester) async {
      await _pumpCard(
          tester, _bank(kota: 'Depok', alamat: 'Jl. Melati 3, Depok'));

      expect(find.text('Depok'), findsOneWidget);
    });

    testWidgets('falls back to the address when no city is set',
        (tester) async {
      // The registration form has no city input — it asks for the city inside
      // the address — so this is what every app-registered bank looks like.
      await _pumpCard(
        tester,
        _bank(alamat: 'Jl. Melati 3, RT 04/RW 02, Kukusan, Beji, Depok'),
      );

      expect(
        find.text('Jl. Melati 3, RT 04/RW 02, Kukusan, Beji, Depok'),
        findsOneWidget,
      );
      expect(
        find.text('Kota tidak dicantumkan'),
        findsNothing,
        reason: 'the city is in the address — nothing is actually missing',
      );
    });

    testWidgets('shows no placeholder when there is genuinely no location',
        (tester) async {
      await _pumpCard(tester, _bank());

      expect(find.text('Kota tidak dicantumkan'), findsNothing);
      expect(find.text('Bank Sampah BTH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long address stays on one line and does not overflow',
        (tester) async {
      await _pumpCard(
        tester,
        _bank(
          alamat:
              'Jl. Raya Margonda No. 525 Blok A2 Lantai 3, RT 004 / RW 011, '
              'Kelurahan Kemiri Muka, Kecamatan Beji, Kota Depok, Jawa Barat 16423',
        ),
      );

      // pumpWidget surfaces a RenderFlex overflow as an exception.
      expect(tester.takeException(), isNull);
    });
  });

  group('PendingBankCard', () {
    late _StubSuperadminCubit cubit;

    setUp(() => cubit = _StubSuperadminCubit());
    tearDown(() => cubit.close());

    Future<void> pumpPending(WidgetTester tester, BankSampahEntity bank) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PendingBankCard(bank: bank, cubit: cubit),
          ),
        ),
      ));
    }

    testWidgets('carries no city line — the address row conveys the location',
        (tester) async {
      // A city IS set here: the point is that the pending card still must not
      // render it separately, because its address row already covers location.
      await pumpPending(
        tester,
        _bank(kota: 'Depok', alamat: 'Jl. Melati 3, Kukusan, Depok'),
      );

      expect(find.text('Jl. Melati 3, Kukusan, Depok'), findsOneWidget);
      expect(
        find.text('Depok'),
        findsNothing,
        reason: 'the city duplicates what the address row already says',
      );
    });

    testWidgets('shows no placeholder when no city is on record',
        (tester) async {
      await pumpPending(tester, _bank(alamat: 'Jl. Melati 3, Kukusan, Depok'));

      expect(find.text('Kota tidak dicantumkan'), findsNothing);
      expect(find.text('Jl. Melati 3, Kukusan, Depok'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
