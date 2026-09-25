import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_paged_list_view.dart';

class _MockGetNasabahUseCase extends Mock implements GetNasabahUseCase {}

class _MockGetActiveNasabahUseCase extends Mock
    implements GetActiveNasabahUseCase {}

class _MockGetNasabahRingkasanUseCase extends Mock
    implements GetNasabahRingkasanUseCase {}

class _MockAddNasabahUseCase extends Mock implements AddNasabahUseCase {}

class _MockUpdateNasabahUseCase extends Mock implements UpdateNasabahUseCase {}

class _MockActivateNasabahUseCase extends Mock
    implements ActivateNasabahUseCase {}

class _MockDeactivateNasabahUseCase extends Mock
    implements DeactivateNasabahUseCase {}

class _MockApproveNasabahUseCase extends Mock
    implements ApproveNasabahUseCase {}

class _MockRejectNasabahUseCase extends Mock implements RejectNasabahUseCase {}

NasabahEntity _nasabah(int nomor) => NasabahEntity(
      id: 'n-$nomor',
      idNasabah: 'NAS-${nomor.toString().padLeft(4, '0')}',
      name: 'Nasabah $nomor',
      phone: '08123456789',
      balance: 'Rp 0',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NN',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

void main() {
  late _MockGetNasabahUseCase getUseCase;
  late NasabahCubit cubit;

  setUp(() {
    getUseCase = _MockGetNasabahUseCase();
    cubit = NasabahCubit(
      getUseCase,
      _MockGetActiveNasabahUseCase(),
      _MockGetNasabahRingkasanUseCase(),
      _MockAddNasabahUseCase(),
      _MockUpdateNasabahUseCase(),
      _MockActivateNasabahUseCase(),
      _MockDeactivateNasabahUseCase(),
      _MockApproveNasabahUseCase(),
      _MockRejectNasabahUseCase(),
    );
  });

  tearDown(() => cubit.close());

  Widget host() => MaterialApp(
        home: BlocProvider<NasabahCubit>.value(
          value: cubit,
          child: const NasabahPage(),
        ),
      );

  testWidgets('renders the paged list and forwards the load-more request',
      (tester) async {
    when(() => getUseCase.execute(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as GetNasabahParams;
      return Right(_halaman(params.page));
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(NasabahPagedListView), findsOneWidget);
    expect(find.text('Nasabah 1'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    // Halaman kedua diminta lewat callback milik halaman, bukan oleh widget
    // daftar sendiri, jadi ini menguji sambungannya.
    final params = verify(() => getUseCase.execute(captureAny()))
        .captured
        .cast<GetNasabahParams>();
    expect(params.map((p) => p.page), contains(2));
    expect(find.text('Nasabah 21'), findsOneWidget);
  });
}

/// Halaman berisi 20 baris; halaman pertama masih menyisakan halaman lanjutan.
HalamanNasabah _halaman(int halaman) {
  final mulai = (halaman - 1) * 20 + 1;
  return HalamanNasabah(
    items: [for (var i = mulai; i < mulai + 20; i++) _nasabah(i)],
    totalCount: 40,
    hasMore: halaman < 2,
  );
}
