import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import 'stub_api.dart';

/// Registers the beranda page's pengumuman repository over a fresh [StubApi]
/// answering with an empty section by default, and returns the api so a test
/// can override the answer. The caller owns the teardown.
StubApi registerNasabahPengumumanRepository({Object? berandaJson}) {
  final api = StubApi();
  api.on(
    'GET',
    '/api/v1/nasabah/me/pengumuman/beranda',
    json: berandaJson ?? {'items': [], 'unread_count': 0},
  );
  di.registerSingleton<NasabahPengumumanRepository>(
      NasabahPengumumanRepository(api.network));
  return api;
}
