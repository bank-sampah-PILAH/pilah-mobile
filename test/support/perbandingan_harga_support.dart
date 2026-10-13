import 'package:pilah_mobile/features/perbandingan_harga/data/datasources/perbandingan_harga_remote_data_source.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';

import 'stub_api.dart';

/// A real [PerbandinganHargaCubit] over the real data source, HTTP stubbed.
PerbandinganHargaCubit buildPerbandinganHargaCubit(StubApi api) =>
    PerbandinganHargaCubit(PerbandinganHargaRemoteDataSourceImpl(api.network));

/// The perbandingan envelope the backend answers with (PIL-309).
Map<String, dynamic> perbandinganJson({
  String nomor = 'PLS-001',
  String namaSampah = 'Plastik PET',
  List<dynamic> rows = const [],
}) =>
    {
      'jenis_sampah': {
        'id': 'j1',
        'nomor': nomor,
        'nama_sampah': namaSampah,
        'kategori': 'plastik',
        'satuan': 'kg',
      },
      'perbandingan': rows,
    };

/// One comparison row; [harga] null + [alasan] = an unavailable price.
Map<String, dynamic> hargaRow(
  String bankId,
  String nama, {
  String? harga,
  String? alasan,
  String kota = 'Depok',
}) =>
    {
      'bank_sampah_id': bankId,
      'nama': nama,
      'kota': kota,
      'harga_per_kg': harga,
      'berlaku_mulai': harga != null ? '2026-10-12T07:00:00+00:00' : null,
      'harga_tidak_tersedia': harga == null,
      'alasan': alasan,
    };
