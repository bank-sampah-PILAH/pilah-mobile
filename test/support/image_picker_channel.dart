import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1x1 transparent PNG, small enough to decode in a widget test.
final List<int> tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// Writes [tinyPng] to a temp file and returns it; removed when the test ends.
File writeTinyPng(String name) {
  final file = File('${Directory.systemTemp.path}/$name')
    ..writeAsBytesSync(tinyPng);
  addTearDown(() {
    if (file.existsSync()) file.deleteSync();
  });
  return file;
}

/// Makes the `image_picker` plugin channel answer every pick with [path]
/// (or a cancelled pick when null), and records the calls it receives.
List<MethodCall> mockImagePicker(String? path) {
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    calls.add(call);
    return path;
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  return calls;
}
