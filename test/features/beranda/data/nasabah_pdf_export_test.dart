import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

class _Network extends Mock implements NetworkService {}

void main() {
  late _Network network;
  late NasabahRepository repository;

  setUp(() {
    network = _Network();
    repository = NasabahRepository(network);
  });

  Response pdfResponse(
    List<int> bytes, {
    String? contentDisposition,
    Object? data,
  }) =>
      Response(
        data: data ?? Uint8List.fromList(bytes),
        requestOptions: RequestOptions(path: '/pdf'),
        headers: contentDisposition == null
            ? null
            : Headers.fromMap({
                'content-disposition': [contentDisposition]
              }),
      );

  test(
      'exportPdf fetches bytes for the membership and uses the header filename',
      () async {
    when(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: any(named: 'queryParams'))).thenAnswer(
      (_) async => pdfResponse([0x25, 0x50, 0x44, 0x46],
          contentDisposition:
              'attachment; filename="Riwayat_Aktivitas_NSB-1.pdf"'),
    );

    final export = await repository.exportPdf('member-b');

    expect(export.bytes, [0x25, 0x50, 0x44, 0x46]);
    expect(export.filename, 'Riwayat_Aktivitas_NSB-1.pdf');
    verify(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: {'keanggotaan_id': 'member-b'})).called(1);
  });

  test('a stripped Content-Disposition header falls back to a fixed filename',
      () async {
    when(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: any(named: 'queryParams'))).thenAnswer(
      (_) async => pdfResponse([1]),
    );

    final export = await repository.exportPdf('member-b');

    expect(export.filename, 'Riwayat_Aktivitas.pdf');
  });

  test('a quoted filename is unquoted', () async {
    when(() => network.getBytes('/api/v1/nasabah/me/riwayat/export-pdf',
        queryParams: any(named: 'queryParams'))).thenAnswer(
      (_) async => pdfResponse([1],
          contentDisposition: 'attachment; filename="Riwayat_Aktivitas_X.pdf"'),
    );

    final export = await repository.exportPdf('member-b');

    expect(export.filename, 'Riwayat_Aktivitas_X.pdf');
  });
}
