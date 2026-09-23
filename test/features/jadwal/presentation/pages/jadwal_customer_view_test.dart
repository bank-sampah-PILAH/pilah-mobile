import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  testWidgets('customer sees only published schedules in a read-only view',
      (tester) async {
    final cubit = _MockJadwalCubit();
    final schedules = [
      _schedule(
          id: 'published',
          location: 'Balai Warga',
          status: 'diterbitkan',
          isOverlapping: true),
      _schedule(id: 'draft', location: 'Draf', status: 'draft'),
      _schedule(id: 'cancelled', location: 'Dibatalkan', status: 'dibatalkan'),
      _schedule(id: 'completed', location: 'Selesai', status: 'selesai'),
    ];
    when(() => cubit.state).thenReturn(JadwalLoaded(schedules));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.text('Draf'), findsNothing);
    expect(find.text('Dibatalkan'), findsNothing);
    expect(find.text('Selesai'), findsNothing);
    expect(find.textContaining('Diterbitkan'), findsOneWidget);
    expect(find.textContaining('diterbitkan'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Tooltip &&
          widget.message == 'Jadwal bertumpuk di lokasi yang sama'),
      findsNothing,
    );

    await tester.tap(find.text('Balai Warga'));
    await tester.pump();
    expect(find.text('Ubah Jadwal'), findsNothing);
  });
}

JadwalEntity _schedule({
  required String id,
  required String location,
  required String status,
  bool isOverlapping = false,
}) =>
    JadwalEntity(
      id: id,
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: location,
      status: status,
      isOverlapping: isOverlapping,
    );
