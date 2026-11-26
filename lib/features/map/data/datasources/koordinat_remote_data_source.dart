import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/map/domain/entities/hasil_koordinat.dart';

/// Turns "where is this bank?" into a coordinate without needing map tiles
/// (PIL-326 fallback).
abstract class KoordinatRemoteDataSource {
  /// Looks the address up on the server's geocoder.
  Future<HasilKoordinat> dariAlamat({required String alamat, String? kota});

  /// Parses a pasted Google Maps link; short links are expanded server-side
  /// because a browser cannot follow their redirects.
  Future<HasilKoordinat> dariTautan(String tautan);
}

@LazySingleton(as: KoordinatRemoteDataSource)
class KoordinatRemoteDataSourceImpl implements KoordinatRemoteDataSource {
  final NetworkService networkService;

  KoordinatRemoteDataSourceImpl(this.networkService);

  @override
  Future<HasilKoordinat> dariAlamat({
    required String alamat,
    String? kota,
  }) =>
      _kirim({
        'sumber': 'alamat',
        'alamat': alamat,
        if (kota != null && kota.trim().isNotEmpty) 'kota': kota.trim(),
      });

  @override
  Future<HasilKoordinat> dariTautan(String tautan) => _kirim({
        'sumber': 'tautan',
        'tautan': tautan.trim(),
      });

  Future<HasilKoordinat> _kirim(Map<String, dynamic> body) async {
    final response = await networkService.post(
      Endpoints.bankSampahResolveKoordinat,
      data: body,
    );
    return HasilKoordinat.fromJson(response.data as Map<String, dynamic>);
  }
}
