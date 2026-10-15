import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_state.dart';

import '../../../support/onboarding_support.dart';
import '../../../support/stub_api.dart';

const _profile = '/api/v1/onboarding/profile';
const _bank = '/api/v1/onboarding/bank-sampah';
const _nasabah = '/api/v1/onboarding/nasabah';

const _draft = CompleteProfileRequest(
  nama: 'Siti',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1998-05-17',
  noHp: '81234567890',
  alamat: 'Jl. Melati',
);

void main() {
  late StubApi api;
  late OnboardingCubit cubit;
  late File photo;

  setUp(() {
    api = StubApi();
    cubit = buildOnboardingCubit(api);
    photo = File('${Directory.systemTemp.path}/onboarding_foto.jpg')
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    await cubit.close();
    if (photo.existsSync()) photo.deleteSync();
  });

  RegisterBankSampahRequest bankRequest({String? kota = ' Depok '}) =>
      RegisterBankSampahRequest(
        nama: 'Bank Melati',
        alamat: 'Jl. Melati 1',
        kota: kota,
        noHpPic: '0812',
        fotoKegiatanPath: photo.path,
      );

  test('complete profile puts the JSON and returns the next step', () async {
    api.on('PUT', _profile, json: {'next_step': 'dashboard'});

    final outcome = await cubit.completeProfile(_draft);

    expect(outcome.result!.nextStep, 'dashboard');
    expect(outcome.error, isNull);
    expect(api.last.json['alamat'], 'Jl. Melati');
    expect(cubit.state, isA<OnboardingInitial>());
  });

  test('a profile without an address omits it from the payload', () {
    const request = CompleteProfileRequest(
      nama: 'A',
      jenisKelamin: 'laki-laki',
      tanggalLahir: '2000-01-01',
      noHp: '8',
    );

    expect(request.toJson().containsKey('alamat'), isFalse);
  });

  test('complete profile hands back a validation failure', () async {
    api.on('PUT', _profile, status: 422, json: {
      'errors': {
        'no_hp': ['Nomor tidak valid']
      }
    });

    final outcome = await cubit.completeProfile(_draft);

    expect(outcome.result, isNull);
    expect(outcome.error!.fieldError(['no_hp']), 'Nomor tidak valid');
  });

  test('accepting an invite keeps the bank name and outcome', () async {
    api.on('POST', '/api/v1/invites/accept', json: {
      'next_step': 'dashboard',
      'outcome': 'already_member',
      'message': 'Anda sudah terdaftar pada bank sampah ini',
      'nama': 'Bank Melati',
    });

    final outcome = await cubit.acceptInvite('tok-1');

    expect(api.last.json, {'token': 'tok-1'});
    expect(outcome.result!.isAlreadyMember, isTrue);
    expect(outcome.result!.bankSampahNama, 'Bank Melati');
  });

  test('accept invite falls back to alternative field names', () async {
    api.on('POST', '/api/v1/invites/accept', json: {
      'detail': 'Anda sudah terdaftar',
      'bank_sampah_nama': 'Bank Lain',
    });

    final outcome = await cubit.acceptInvite('tok-1');

    expect(outcome.result!.bankSampahNama, 'Bank Lain');
    expect(outcome.result!.isAlreadyMember, isTrue);
  });

  test('an expired invite is a failure', () async {
    api.on('POST', '/api/v1/invites/accept',
        status: 400, json: {'error': 'Undangan kedaluwarsa'});

    final outcome = await cubit.acceptInvite('old');

    expect(outcome.error!.displayMessage, 'Undangan kedaluwarsa');
  });

  test('already-member detection reads the outcome, then the wording', () {
    expect(const OnboardingResult(outcome: ' ALREADY_MEMBER ').isAlreadyMember,
        isTrue);
    expect(
        const OnboardingResult(outcome: 'joined', message: 'sudah terdaftar')
            .isAlreadyMember,
        isFalse);
    expect(const OnboardingResult(message: 'Sudah terdaftar').isAlreadyMember,
        isTrue);
    expect(const OnboardingResult().isAlreadyMember, isFalse);
  });

  test('registering a bank sampah uploads the photo as multipart', () async {
    api.on('POST', _bank, json: {'next_step': 'pending'});

    final outcome = await cubit.registerBankSampah(bankRequest());

    expect(outcome.result!.nextStep, 'pending');
    final form = api.last.body as FormData;
    final fields = {for (final f in form.fields) f.key: f.value};
    expect(fields['kota'], 'Depok');
    expect(form.files.single.key, 'foto_kegiatan');
    expect(form.files.single.value.filename, 'onboarding_foto.jpg');
  });

  test('a blank city is left out of the registration', () async {
    api.on('POST', _bank, json: {'next_step': 'pending'});

    await cubit.registerBankSampah(bankRequest(kota: '  '));
    expect((api.last.body as FormData).fields.map((f) => f.key),
        isNot(contains('kota')));
    await cubit.registerBankSampah(bankRequest(kota: null));
    expect((api.last.body as FormData).fields.map((f) => f.key),
        isNot(contains('kota')));
  });

  test('a failed bank registration returns the error', () async {
    api.on('POST', _bank, status: 413, json: {'error': 'Foto terlalu besar'});

    final outcome = await cubit.registerBankSampah(bankRequest());

    expect(outcome.error!.displayMessage, 'Foto terlalu besar');
  });

  group('submitRegistration', () {
    test('sends the saved profile first, once, then registers', () async {
      api.on('PUT', _profile, json: {'next_step': 'register_bank_sampah'});
      api.on('POST', _bank, json: {'next_step': 'pending'});
      cubit.saveProfileDraft(_draft);
      expect(cubit.hasProfileDraft, isTrue);
      expect(cubit.profileDraft, _draft);

      final outcome = await cubit.submitRegistration(bankRequest());

      expect(outcome.result!.nextStep, 'pending');
      expect(api.requests.map((r) => r.method), ['PUT', 'POST']);
      expect(cubit.hasProfileDraft, isFalse);
    });

    test('a profile failure stops before the registration', () async {
      api.on('PUT', _profile, status: 422, json: {
        'errors': {
          'nama': ['Nama kosong']
        }
      });
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitRegistration(bankRequest());

      expect(outcome.error!.displayMessage, 'Nama kosong');
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
      expect(cubit.hasProfileDraft, isTrue);
    });

    test('an already-complete profile does not block the registration',
        () async {
      api.on('PUT', _profile,
          status: 400, json: {'error': 'Profil sudah lengkap'});
      api.on('POST', _bank, json: {'next_step': 'pending'});
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitRegistration(bankRequest());

      expect(outcome.result!.nextStep, 'pending');
    });

    test('a retry after a failed registration does not resend the profile',
        () async {
      api.on('PUT', _profile, json: {});
      api.on('POST', _bank, status: 500, json: {});
      cubit.saveProfileDraft(_draft);
      await cubit.submitRegistration(bankRequest());
      api.on('POST', _bank, json: {'next_step': 'pending'});

      await cubit.submitRegistration(bankRequest());

      expect(api.requests.where((r) => r.method == 'PUT'), hasLength(1));
    });

    test('without a draft it just registers', () async {
      api.on('POST', _bank, json: {'next_step': 'pending'});

      await cubit.submitRegistration(bankRequest());

      expect(api.requests.map((r) => r.method), ['POST']);
    });

    test('clearing the draft forgets it', () {
      cubit.saveProfileDraft(_draft);

      cubit.clearProfileDraft();

      expect(cubit.profileDraft, isNull);
    });
  });

  group('nasabah registration', () {
    const request = RegisterNasabahRequest(bankSampahId: 'bank-1');

    test('applies to a bank sampah', () async {
      api.on('POST', _nasabah, json: {'next_step': 'pending_approval'});

      final outcome = await cubit.registerNasabah(request);

      expect(api.last.json, {'bank_sampah_id': 'bank-1'});
      expect(outcome.result!.nextStep, 'pending_approval');
      expect(request.hashCode,
          const RegisterNasabahRequest(bankSampahId: 'bank-1').hashCode);
    });

    test('a failure is returned', () async {
      api.on('POST', _nasabah, status: 409, json: {'error': 'Sudah mendaftar'});

      expect((await cubit.registerNasabah(request)).error!.displayMessage,
          'Sudah mendaftar');
    });

    test('submits the draft profile before applying', () async {
      api.on('PUT', _profile, json: {'next_step': 'register_nasabah'});
      api.on('POST', _nasabah, json: {'next_step': 'pending_approval'});
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitNasabahRegistration(request);

      expect(api.requests.map((r) => r.method), ['PUT', 'POST']);
      expect(outcome.result!.nextStep, 'pending_approval');
      expect(cubit.hasProfileDraft, isFalse);
    });

    test('stops when the profile step already finished onboarding', () async {
      api.on('PUT', _profile, json: {'next_step': 'nasabah_dashboard'});
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitNasabahRegistration(request);

      expect(outcome.result!.nextStep, 'nasabah_dashboard');
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
      expect(cubit.hasProfileDraft, isFalse);
    });

    test('a profile failure is returned without applying', () async {
      api.on('PUT', _profile, status: 422, json: {
        'errors': {
          'nama': ['Kosong']
        }
      });
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitNasabahRegistration(request);

      expect(outcome.error!.displayMessage, 'Kosong');
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    test('an already-complete profile still lets the application through',
        () async {
      api.on('PUT', _profile,
          status: 400, json: {'error': 'Profil sudah lengkap'});
      api.on('POST', _nasabah, json: {'next_step': 'pending_approval'});
      cubit.saveProfileDraft(_draft);

      final outcome = await cubit.submitNasabahRegistration(request);

      expect(outcome.result!.nextStep, 'pending_approval');
    });

    test('without a draft it just applies', () async {
      api.on('POST', _nasabah, json: {'next_step': 'pending_approval'});

      await cubit.submitNasabahRegistration(request);

      expect(api.requests.map((r) => r.method), ['POST']);
    });
  });

  group('directories', () {
    test('lists the bank sampah directory', () async {
      api.on('GET', '/api/v1/bank-sampah', json: [
        {
          'id': 'b1',
          'nama': 'Bank Melati',
          'alamat': 'Jl. 1',
          'kota': 'Depok',
          'foto_logo': 'https://img.test/l.png',
        },
        <String, dynamic>{},
      ]);

      final outcome = await cubit.loadBankSampahDirectory();

      expect(outcome.result!.first.nama, 'Bank Melati');
      expect(outcome.result!.first.fotoLogo, 'https://img.test/l.png');
      expect(outcome.result!.last.id, '');
      expect(outcome.result!.last.kota, '');
    });

    test('a directory failure is returned', () async {
      api.fail('GET', '/api/v1/bank-sampah');

      expect((await cubit.loadBankSampahDirectory()).error, isNotNull);
    });

    test('lists my memberships', () async {
      api.on('GET', '/api/v1/nasabah/me', json: [
        {
          'id': 'm1',
          'bank_sampah': {'id': 'b1', 'nama': 'Bank Melati', 'kota': 'Depok'},
          'status': 'approved',
          'is_active': true,
        },
        <String, dynamic>{},
      ]);

      final outcome = await cubit.loadMyMemberships();

      expect(outcome.result!.first.bankSampahNama, 'Bank Melati');
      expect(outcome.result!.first.isActive, isTrue);
      expect(outcome.result!.last.status, '');
      expect(outcome.result!.last.isActive, isFalse);
    });

    test('a membership failure is returned', () async {
      api.on('GET', '/api/v1/nasabah/me',
          status: 401, json: {'error': 'Masuk dulu'});

      expect((await cubit.loadMyMemberships()).error!.displayMessage,
          'Masuk dulu');
    });
  });

  test('submitting states compare by value', () {
    expect(const OnboardingInitial().props, isEmpty);
    expect(const OnboardingSubmitting().props, isEmpty);
  });
}
