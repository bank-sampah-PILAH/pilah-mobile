import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _MockJadwalCubit extends MockCubit<JadwalState>
    implements JadwalCubit {}

void main() {
  testWidgets('draft schedule can be published from the management list',
      (tester) async {
    final cubit = _MockJadwalCubit();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.now().add(const Duration(days: 1)),
      selesaiPada: DateTime.now().add(const Duration(days: 1, hours: 2)),
      lokasi: 'Balai Warga',
    );
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});
    when(() => cubit.changeStatus(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Terbitkan'), findsOneWidget);
    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    verify(() => cubit.changeStatus('jadwal-1', 'terbitkan')).called(1);
  });
}
