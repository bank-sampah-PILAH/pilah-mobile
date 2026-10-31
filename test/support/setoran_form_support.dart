import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

import 'harga_support.dart';
import 'nasabah_support.dart';
import 'profile_support.dart';
import 'stub_api.dart';
import 'transaksi_support.dart';

/// The provider overrides the setoran form needs merely to build itself.
///
/// The form used to be reachable only as its own route, so a test about
/// navigation could register a stub page and never touch the real thing. From
/// the medium breakpoint up it now opens as a side sheet *inside* whichever
/// page asked for it, so tapping "Tambah Transaksi" renders the real form
/// inline — and a test that does so needs the form's providers even when the
/// test itself is about the menu.
///
/// Quiet stubs only: every endpoint answers empty, because none of these tests
/// is about what the form loads.
Widget withSetoranFormProviders({required Widget child, StubApi? api}) {
  final stub = api ?? StubApi();
  stub.on('GET', '/api/v1/jenis-sampah', json: {'results': [], 'next': null});
  stub.on('GET', '/api/v1/nasabah', json: {'results': [], 'next': null});
  stub.on('GET', '/api/v1/pengaturan/wa-template', json: <String, dynamic>{});

  return ProviderScope(
    overrides: [
      hargaProvider.overrideWith(() => buildHargaNotifier(stub)),
      profileProvider.overrideWith(() => buildProfileNotifier(stub)),
      nasabahProvider.overrideWith(() => buildNasabahNotifier(stub)),
      transaksiProvider.overrideWith(() => buildTransaksiNotifier(stub)),
    ],
    child: child,
  );
}
