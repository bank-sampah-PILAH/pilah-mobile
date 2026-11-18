import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';

void main() {
  test('a flow id is a random version 4 uuid', () {
    final id = newFlowId();

    expect(
      id,
      matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
  });

  test('two flows never share an id', () {
    expect(newFlowId(), isNot(newFlowId()));
  });

  test('a flow id can be sent as a property', () {
    final id = newFlowId();

    expect(AnalyticsProps.sanitize({'alur_id': id}), {'alur_id': id});
  });
}
