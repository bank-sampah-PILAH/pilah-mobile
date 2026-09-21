import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

class _FakeRegisterNasabahRequest extends Fake
    implements RegisterNasabahRequest {}

const _bank = BankSampahDirectoryEntity(
  id: 'bank-1',
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  kota: 'Depok',
  fotoLogo: '',
);

const _request = RegisterNasabahRequest(bankSampahId: 'bank-1');

DioException _refusal(String message, {int status = 400}) => DioException(
      requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
        statusCode: status,
        data: {'error': message},
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeRegisterNasabahRequest()));

  late _MockDataSource dataSource;
  late OnboardingCubit cubit;

  setUp(() {
    dataSource = _MockDataSource();
    cubit = OnboardingCubit(dataSource);
  });

  tearDown(() => cubit.close());

  group('loadBankSampahDirectory', () {
    test('returns the banks the data source lists', () async {
      when(() => dataSource.listBankSampahDirectory())
          .thenAnswer((_) async => [_bank]);

      final (:result, :error) = await cubit.loadBankSampahDirectory();

      expect(error, isNull);
      expect(result, [_bank]);
    });

    test('surfaces a network failure instead of throwing', () async {
      // Rejected future, not a synchronous throw: apiCall receives the
      // future already evaluated, so a throw during the mock call itself
      // would sail past its try/catch rather than exercise it.
      when(() => dataSource.listBankSampahDirectory()).thenAnswer(
          (_) async => throw _refusal('Gagal memuat daftar bank sampah'));

      final (:result, :error) = await cubit.loadBankSampahDirectory();

      expect(result, isNull);
      expect(error?.displayMessage, 'Gagal memuat daftar bank sampah');
    });
  });

  group('registerNasabah', () {
    test('sends the request and returns the next step', () async {
      when(() => dataSource.registerNasabah(_request)).thenAnswer(
          (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'));

      final (:result, :error) = await cubit.registerNasabah(_request);

      expect(error, isNull);
      expect(result?.nextStep, 'nasabah_dashboard');
      verify(() => dataSource.registerNasabah(_request)).called(1);
    });

    test('surfaces the backend refusal', () async {
      when(() => dataSource.registerNasabah(_request)).thenAnswer((_) async =>
          throw _refusal(
              'Anda sudah terdaftar sebagai nasabah di bank sampah ini'));

      final (:result, :error) = await cubit.registerNasabah(_request);

      expect(result, isNull);
      expect(error?.displayMessage,
          'Anda sudah terdaftar sebagai nasabah di bank sampah ini');
    });
  });
}
