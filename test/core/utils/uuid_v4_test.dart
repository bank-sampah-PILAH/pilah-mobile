import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/flow_id.dart';
import 'package:pilah_mobile/core/utils/uuid_v4.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';

final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  test('a uuid is random and version 4', () {
    final id = newUuidV4();

    expect(id, matches(_uuidV4));
    expect(newUuidV4(), isNot(id));
  });

  test('the flow id and the idempotency key are both such a uuid', () {
    expect(newFlowId(), matches(_uuidV4));
    expect(newTransaksiIdempotencyKey(), matches(_uuidV4));
  });
}
