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

    test('a cancelled schedule allows nothing', () {
      expect(JadwalStatus.dibatalkan.availableActions, isEmpty);
    });

    test('a completed schedule allows nothing', () {
      expect(
        JadwalStatus.selesai.availableActions,
        isEmpty,
        reason: 'completing is final; BR-08 forbids editing a closed record',
      );
    });
  });

  group('JadwalStatus.fromWire', () {
    test('maps the status the API sends', () {
      expect(JadwalStatus.fromWire('diterbitkan'), JadwalStatus.diterbitkan);
    });

    test('maps draf, whose wire spelling differs', () {
      expect(JadwalStatus.fromWire('draft'), JadwalStatus.draf);
    });

    test('returns null for a status this build has never heard of', () {
      expect(
        JadwalStatus.fromWire('ditunda'),
        isNull,
        reason: 'the API may ship a new status before the app does',
      );
    });
  });
}
