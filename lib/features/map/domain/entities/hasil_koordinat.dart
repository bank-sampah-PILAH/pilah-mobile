/// One coordinate resolved by the backend (PIL-326 fallback): either looked up
/// from an address or parsed out of a pasted Google Maps link.
///
/// The app never calls a geocoder or Google itself — the server owns the
/// provider, the key and the CORS/redirect rules.
class HasilKoordinat {
  const HasilKoordinat({
    required this.latitude,
    required this.longitude,
    required this.sumber,
    this.alamatHasil,
    this.akurasiM,
  });

  final double latitude;
  final double longitude;

  /// Provenance class chosen by the server: `geocode` or `tautan`.
  final String sumber;

  /// Human-readable address the geocoder matched, when it returned one.
  final String? alamatHasil;

  /// Accuracy radius in meters, when the provider reports one.
  final double? akurasiM;

  factory HasilKoordinat.fromJson(Map<String, dynamic> json) => HasilKoordinat(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        sumber: json['sumber']?.toString() ?? '',
        alamatHasil: json['alamat_hasil']?.toString(),
        akurasiM: (json['akurasi_m'] as num?)?.toDouble(),
      );
}
