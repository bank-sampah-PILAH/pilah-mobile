import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_status.dart';

/// Which lifecycle actions a schedule allows depends only on the status it is
/// in, so the rule belongs to the status itself rather than to the widget that
/// happens to draw the buttons.
void main() {
  group('JadwalStatus.availableActions', () {
    test('a draft can be published or cancelled', () {
      expect(
        JadwalStatus.draf.availableActions,
        {JadwalAction.batalkan, JadwalAction.terbitkan},
      );
    });

    test('a published schedule can be cancelled or completed', () {
      expect(
        JadwalStatus.diterbitkan.availableActions,
        {JadwalAction.batalkan, JadwalAction.selesaikan},
        reason: 'it can no longer be published a second time',
      );
    });
  });
}
