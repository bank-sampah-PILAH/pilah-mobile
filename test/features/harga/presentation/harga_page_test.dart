import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';

class _MockHargaCubit extends MockCubit<HargaState> implements HargaCubit {}

HargaEntity _jenis(String id, {HargaTerjadwal? terjadwal}) => HargaEntity(
      id: id,
      kodeSampah: id,
      name: 'Jenis $id',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'plastik',
      subtitle: '',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
      hargaTerjadwal: terjadwal,
    );

void main() {
  testWidgets('the price list shows an upcoming price change', (tester) async {
    final cubit = _MockHargaCubit();
    addTearDown(cubit.close);
    when(() => cubit.loadHarga()).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(HargaLoaded(jenisSampahList: [
      _jenis(
        'PLS-001',
        terjadwal: HargaTerjadwal(
          harga: 5000,
          berlakuMulai: DateTime(2026, 10, 15),
        ),
      ),
      _jenis('KRT-001'),
    ]));

    await tester.pumpWidget(
      BlocProvider<HargaCubit>.value(
        value: cubit,
        child: const MaterialApp(home: HargaPage()),
      ),
    );

    expect(find.text('Rp 5.000 mulai 15 Oktober 2026'), findsOneWidget);
    expect(find.textContaining('mulai'), findsOneWidget);
  });
}
