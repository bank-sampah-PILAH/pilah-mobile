import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

@LazySingleton(as: TransaksiRemoteDataSource)
class TransaksiRemoteDataSourceImpl implements TransaksiRemoteDataSource {
  final NetworkService networkService;

  TransaksiRemoteDataSourceImpl(this.networkService);

  static const String _path = '/api/v1/transaksi';

  @override
  Future<List<TransaksiGroupEntity>> getTransaksi(TransaksiFilter filter) async {
    final response = await networkService.get(
      _path,
      queryParams: {...filter.toQueryParams(), 'page_size': 100},
    );
    final data = response.data;
    final List<dynamic> results =
        data is Map<String, dynamic> ? (data['results'] as List? ?? []) : (data as List);

    final today = DateTime.now();
    final groups = <String, List<TransaksiEntity>>{};
    final order = <String>[];

    for (final raw in results) {
      final json = raw as Map<String, dynamic>;
      final tanggal = DateTime.tryParse(json['tanggal']?.toString() ?? '')?.toLocal();
      final header = _bucketHeader(tanggal, today);
      final entity = _mapListItem(json, tanggal);
      if (!groups.containsKey(header)) {
        groups[header] = [];
        order.add(header);
      }
      groups[header]!.add(entity);
    }

    return order
        .map((header) => TransaksiGroupEntity(header: header, transactions: groups[header]!))
        .toList();
  }

  @override
  Future<TransaksiExport> exportTransaksi(TransaksiFilter filter) async {
    final response = await networkService.getBytes(
      '$_path/export',
      queryParams: filter.toQueryParams(),
    );
    final data = response.data;
    final bytes = data is Uint8List
        ? data
        : Uint8List.fromList((data as List).cast<int>());
    final filename = _extractFilename(response.headers.value('content-disposition')) ??
        'laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    return TransaksiExport(bytes: bytes, filename: filename);
  }

  String? _extractFilename(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final match = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
    return match?.group(1);
  }

  @override
  Future<TransaksiCreated> addTransaksi(TransaksiRequest request) async {
    final body = {
      'nasabah_id': request.nasabahId,
      'items': request.items
          .map((item) => {'jenis_sampah_id': item.jenisSampahId, 'berat': item.berat})
          .toList(),
      if (request.catatan != null && request.catatan!.trim().isNotEmpty)
        'catatan': request.catatan!.trim(),
    };
    final response = await networkService.post(_path, data: body);
    final json = response.data as Map<String, dynamic>;
    final items = json['items'] as List? ?? [];
    return TransaksiCreated(
      id: json['id']?.toString() ?? '',
      totalNilai: _toInt(json['total_nilai']),
      saldoSetelah: _toInt(json['saldo_setelah_transaksi']),
      itemCount: items.length,
    );
  }

  @override
  Future<TransaksiDetailEntity> getTransaksiDetail(String id) async {
    final response = await networkService.get('$_path/$id');
    final json = response.data as Map<String, dynamic>;
    final items = (json['items'] as List? ?? []).map((raw) {
      final item = raw as Map<String, dynamic>;
      return ItemSetoranEntity(
        jenis: item['nama_sampah_snapshot']?.toString() ?? '-',
        berat: '${_trimDecimal(item['berat'])} kg',
        harga: _rupiah(item['harga_snapshot']),
        subtotal: _rupiah(item['subtotal']),
      );
    }).toList();

    return TransaksiDetailEntity(
      name: json['nasabah_nama']?.toString() ?? '-',
      amountFormatted: _rupiah(json['total_nilai']),
      balanceFormatted: _rupiah(json['saldo_setelah_transaksi']),
      waStatus: _waStatus(json['status_wa']?.toString()),
      items: items,
    );
  }

  @override
  Future<String> resendWa(String id) async {
    // On success the backend returns 200 with {"success": true, "status_wa":
    // "terkirim", ...}; on a failed send it returns 400 with {"error": ...},
    // which Dio raises so apiCall can surface the message.
    final response = await networkService.post('$_path/$id/notify-wa', data: const {});
    final json = response.data as Map<String, dynamic>;
    return _waStatus(json['status_wa']?.toString());
  }

  // ---- mapping helpers ----------------------------------------------------

  TransaksiEntity _mapListItem(Map<String, dynamic> json, DateTime? tanggal) {
    final name = json['nasabah_nama']?.toString() ?? '-';
    final jenisUtama = json['jenis_sampah_utama']?.toString();
    final berat = _trimDecimal(json['total_berat_kg']);
    final palette = _avatarPaletteFor(name);
    return TransaksiEntity(
      id: json['id']?.toString() ?? '',
      initials: json['nasabah_inisial']?.toString() ?? _initialsOf(name),
      avatarColor: palette.$1,
      textColor: palette.$2,
      name: name,
      subtitle: jenisUtama != null ? '$jenisUtama • $berat kg' : '$berat kg',
      amount: '+${_rupiah(json['total_nilai'])}',
      isWaSuccess: json['status_wa']?.toString() == 'terkirim',
      time: tanggal != null ? _formatTime(tanggal) : null,
      balance: '',
      items: const [],
    );
  }

  String _bucketHeader(DateTime? date, DateTime today) {
    if (date == null) return 'LAINNYA';
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '$diff HARI LALU';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _waStatus(String? value) {
    switch (value) {
      case 'terkirim':
        return 'sent';
      case 'gagal':
        return 'failed';
      default:
        return 'pending';
    }
  }

  int _toInt(dynamic value) => (double.tryParse(value?.toString() ?? '') ?? 0).round();

  String _rupiah(dynamic value) {
    final digits = _toInt(value).abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  String _trimDecimal(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '') ?? 0;
    var text = n.toStringAsFixed(2);
    if (text.contains('.')) {
      text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return text;
  }

  String _initialsOf(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NN';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  (Color, Color) _avatarPaletteFor(String name) {
    if (name.isEmpty) return _avatarPalette.first;
    return _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
  }

  static const List<(Color, Color)> _avatarPalette = [
    (Color(0xFFEAF5EC), Color(0xFF2F6B45)),
    (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
    (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
    (Color(0xFFFFF8D6), Color(0xFFD4A017)),
    (Color(0xFFFFEDD5), Color(0xFF9A3412)),
    (Color(0xFFCCFBF1), Color(0xFF0F766E)),
  ];
}
