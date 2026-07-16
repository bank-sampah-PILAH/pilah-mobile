import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/app.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockNasabahCubit extends MockCubit<NasabahState> implements NasabahCubit {}

class _MockHargaCubit extends MockCubit<HargaState> implements HargaCubit {}

class _MockTransaksiCubit extends MockCubit<TransaksiState>
    implements TransaksiCubit {}

class _MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

void main() {
  late _MockNasabahCubit nasabah;
  late _MockHargaCubit harga;
  late _MockTransaksiCubit transaksi;
  late _MockDashboardCubit dashboard;

  setUp(() {
    nasabah = _MockNasabahCubit();
    harga = _MockHargaCubit();
    transaksi = _MockTransaksiCubit();
    dashboard = _MockDashboardCubit();
    when(() => nasabah.state).thenReturn(NasabahInitial());
    when(() => harga.state).thenReturn(HargaInitial());
    when(() => transaksi.state).thenReturn(TransaksiInitial());
    when(() => dashboard.state).thenReturn(const DashboardState());

    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
  });

  testWidgets(
      'resetSessionScopedState clears a pending invite token on logout (H1)',
      (tester) async {
    // A user captured an invite deep link but never redeemed it.
    di<InviteTokenStore>().save('invite-token-abc');
    expect(di<InviteTokenStore>().hasToken, isTrue);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<NasabahCubit>.value(value: nasabah),
          BlocProvider<HargaCubit>.value(value: harga),
          BlocProvider<TransaksiCubit>.value(value: transaksi),
          BlocProvider<DashboardCubit>.value(value: dashboard),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => resetSessionScopedState(context),
              child: const Text('logout'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('logout'));
    await tester.pump();

    expect(
      di<InviteTokenStore>().hasToken,
      isFalse,
      reason: 'a token from the previous account must not follow the next login',
    );
    // The existing session-cubit resets still fire — this fix is additive.
    verify(() => nasabah.reset()).called(1);
    verify(() => harga.reset()).called(1);
    verify(() => transaksi.reset()).called(1);
    verify(() => dashboard.reset()).called(1);
  });
}
