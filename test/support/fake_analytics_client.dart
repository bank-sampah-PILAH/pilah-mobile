import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';

/// Records what it was asked to do, in order.
///
/// Events go through [AnalyticsProps.sanitize] like they do for real, so a
/// test that sends a property the list does not allow fails right there.
class FakeAnalyticsClient implements AnalyticsClient {
  /// With [enforceLifecycle] it behaves like the real client: events and
  /// screens are dropped until [start] and again after [stop]. Without it
  /// everything is recorded, which most tests want.
  FakeAnalyticsClient({this.isAvailable = true, this.enforceLifecycle = false});

  final bool enforceLifecycle;
  bool _live = false;

  @override
  final bool isAvailable;

  /// Only `start` and `stop`, in order.
  final calls = <String>[];

  /// Everything it was asked to do, in order: lifecycle, events and screens.
  final log = <String>[];

  /// Every event captured, with its cleaned properties.
  final events = <({String name, Map<String, Object> properties})>[];

  /// Who it was told the user is, and the properties registered for every
  /// event, in the order they came.
  final identified = <String>[];
  final registered = <Map<String, Object>>[];

  /// Every screen name reported, and the properties each came with.
  final screens = <String>[];
  final screenProps = <Map<String, Object>>[];

  @override
  Future<void> start() async {
    _live = true;
    calls.add('start');
    log.add('start');
  }

  @override
  Future<void> stop() async {
    _live = false;
    calls.add('stop');
    log.add('stop');
  }

  @override
  void capture(String event, [Map<String, Object?> properties = const {}]) {
    if (enforceLifecycle && !_live) return;
    log.add('capture:$event');
    events.add((name: event, properties: AnalyticsProps.sanitize(properties)));
  }

  @override
  void screen(String name, [Map<String, Object?> properties = const {}]) {
    if (enforceLifecycle && !_live) return;
    log.add('screen:$name');
    screens.add(name);
    screenProps.add(AnalyticsProps.sanitize(properties));
  }

  @override
  void identify(String id) {
    log.add('identify:$id');
    identified.add(AnalyticsProps.cleanId(id) ?? '');
  }

  @override
  void register(Map<String, Object?> properties) {
    log.add('register');
    registered.add(AnalyticsProps.sanitize(properties));
  }

  @override
  void reset() => log.add('reset');
}
