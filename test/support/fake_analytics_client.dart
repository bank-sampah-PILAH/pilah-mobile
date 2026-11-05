import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// Records what it was asked to do, in order.
class FakeAnalyticsClient implements AnalyticsClient {
  FakeAnalyticsClient({this.isAvailable = true});

  @override
  final bool isAvailable;
  final calls = <String>[];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');
}
