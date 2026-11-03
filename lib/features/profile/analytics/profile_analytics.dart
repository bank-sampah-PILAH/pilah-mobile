import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// A part of the profile settings that the one Simpan button can save.
enum ProfileSettingsField {
  bankName('nama_bank'),
  address('alamat'),
  phone('nomor_hp'),
  logo('logo'),
  waTemplate('template_wa');

  const ProfileSettingsField(this.wire);

  /// The fixed name that is sent.
  final String wire;
}

/// The profile settings were saved. Only the names of the fields that changed
/// are sent, in a fixed order: the bank's name, address and phone number, and
/// the WhatsApp template's text, stay in the app.
void profileSettingsSaved(
  AnalyticsClient client,
  Set<ProfileSettingsField> changed,
) =>
    client.capture('profil_pengaturan_disimpan', {
      'bidang_diubah': [
        for (final field in ProfileSettingsField.values)
          if (changed.contains(field)) field.wire,
      ],
    });

/// The invite link was copied. The link itself is never sent.
void inviteLinkCopied(AnalyticsClient client) =>
    client.capture('undangan_tautan_disalin');
