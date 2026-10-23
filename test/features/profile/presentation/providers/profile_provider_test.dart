import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';

import '../../../../support/profile_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  late StubApi api;
  late TestProfileNotifier notifier;
  late ProviderContainer container;
  late ProviderSubscription<ProfileState> subscription;

  setUp(() {
    api = StubApi();
    notifier = buildProfileNotifier(api);
    container = ProviderContainer(
      overrides: [profileProvider.overrideWith(() => notifier)],
    );
    subscription = container.listen(profileProvider, (_, __) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('loads the bank, WhatsApp template and team together', () async {
    stubProfile(api, bank: bankJson(logo: '/media/logo.png'));

    await notifier.load();

    final state = container.read(profileProvider);
    expect(state.status, ProfileStatus.loaded);
    expect(state.bankSampah!.nama, 'Bank Sampah BTH');
    expect(state.bankSampah!.fotoLogo, 'http://api.test/media/logo.png');
    expect(state.waTemplate!.template, 'Halo {nama}');
    expect(state.waTemplate!.preview, 'Halo Budi');
    expect(state.waTemplate!.variables, ['{Nama}', '{Total}']);
    expect(state.team.map((m) => m.nama), ['Siti', 'Andi']);
    expect(state.team.first.isPrimary, isTrue);
    expect(state.team.first.isCurrentUser, isTrue);
    expect(state.team.last.isPrimary, isFalse);
  });

  test('missing optional fields fall back to blanks', () async {
    stubProfile(api,
        bank: <String, dynamic>{},
        wa: <String, dynamic>{},
        team: <Map<String, dynamic>>[{}]);

    await notifier.load();

    expect(container.read(profileProvider).bankSampah!.id, '');
    expect(container.read(profileProvider).bankSampah!.fotoLogo, isNull);
    expect(container.read(profileProvider).waTemplate!.template, '');
    expect(container.read(profileProvider).waTemplate!.variables, isEmpty);
    expect(container.read(profileProvider).team.single.id, '');
  });

  test('a team response that is not a list or map reads as empty', () async {
    stubProfile(api, team: 'oops');

    await notifier.load();

    expect(container.read(profileProvider).team, isEmpty);
  });

  test('an empty team body reads as no members', () async {
    stubProfile(api);
    api.on('GET', '/api/v1/team', json: null);

    await notifier.load();

    expect(container.read(profileProvider).team, isEmpty);
  });

  test('a failed bank load is an error, even if the rest would work', () async {
    stubProfile(api);
    api.on('GET', '/api/v1/bank-sampah/me',
        status: 403, json: {'error': 'Bukan pengelola'});

    await notifier.load();

    expect(container.read(profileProvider).status, ProfileStatus.error);
    expect(container.read(profileProvider).error, 'Bukan pengelola');
  });

  test('the template and team degrade without failing the page', () async {
    stubProfile(api);
    api.fail('GET', '/api/v1/pengaturan/wa-template');
    api.on('GET', '/api/v1/team', status: 500, json: {});

    await notifier.load();

    expect(container.read(profileProvider).status, ProfileStatus.loaded);
    expect(container.read(profileProvider).waTemplate, isNull);
    expect(container.read(profileProvider).team, isEmpty);
  });

  test('a silent reload keeps the loaded page on screen', () async {
    stubProfile(api);
    await notifier.load();
    stubProfile(api, bank: {...bankJson(), 'nama': 'Baru'});
    final statuses = <ProfileStatus>[];
    final sub = container.listen(
      profileProvider,
      (_, next) => statuses.add(next.status),
    );

    await notifier.load(silent: true);
    sub.close();

    expect(statuses, [ProfileStatus.loaded]);
    expect(container.read(profileProvider).bankSampah!.nama, 'Baru');
  });

  test('saving the template stores it and updates state', () async {
    stubProfile(api);
    await notifier.load();
    api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});

    final error = await notifier.saveWaTemplate('Halo {nama}, saldo {saldo}');

    expect(error, isNull);
    expect(container.read(profileProvider).isSavingTemplate, isFalse);
    expect(container.read(profileProvider).waTemplate!.template,
        'Halo {nama}, saldo {saldo}');
    expect(container.read(profileProvider).waTemplate!.variables,
        ['{Nama}', '{Total}']);
    expect(api.last.json, {'template': 'Halo {nama}, saldo {saldo}'});
  });

  test('saving a template before one was loaded starts from blank', () async {
    api.on('PUT', '/api/v1/pengaturan/wa-template', json: {});

    await notifier.saveWaTemplate('Halo');

    expect(container.read(profileProvider).waTemplate!.template, 'Halo');
  });

  test('a rejected template save returns the failure and stops the spinner',
      () async {
    api.on('PUT', '/api/v1/pengaturan/wa-template', status: 422, json: {
      'errors': {
        'template': ['Variabel tidak dikenal']
      }
    });

    final error = await notifier.saveWaTemplate('{x}');

    expect(error!.displayMessage, 'Variabel tidak dikenal');
    expect(container.read(profileProvider).isSavingTemplate, isFalse);
  });

  test('updating the bank profile sends the multipart fields', () async {
    stubProfile(api);
    await notifier.load();
    api.on('PUT', '/api/v1/bank-sampah/me',
        json: {...bankJson(), 'nama': 'Nama Baru'});

    final error = await notifier.updateBankSampah(
        nama: 'Nama Baru', alamat: 'Jl. Baru', noHpPic: '0812');

    expect(error, isNull);
    expect(container.read(profileProvider).bankSampah!.nama, 'Nama Baru');
    final form = api.last.body as FormData;
    expect({
      for (final f in form.fields) f.key: f.value
    }, {
      'nama': 'Nama Baru',
      'alamat': 'Jl. Baru',
      'kota': 'Depok',
      'no_hp_pic': '0812',
    });
  });

  test('a rejected bank update hands back the failure', () async {
    api.on('PUT', '/api/v1/bank-sampah/me', status: 422, json: {
      'errors': {
        'no_hp_pic': ['Nomor tidak valid']
      }
    });

    final error =
        await notifier.updateBankSampah(nama: 'a', alamat: 'b', noHpPic: 'x');

    expect(error!.fieldError(['no_hp_pic']), 'Nomor tidak valid');
  });

  test('generates a team invite link', () async {
    api.on('POST', '/api/v1/team/invite',
        json: {'invite_url': 'https://pilah.test/invite/abc'});

    final result = await notifier.generateInvite();

    expect(result.url, 'https://pilah.test/invite/abc');
    expect(result.error, isNull);
  });

  test('an invite for a non-primary pengelola is refused', () async {
    api.on('POST', '/api/v1/team/invite',
        status: 403, json: {'error': 'Hanya pengelola utama'});

    final result = await notifier.generateInvite();

    expect(result.url, isNull);
    expect(result.error!.displayMessage, 'Hanya pengelola utama');
  });

  test('an invite response without a URL reads as blank', () async {
    api.on('POST', '/api/v1/team/invite', json: <String, dynamic>{});

    expect((await notifier.generateInvite()).url, '');
  });

  test('reset forgets everything', () async {
    stubProfile(api);
    await notifier.load();

    notifier.reset();

    expect(container.read(profileProvider), const ProfileState());
  });

  test('copyWith on a template keeps its preview and variables', () {
    const template = WaTemplate(template: 'a', preview: 'p', variables: ['v']);

    final next = template.copyWith(template: 'b');

    expect(next.template, 'b');
    expect(next.preview, 'p');
    expect(next.variables, ['v']);
    expect(template.copyWith().template, 'a');
  });
}
