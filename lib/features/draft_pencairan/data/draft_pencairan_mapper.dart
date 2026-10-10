import 'package:pilah_mobile/features/pencairan/data/model/mapper/pencairan_mapper.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../domain/model/draft_pencairan.dart';

/// JSON from `/api/v1/draft-pencairan` to the domain, and the domain back to a
/// request body. Money arrives as decimal strings and is whole rupiah.
class DraftPencairanMapper {
  static int _rupiah(Object? value) => PencairanMapper.rupiah(value);

  static DateTime? _tanggal(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  static Potongan _potongan(Map<String, dynamic> json) => Potongan(
        PotonganJenis.fromApi(json['potongan_jenis'] as String?) ??
            PotonganJenis.persen,
        num.tryParse(json['potongan_nilai']?.toString() ?? '') ?? 0,
      );

  /// Null when nothing was applied to everyone.
  static JumlahUmum? _jumlah(Map<String, dynamic> json) {
    final jenis = JumlahJenis.fromApi(json['jumlah_jenis'] as String?);
    final nilai = num.tryParse(json['jumlah_nilai']?.toString() ?? '');
    return jenis == null || nilai == null ? null : JumlahUmum(jenis, nilai);
  }

  static Kandidat kandidat(Map<String, dynamic> json) => Kandidat(
        id: json['id'].toString(),
        kode: json['kode']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '',
        saldo: _rupiah(json['saldo']),
      );

  static DraftItem item(Map<String, dynamic> json) {
    // A blank jenis means the item has no potongan of its own.
    final jenis = PotonganJenis.fromApi(json['potongan_jenis'] as String?);
    return DraftItem(
      id: json['id']?.toString() ?? '',
      nasabahId: json['nasabah_id'].toString(),
      nasabahNama: json['nasabah_nama']?.toString() ?? '',
      nominal: _rupiah(json['nominal']),
      metode: MetodePencairan.fromApi(json['metode'] as String?),
      potongan: jenis == null
          ? null
          : Potongan(jenis, num.tryParse('${json['potongan_nilai']}') ?? 0),
      potonganEfektif: _rupiah(json['potongan']),
      dibayar: _rupiah(json['dibayar']),
      saldoSaatIni: _rupiah(json['saldo_saat_ini']),
    );
  }

  static DraftPencairan draft(Map<String, dynamic> json) => DraftPencairan(
        id: json['id'].toString(),
        nama: json['nama']?.toString() ?? '',
        status: DraftStatus.fromApi(json['status'] as String?),
        potonganDefault: _potongan(json),
        jumlahUmum: _jumlah(json),
        dibuatOlehNama: json['dibuat_oleh_nama']?.toString() ?? '',
        diubahOlehNama: json['diubah_oleh_nama']?.toString() ?? '',
        createdAt: _tanggal(json['created_at']),
        updatedAt: _tanggal(json['updated_at']),
        items: (json['items'] as List? ?? const [])
            .map((row) => item(row as Map<String, dynamic>))
            .toList(),
        totalNominal: _rupiah(json['total_nominal']),
        totalPotongan: _rupiah(json['total_potongan']),
        totalDibayar: _rupiah(json['total_dibayar']),
      );

  static DraftRingkasan ringkasan(Map<String, dynamic> json) => DraftRingkasan(
        id: json['id'].toString(),
        nama: json['nama']?.toString() ?? '',
        status: DraftStatus.fromApi(json['status'] as String?),
        dibuatOlehNama: json['dibuat_oleh_nama']?.toString() ?? '',
        diubahOlehNama: json['diubah_oleh_nama']?.toString() ?? '',
        createdAt: _tanggal(json['created_at']),
        updatedAt: _tanggal(json['updated_at']),
        jumlahItem: (json['jumlah_item'] as num?)?.toInt() ?? 0,
        totalNominal: _rupiah(json['total_nominal']),
        totalPotongan: _rupiah(json['total_potongan']),
        totalDibayar: _rupiah(json['total_dibayar']),
      );

  /// The same body creates a draft and edits one: the backend replaces the item
  /// list, and a null potongan pair clears an item's own potongan.
  static Map<String, dynamic> body(DraftInput input) {
    final nama = input.nama?.trim();
    return {
      if (nama != null && nama.isNotEmpty) 'nama': nama,
      'potongan_jenis': input.potonganDefault.jenis.name,
      'potongan_nilai': input.potonganDefault.nilaiJson,
      // Always sent: null clears what was kept when nothing is applied now.
      'jumlah_jenis': input.jumlahUmum?.jenis.name,
      'jumlah_nilai': input.jumlahUmum?.nilaiJson,
      'items': [
        for (final item in input.items)
          {
            'nasabah_id': item.nasabahId,
            'nominal': item.nominal,
            'metode': item.metode.name,
            'potongan_jenis': item.potongan?.jenis.name,
            'potongan_nilai': item.potongan?.nilaiJson,
          },
      ],
    };
  }
}
