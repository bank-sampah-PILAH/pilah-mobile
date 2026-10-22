import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';

class UnusedJadwalRepository extends Fake implements JadwalRepository {}

class TestJadwalNotifier extends JadwalNotifier {
  TestJadwalNotifier({
    required JadwalRepository repository,
    required JadwalState initialState,
    this.onLoadJadwal,
    this.onLoadCalendarDates,
    this.onLoadUpcomingDates,
    this.onLoadNextPage,
    this.onChangeStatus,
    this.onSaveJadwal,
  })  : _initialState = initialState,
        super(repository);

  final JadwalState _initialState;
  final Future<void> Function({
    bool silent,
    DateTime? date,
    DateTime? dateTo,
  })? onLoadJadwal;
  final Future<void> Function({
    required DateTime startDate,
    required DateTime endDate,
  })? onLoadCalendarDates;
  final Future<void> Function({DateTime? today})? onLoadUpcomingDates;
  final Future<void> Function()? onLoadNextPage;
  final Future<NetworkException?> Function(String id, String action)?
      onChangeStatus;
  final Future<NetworkException?> Function(JadwalEntity schedule)? onSaveJadwal;

  @override
  JadwalState build() => _initialState;

  @override
  Future<void> loadJadwal({
    bool silent = false,
    DateTime? date,
    DateTime? dateTo,
  }) async {
    await onLoadJadwal?.call(silent: silent, date: date, dateTo: dateTo);
  }

  @override
  Future<void> loadCalendarDates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await onLoadCalendarDates?.call(startDate: startDate, endDate: endDate);
  }

  @override
  Future<void> loadUpcomingDates({DateTime? today}) async {
    await onLoadUpcomingDates?.call(today: today);
  }

  @override
  Future<void> loadNextPage() async => onLoadNextPage?.call();

  @override
  Future<NetworkException?> changeStatus(String id, String action) async =>
      onChangeStatus?.call(id, action);

  @override
  Future<NetworkException?> saveJadwal(JadwalEntity schedule) async =>
      onSaveJadwal?.call(schedule);
}
