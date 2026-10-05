import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// A `path_provider` that points at scratch directories, so tests never touch
/// the real home folder.
class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProvider({this.downloads, required this.documents});

  /// Null mimics a platform without a downloads folder.
  final String? downloads;
  final String documents;

  @override
  Future<String?> getDownloadsPath() async => downloads;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;

  @override
  Future<String?> getExternalStoragePath() async => null;
}

/// Installs a [FakePathProvider] for the duration of the test.
FakePathProvider installFakePathProvider(
    {String? downloads, String? documents}) {
  final original = PathProviderPlatform.instance;
  final root = Directory.systemTemp.createTempSync('pilah_paths_');
  final fake = FakePathProvider(
    downloads: downloads == null ? null : '${root.path}/$downloads',
    documents: '${root.path}/${documents ?? 'documents'}',
  );
  PathProviderPlatform.instance = fake;
  addTearDown(() {
    PathProviderPlatform.instance = original;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  return fake;
}

/// Records what the app asked the OS share sheet to share.
class FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final shared = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

FakeSharePlatform installFakeSharePlatform() {
  final fake = FakeSharePlatform();
  SharePlatform.instance = fake;
  return fake;
}
