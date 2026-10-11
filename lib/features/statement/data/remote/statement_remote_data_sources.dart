import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

import '../../domain/model/statement_export.dart';

abstract class StatementRemoteDataSources {
  Future<StatementExport> exportPdf(String membershipId);
}

@LazySingleton(as: StatementRemoteDataSources)
class StatementRemoteDataSourceImpl implements StatementRemoteDataSources {
  final NetworkService _networkService;
  const StatementRemoteDataSourceImpl(this._networkService);

  static const _path = '/api/v1/nasabah/me/riwayat/export-pdf';

  /// The backend renders the statement with the member's bank and saldo, so
  /// the pass-through only forwards auth. Byte-and-header only: file writes,
  /// preview and sharing live in the presentation layer.
  @override
  Future<StatementExport> exportPdf(String membershipId) async {
    final response = await _networkService.getBytes(
      _path,
      queryParams: {'keanggotaan_id': membershipId},
    );
    final data = response.data;
    final bytes = Uint8List.fromList((data as List).cast<int>());
    return StatementExport(
      bytes: bytes,
      filename: attachmentName(response),
    );
  }

  /// Filename from `Content-Disposition: attachment; filename="x.pdf"`, with
  /// a fixed default — the backend always sends the header, but a proxy
  /// stripping it must not defeat the save. The value becomes a path
  /// component (temp preview file, Downloads save), so it is reduced to a
  /// bare basename and forced onto the PDF extension: a header like
  /// `filename="../x.pdf"` must not escape the target directory.
  String attachmentName(Response response) {
    final header = response.headers.value('content-disposition');
    final match = header == null ? null : filenameRegExp.firstMatch(header);
    final raw = match?.group(1) ?? defaultStatementFilename;
    // Headers may carry either separator flavor; strip both so `..\x.pdf`
    // cannot traverse on Windows either.
    final base =
        raw.split(RegExp(r'[/\\]')).where((part) => part.isNotEmpty).last;
    return base.endsWith('.pdf') ? base : '$base.pdf';
  }
}

const defaultStatementFilename = 'Riwayat_Aktivitas.pdf';
final RegExp filenameRegExp = RegExp(r'filename="?([^";]+)"?$');
