import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart';

/// Satu tempat untuk dependensi konstruktor `NasabahCubit` yang paling baru,
/// supaya tes yang hanya perlu mengisinya tidak masing-masing mendefinisikan
/// ulang mock yang sama.
class MockSinkronProfilNasabahUseCase extends Mock
    implements SinkronProfilNasabahUseCase {}
