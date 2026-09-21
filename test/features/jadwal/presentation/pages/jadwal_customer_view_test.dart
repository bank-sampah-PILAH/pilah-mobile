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
  testWidgets('customer schedule view is read only', (tester) async {
    final cubit = _MockJadwalCubit();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.now().add(const Duration(days: 1)),
      selesaiPada: DateTime.now().add(const Duration(days: 1, hours: 2)),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);

    await tester.tap(find.text('Balai Warga'));
    await tester.pump();
    expect(find.text('Ubah Jadwal'), findsNothing);
  });
}
