import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';

import 'stub_api.dart';

/// A real [CariBankCubit] over the real data source, with HTTP stubbed.
CariBankCubit buildCariBankCubit(StubApi api) =>
    CariBankCubit(CariBankRemoteDataSourceImpl(api.network));

/// The paginated directory envelope the backend answers with (PIL-308).
Map<String, dynamic> bankSampahPage(
  List<dynamic> results, {
  int? count,
  bool hasNext = false,
}) =>
    {
      'count': count ?? results.length,
      'previous': null,
      'next': hasNext ? 'http://api.test/api/v1/bank-sampah?page=2' : null,
      'results': results,
    };

/// A directory row; [latitude]/[longitude] add the PIL-326 coordinates a
/// map marker needs (PIL-330). Omit both to simulate a bank without
/// coordinates. [jarakKm] adds the PIL-314 distance string, present only in
/// coordinate search mode.
Map<String, dynamic> bankRow(
  String id,
  String nama, {
  String kota = 'Depok',
  double? latitude,
  double? longitude,
  String? jarakKm,
}) =>
    {
      'id': id,
      'nama': nama,
      'alamat': 'Jl. $nama',
      'kota': kota,
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
      if (jarakKm != null) 'jarak_km': jarakKm,
    };

/// A `GET /bank-sampah/{id}` detail body with layanan.
Map<String, dynamic> bankDetailJson({List<dynamic> layanan = const []}) => {
      'id': 'b1',
      'nama': 'Bank Garis',
      'alamat': 'Jl. Garis No. 1',
      'kota': 'Depok',
      'status': 'active',
      'latitude': '-6.362829',
      'longitude': '106.828655',
      'foto_logo': '',
      'layanan': layanan,
    };

Map<String, dynamic> layananJson(String kode, String nama, String harga) => {
      'id': 'ls-$kode',
      'kode': kode,
      'nama_sampah': nama,
      'kategori': 'kertas',
      'deskripsi': '',
      'satuan': 'kg',
      'harga_per_kg': harga,
    };
