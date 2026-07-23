import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

class _FakeProfileRequest extends Fake implements CompleteProfileRequest {}

class _FakeRegisterRequest extends Fake implements RegisterBankSampahRequest {}

const _draft = CompleteProfileRequest(
  nama: 'Sari Dewi',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1990-04-17',
  noHp: '81234567890',
);

const _registration = RegisterBankSampahRequest(
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  noHpPic: '81234567890',
  fotoKegiatanPath: '/tmp/kegiatan.jpg',
);

/// A backend refusal carrying [message], shaped the way the API returns one.
DioException _refusal(String message, {int status = 400}) => DioException(
      requestOptions: RequestOptions(path: '/api/v1/onboarding/profile'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/onboarding/profile'),
        statusCode: status,
        data: {'error': message},
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeProfileRequest());
    registerFallbackValue(_FakeRegisterRequest());
  });

  late _MockDataSource dataSource;
  late OnboardingCubit cubit;

  setUp(() {
    dataSource = _MockDataSource();
    cubit = OnboardingCubit(dataSource);
  });

  tearDown(() => cubit.close());

  // Failures are returned as rejected futures, not thrown synchronously: a real
  // data source is an async function, and `apiCall` receives the future already
  // evaluated, so a synchronous throw would sail past the error handling under
  // test rather than exercise it.
  void stubProfile({Object? throws}) {
    when(() => dataSource.completeProfile(any())).thenAnswer((_) async {
      if (throws != null) throw throws;
      return const OnboardingResult(nextStep: 'register_bank_sampah');
    });
  }

  void stubRegister({Object? throws}) {
    when(() => dataSource.registerBankSampah(any())).thenAnswer((_) async {
      if (throws != null) throw throws;
      return const OnboardingResult(nextStep: 'approval_pending');
    });
  }

  group('the banked draft', () {
    test('is held without touching the network', () async {
      cubit.saveProfileDraft(_draft);

      expect(cubit.hasProfileDraft, isTrue);
      expect(cubit.profileDraft?.nama, 'Sari Dewi');
      verifyNever(() => dataSource.completeProfile(any()));
    });

    test('starts empty, so a direct arrival is not mistaken for step two', () {
      expect(cubit.hasProfileDraft, isFalse);
      expect(cubit.profileDraft, isNull);
    });
  });

  group('submitRegistration', () {
    test('sends the profile before the registration', () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister();

      await cubit.submitRegistration(_registration);

      verifyInOrder([
        () => dataSource.completeProfile(_draft),
        () => dataSource.registerBankSampah(_registration),
      ]);
    });

    test('sends only the registration when no draft was banked', () async {
      stubProfile();
      stubRegister();

      final (:result, :error) = await cubit.submitRegistration(_registration);

      verifyNever(() => dataSource.completeProfile(any()));
      verify(() => dataSource.registerBankSampah(_registration)).called(1);
      expect(error, isNull);
      expect(result?.nextStep, 'approval_pending');
    });

    test('stops at a failed profile rather than registering a bank sampah',
        () async {
      cubit.saveProfileDraft(_draft);
      stubProfile(throws: _refusal('Format nomor tidak valid'));
      stubRegister();

      final (:result, :error) = await cubit.submitRegistration(_registration);

      expect(error?.displayMessage, 'Format nomor tidak valid');
      expect(result, isNull);
      verifyNever(() => dataSource.registerBankSampah(any()));
      expect(
        cubit.hasProfileDraft,
        isTrue,
        reason: 'the draft is the form contents; dropping it on a failure the '
            'user can fix would empty the screen they need to correct',
      );
    });

    test('clears the draft once both steps land', () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister();

      await cubit.submitRegistration(_registration);

      expect(cubit.hasProfileDraft, isFalse);
    });
  });

  group('retry after the profile committed but the registration did not', () {
    test('does not resend the profile', () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister(throws: _refusal('Bank sampah sudah aktif'));

      final first = await cubit.submitRegistration(_registration);
      expect(first.error?.displayMessage, 'Bank sampah sudah aktif');

      stubRegister();
      final second = await cubit.submitRegistration(_registration);

      expect(second.error, isNull);
      verify(() => dataSource.completeProfile(any())).called(1);
      verify(() => dataSource.registerBankSampah(any())).called(2);
    });

    test('would otherwise be locked out by the backend', () async {
      cubit.saveProfileDraft(_draft);
      stubProfile();
      stubRegister(throws: _refusal('Bank sampah sudah aktif'));
      await cubit.submitRegistration(_registration);

      // Second attempt: if the profile were replayed, this is what the API
      // would answer, and the user could never get past it.
      stubProfile(throws: _refusal('Profil sudah lengkap'));
      stubRegister();

      final (:result, :error) = await cubit.submitRegistration(_registration);

      expect(error, isNull);
      expect(result?.nextStep, 'approval_pending');
    });
  });

  test('an already-complete profile is a pass, not a dead end', () async {
    // The flag lives in memory, so a relaunch mid-wizard arrives with a draft
    // and no record that step one was accepted. The backend refuses the repeat;
    // treating that as failure would strand the user on a form that can never
    // submit.
    cubit.saveProfileDraft(_draft);
    stubProfile(throws: _refusal('Profil sudah lengkap'));
    stubRegister();

    final (:result, :error) = await cubit.submitRegistration(_registration);

    expect(error, isNull);
    expect(result?.nextStep, 'approval_pending');
    verify(() => dataSource.registerBankSampah(_registration)).called(1);
  });

  test('clearProfileDraft also forgets that step one was accepted', () async {
    cubit.saveProfileDraft(_draft);
    stubProfile();
    stubRegister(throws: _refusal('Bank sampah sudah aktif'));
    await cubit.submitRegistration(_registration);

    // Logout happens here: a different account must not inherit the first
    // user's "profile already submitted" credit.
    cubit.clearProfileDraft();

    cubit.saveProfileDraft(_draft);
    stubRegister();
    await cubit.submitRegistration(_registration);

    verify(() => dataSource.completeProfile(any())).called(2);
  });
}
