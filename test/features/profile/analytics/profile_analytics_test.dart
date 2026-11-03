import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/analytics/profile_analytics.dart';

import '../../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;

  setUp(() => client = FakeAnalyticsClient());

  test('saved settings name the fields that changed, in a fixed order', () {
    profileSettingsSaved(client, {
      ProfileSettingsField.waTemplate,
      ProfileSettingsField.bankName,
      ProfileSettingsField.phone,
    });

    expect(client.events.single.name, 'profil_pengaturan_disimpan');
    expect(client.events.single.properties, {
      'bidang_diubah': ['nama_bank', 'nomor_hp', 'template_wa'],
    });
  });

  test('every field has its own fixed name', () {
    profileSettingsSaved(client, ProfileSettingsField.values.toSet());

    expect(client.events.single.properties['bidang_diubah'],
        ['nama_bank', 'alamat', 'nomor_hp', 'logo', 'template_wa']);
  });

  test('copying the invite link carries nothing but its name', () {
    inviteLinkCopied(client);

    expect(client.events.single.name, 'undangan_tautan_disalin');
    expect(client.events.single.properties, isEmpty);
  });
}
