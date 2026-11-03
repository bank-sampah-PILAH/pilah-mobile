import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';

/// Records what it was asked to do, in order.
///
/// Events go through [AnalyticsProps.sanitize] like they do for real, so a
/// test that sends a property the list does not allow fails right there.
class FakeAnalyticsClient implements AnalyticsClient {
  FakeAnalyticsClient({this.isAvailable = true});

  @override
  final bool isAvailable;
  final calls = <String>[];

  /// Every event captured, with its cleaned properties.
  final events = <({String name, Map<String, Object> properties})>[];

  /// Every screen name reported.
  final screens = <String>[];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  void capture(String event, [Map<String, Object?> properties = const {}]) {
    calls.add('capture:$event');
    events.add((name: event, properties: AnalyticsProps.sanitize(properties)));
  }

  @override
  void screen(String name) {
    calls.add('screen:$name');
    screens.add(name);
  }
}
