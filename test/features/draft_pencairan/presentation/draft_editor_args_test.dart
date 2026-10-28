import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';

void main() {
  group('DraftEditorArgs.fromRoute', () {
    test('prefers the typed editor args over a query id', () {
      const args = DraftEditorArgs.lanjutkan('saved-draft');

      expect(DraftEditorArgs.fromRoute(args, {'id': 'query-draft'}), args);
    });

    test('accepts safe draft ids from route query parameters', () {
      final args = DraftEditorArgs.fromRoute(null, {'id': 'draft_123-abc'});

      expect(args?.draftId, 'draft_123-abc');
      expect(args?.kandidat, isEmpty);
    });

    test('rejects absent, empty, overlong, and path-like ids', () {
      for (final query in <Map<String, String>>[
        const {},
        {'id': ''},
        {'id': 'a' * 65},
        {'id': '../other'},
        {'id': 'nested/path'},
      ]) {
        expect(DraftEditorArgs.fromRoute(null, query), isNull);
      }
    });
  });
}
