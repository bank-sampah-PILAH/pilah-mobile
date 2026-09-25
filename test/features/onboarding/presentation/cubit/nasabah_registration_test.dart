import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

class _FakeRegisterNasabahRequest extends Fake
    implements RegisterNasabahRequest {}

class _FakeCompleteProfileRequest extends Fake
    implements CompleteProfileRequest {}

const _bank = BankSampahDirectoryEntity(
  id: 'bank-1',
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  kota: 'Depok',
  fotoLogo: '',
);

const _request = RegisterNasabahRequest(bankSampahId: 'bank-1');

const _draft = CompleteProfileRequest(
  nama: 'Nasabah PILAH',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1998-05-20',
  noHp: '81234567890',
  alamat: 'Jl. Melati No. 5',
);

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
  setUpAll(() {
    registerFallbackValue(_FakeRegisterNasabahRequest());
    registerFallbackValue(_FakeCompleteProfileRequest());
  });

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

  group('loadMyMemberships', () {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah BTH',
      bankSampahKota: 'Depok',
      status: 'approved',
      isActive: true,
    );

    test('returns the memberships the data source lists', () async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => [membership]);

      final (:result, :error) = await cubit.loadMyMemberships();

      expect(error, isNull);
      expect(result, [membership]);
    });

    test('surfaces a network failure instead of throwing', () async {
      when(() => dataSource.listMyMemberships())
          .thenAnswer((_) async => throw _refusal('Gagal memuat keanggotaan'));

      final (:result, :error) = await cubit.loadMyMemberships();

      expect(result, isNull);
      expect(error?.displayMessage, 'Gagal memuat keanggotaan');
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

  group('submitNasabahRegistration', () {
    void stubProfile({Object? throws}) {
      when(() => dataSource.completeProfile(any())).thenAnswer((_) async {
        if (throws != null) throw throws;
        return const OnboardingResult(nextStep: 'register_nasabah');
      });
    }

    void stubRegister({Object? throws}) {
      when(() => dataSource.registerNasabah(any())).thenAnswer((_) async {
        if (throws != null) throw throws;
        return const OnboardingResult(nextStep: 'nasabah_dashboard');
      });
    }

    test('sends the banked profile before the membership application',
        () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister();

      await cubit.submitNasabahRegistration(_request);

      verifyInOrder([
        () => dataSource.completeProfile(_draft),
        () => dataSource.registerNasabah(_request),
      ]);
    });

    test('sends only the membership application when no draft was banked',
        () async {
      stubProfile();
      stubRegister();

      final (:result, :error) = await cubit.submitNasabahRegistration(_request);

      verifyNever(() => dataSource.completeProfile(any()));
      verify(() => dataSource.registerNasabah(_request)).called(1);
      expect(error, isNull);
      expect(result?.nextStep, 'nasabah_dashboard');
    });

    test('stops at a failed profile rather than registering a bank sampah',
        () async {
      cubit.saveProfileDraft(_draft);
      stubProfile(throws: _refusal('Alamat wajib diisi'));
      stubRegister();

      final (:result, :error) = await cubit.submitNasabahRegistration(_request);

      expect(error?.displayMessage, 'Alamat wajib diisi');
      expect(result, isNull);
      verifyNever(() => dataSource.registerNasabah(any()));
      expect(
        cubit.hasProfileDraft,
        isTrue,
        reason: 'the draft is the form contents; dropping it on a failure the '
            'user can fix would empty the screen they need to correct',
      );
    });

    test(
        'skips the membership application when completing the profile '
        'already reaches nasabah_dashboard', () async {
      // A pengurus-entered record matching the account's verified email
      // auto-links on login (AuthService._sync_nasabah_prefill), so
      // completing the profile alone can already finish onboarding.
      // Calling registerNasabah afterwards would fail with "already
      // registered" since the membership already exists.
      cubit.saveProfileDraft(_draft);
      when(() => dataSource.completeProfile(any())).thenAnswer(
          (_) async => const OnboardingResult(nextStep: 'nasabah_dashboard'));

      final (:result, :error) = await cubit.submitNasabahRegistration(_request);

      expect(error, isNull);
      expect(result?.nextStep, 'nasabah_dashboard');
      verifyNever(() => dataSource.registerNasabah(any()));
      expect(cubit.hasProfileDraft, isFalse);
    });

    test('clears the draft once both steps land', () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister();

      await cubit.submitNasabahRegistration(_request);

      expect(cubit.hasProfileDraft, isFalse);
    });

    test('does not resend the profile on retry after it already landed',
        () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister(throws: _refusal('Anda sudah terdaftar'));

      final first = await cubit.submitNasabahRegistration(_request);
      expect(first.error?.displayMessage, 'Anda sudah terdaftar');

      stubRegister();
      final second = await cubit.submitNasabahRegistration(_request);

      expect(second.error, isNull);
      verify(() => dataSource.completeProfile(any())).called(1);
      verify(() => dataSource.registerNasabah(any())).called(2);
    });
  });
}
