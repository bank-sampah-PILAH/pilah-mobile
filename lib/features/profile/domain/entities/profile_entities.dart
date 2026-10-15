// Domain models for the profile screen, sourced from the real API
// (/bank-sampah/me, /pengaturan/wa-template, /team).

class BankSampahProfile {
  final String id;
  final String nama;
  final String alamat;
  final String kota;
  final String noHpPic;
  final String status;

  /// Absolute URL of the uploaded logo, or null when none has been set.
  ///
  /// Always ready to hand to `Image.network`: the data source resolves the
  /// relative `/media/...` path the API returns under local file storage
  /// against the API origin, so callers never have to know which storage
  /// backend answered.
  final String? fotoLogo;

  /// The bank's map coordinates (PIL-326), or null when the penguru has not
  /// set them yet — a bank always lists, it just cannot appear on a map.
  final ({double latitude, double longitude})? lokasi;

  const BankSampahProfile({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.noHpPic,
    required this.status,
    this.fotoLogo,
    this.lokasi,
  });
}

class WaTemplate {
  final String template;
  final String? preview;
  final List<String> variables;

  const WaTemplate({
    required this.template,
    this.preview,
    this.variables = const [],
  });

  WaTemplate copyWith({String? template}) => WaTemplate(
        template: template ?? this.template,
        preview: preview,
        variables: variables,
      );
}

class TeamMember {
  final String id;
  final String nama;
  final String email;
  final bool isPrimary;
  final bool isCurrentUser;

  const TeamMember({
    required this.id,
    required this.nama,
    required this.email,
    required this.isPrimary,
    required this.isCurrentUser,
  });
}
