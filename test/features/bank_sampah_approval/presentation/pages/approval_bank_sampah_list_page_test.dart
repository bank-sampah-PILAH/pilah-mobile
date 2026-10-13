import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockNasabahApprovalCubit extends MockCubit<NasabahApprovalState>
    implements NasabahApprovalCubit {}

class _MemoryStorage implements AppStorage {
  final values = <String, Object>{};
  var reads = 0;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String key, dynamic value) async {
    if (failWrites) throw StateError('storage unavailable');
    values[key] = value;
  }

  @override
  Future<T?> get<T>(String key) async {
    reads++;
    if (failReads) throw StateError('storage unavailable');
    return values[key] as T?;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

void _registerStorage(AppStorage storage) {
  const name = 'shared_preferences';
  final previous = di.isRegistered<AppStorage>(instanceName: name)
      ? di<AppStorage>(instanceName: name)
      : null;
  if (previous != null) di.unregister<AppStorage>(instanceName: name);
  di.registerSingleton<AppStorage>(storage, instanceName: name);
  addTearDown(() {
    if (di.isRegistered<AppStorage>(instanceName: name)) {
      di.unregister<AppStorage>(instanceName: name);
    }
    if (previous != null) {
      di.registerSingleton<AppStorage>(previous, instanceName: name);
    }
  });
}

const _pending = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati No. 5',
  status: MembershipStatus.pending,
  isActive: true,
  totalSaldo: '999.99',
);

const _approved = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.approved,
  isActive: true,
  totalSaldo: '1234567.05',
);

const _otherApproved = NasabahMembershipEntity(
  id: 'membership-3',
  bankSampahId: 'bank-3',
  bankSampahNama: 'Bank Sampah Baru',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Baru',
  status: MembershipStatus.approved,
  isActive: true,
  totalSaldo: '50.00',
);

const _noLongerActive = NasabahMembershipEntity(
  id: 'membership-2',
  bankSampahId: 'bank-2',
  bankSampahNama: 'Bank Sampah Lestari',
  bankSampahKota: 'Jakarta',
  bankSampahAlamat: 'Jl. Sudirman No. 20',
  status: MembershipStatus.pending,
  isActive: false,
  totalSaldo: '1234567.05',
);

Widget _wrap(NasabahApprovalCubit cubit, {String? userId}) => MaterialApp(
      home: BlocProvider<NasabahApprovalCubit>.value(
        value: cubit,
        child: ApprovalBankSampahListView(userId: userId),
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
    expect(find.text('Bandung · Jl. Melati No. 5'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
    expect(find.text('Jakarta · Jl. Sudirman No. 20'), findsOneWidget);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Saldo: Rp 999,99'), findsOneWidget);
    expect(find.text('Saldo: Rp 1.234.567,05'), findsOneWidget);
    expect(find.text('Rp 1.234.567,05'), findsOneWidget);
    expect(find.byIcon(Icons.recycling), findsNWidgets(2));
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

  testWidgets('revalidates saved selection when membership status changes',
      (tester) async {
    final storage = _MemoryStorage()
      ..values['active_membership_id:user-1'] = _approved.id;
    _registerStorage(storage);
    final updates = StreamController<NasabahApprovalState>.broadcast();
    addTearDown(updates.close);
    whenListen(
      cubit,
      updates.stream,
      initialState: const NasabahApprovalLoaded([_approved, _otherApproved]),
    );

    await tester.pumpWidget(_wrap(cubit, userId: 'user-1'));
    await tester.pumpAndSettle();
    expect(find.text('Bank aktif'), findsOneWidget);

    updates.add(const NasabahApprovalLoaded([_noLongerActive, _otherApproved]));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:user-1'], _otherApproved.id);
    expect(find.text('Bank aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reuses the saved selection when eligible memberships are unchanged',
      (tester) async {
    final storage = _MemoryStorage()
      ..values['active_membership_id:user-1'] = _approved.id;
    _registerStorage(storage);
    final updates = StreamController<NasabahApprovalState>.broadcast();
    addTearDown(updates.close);
    whenListen(
      cubit,
      updates.stream,
      initialState: const NasabahApprovalLoaded([_approved, _otherApproved]),
    );

    await tester.pumpWidget(_wrap(cubit, userId: 'user-1'));
    await tester.pumpAndSettle();
    expect(storage.reads, 1);

    updates.add(const NasabahApprovalLoaded([_approved, _otherApproved]));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(storage.reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves a newly selected active membership', (tester) async {
    final storage = _MemoryStorage()
      ..values['active_membership_id:user-1'] = _approved.id;
    _registerStorage(storage);
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_approved, _otherApproved]));

    await tester.pumpWidget(_wrap(cubit, userId: 'user-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih bank'));
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:user-1'], _otherApproved.id);
    expect(find.text('Bank aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error when stored selection cannot be read',
      (tester) async {
    final storage = _MemoryStorage()..failReads = true;
    _registerStorage(storage);
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_approved]));

    await tester.pumpWidget(_wrap(cubit, userId: 'user-1'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat pilihan bank aktif. Coba lagi.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'shows an error and keeps prior choice when selection write fails',
      (tester) async {
    final storage = _MemoryStorage()
      ..values['active_membership_id:user-1'] = _approved.id
      ..failWrites = true;
    _registerStorage(storage);
    when(() => cubit.state)
        .thenReturn(const NasabahApprovalLoaded([_approved, _otherApproved]));

    await tester.pumpWidget(_wrap(cubit, userId: 'user-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih bank'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal menyimpan pilihan bank aktif. Coba lagi.'),
        findsOneWidget);
    expect(storage.values['active_membership_id:user-1'], _approved.id);
    expect(find.text('Bank aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
