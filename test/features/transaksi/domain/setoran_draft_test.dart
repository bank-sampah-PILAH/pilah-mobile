import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/setoran_draft.dart';

/// Whether an unsaved setoran may be submitted is a rule, not a layout
/// concern. Today it lives inline in `_handleSubmit` as one `if` over
/// `List<Map<String, dynamic>>`, which means it cannot be tested without
/// building the whole page, and the wide-screen form would have to repeat it.
///
/// It is also incomplete. `ItemSetoranCard` parses its weight field with
/// `num.tryParse(value) ?? 0.0`, so clearing the box yields 0 — and nothing
/// stops that reaching the server. The backend rejects it (PIL-224), so this is
/// not a hole; it is a round trip and a server error where inline feedback
/// belongs.
void main() {
  const jenis = 'jenis-plastik-pet';

  SetoranDraft draft({
    String? nasabahId = 'nasabah-1',
    List<SetoranItemDraft> items = const [
      SetoranItemDraft(jenisSampahId: jenis, berat: 3.5),
    ],
  }) =>
      SetoranDraft(nasabahId: nasabahId, items: items);

  group('SetoranDraft — the happy path', () {
    test('a nasabah and one weighed item is submittable', () {
      final subject = draft();
      expect(subject.problems, isEmpty);
      expect(subject.isValid, isTrue);
      expect(subject.invalidItemIndexes, isEmpty);
    });

    test('several weighed items are submittable', () {
      final subject = draft(items: const [
        SetoranItemDraft(jenisSampahId: jenis, berat: 3.5),
        SetoranItemDraft(jenisSampahId: 'jenis-kaca', berat: 0.5),
      ]);
      expect(subject.isValid, isTrue);
    });
  });

  group('SetoranDraft — what blocks submission', () {
    test('no nasabah chosen', () {
      expect(
          draft(nasabahId: null).problems, contains(SetoranProblem.noNasabah));
    });

    test('a blank nasabah id counts as none chosen', () {
      expect(
          draft(nasabahId: '  ').problems, contains(SetoranProblem.noNasabah));
    });

    test('no items at all', () {
      final subject = draft(items: const []);
      expect(subject.problems, contains(SetoranProblem.noItems));
      expect(subject.problems, isNot(contains(SetoranProblem.nonPositiveBerat)),
          reason: 'an empty list has no weights to complain about');
    });

    test('an item with no waste type chosen', () {
      final subject = draft(items: const [SetoranItemDraft(berat: 2)]);
      expect(subject.problems, contains(SetoranProblem.itemWithoutJenis));
      expect(subject.invalidItemIndexes, {0},
          reason: 'the form has to know which card to mark');
    });

    test('an item left at zero weight', () {
      final subject = draft(
          items: const [SetoranItemDraft(jenisSampahId: jenis, berat: 0)]);
      expect(subject.problems, contains(SetoranProblem.nonPositiveBerat),
          reason: 'clearing the weight box yields 0 and must not be submitted');
      expect(subject.invalidItemIndexes, {0});
    });

    test('every problem is reported, not just the first', () {
      final subject = draft(nasabahId: null, items: const [
        SetoranItemDraft(berat: 0),
      ]);
      expect(
        subject.problems,
        containsAll([
          SetoranProblem.noNasabah,
          SetoranProblem.itemWithoutJenis,
          SetoranProblem.nonPositiveBerat,
        ]),
        reason: 'fixing one thing should not reveal the next one at a time',
      );
    });

    test('only the offending items are marked', () {
      final subject = draft(items: const [
        SetoranItemDraft(jenisSampahId: jenis, berat: 3.5),
        SetoranItemDraft(jenisSampahId: 'jenis-kaca', berat: 0),
        SetoranItemDraft(jenisSampahId: 'jenis-kertas', berat: 1),
      ]);
      expect(subject.invalidItemIndexes, {1});
    });
  });

  group('SetoranDraft — the boundary', () {
    test('zero is rejected and the smallest step above it is accepted', () {
      expect(
        draft(items: const [SetoranItemDraft(jenisSampahId: jenis, berat: 0)])
            .isValid,
        isFalse,
      );
      expect(
        draft(items: const [SetoranItemDraft(jenisSampahId: jenis, berat: 0.1)])
            .isValid,
        isTrue,
        reason: 'the rule is "more than zero", not "at least one kilo"',
      );
    });

    test('a negative weight is rejected', () {
      expect(
        draft(items: const [SetoranItemDraft(jenisSampahId: jenis, berat: -1)])
            .problems,
        contains(SetoranProblem.nonPositiveBerat),
      );
    });
  });

  /// The form wants to redden a card the moment the pengelola creates an
  /// invalid state by editing, but *not* the moment a card appears. Those are
  /// different problems: a fresh card has no jenis yet (invalid from birth,
  /// nobody's fault), while a zero weight is unreachable without an edit,
  /// because a new item starts at 1 kg. So the page needs the indexes for one
  /// specific problem, not just "invalid".
  group('SetoranDraft — indeks per masalah', () {
    test('only the zero-weight items come back', () {
      final subject = draft(items: const [
        SetoranItemDraft(jenisSampahId: jenis, berat: 3.5),
        SetoranItemDraft(jenisSampahId: 'jenis-kaca', berat: 0),
        SetoranItemDraft(berat: 2),
      ]);

      expect(subject.itemIndexesWith(SetoranProblem.nonPositiveBerat), {1},
          reason: 'index 2 is invalid too, but for the other reason');
    });

    test('only the items without a jenis come back', () {
      final subject = draft(items: const [
        SetoranItemDraft(berat: 2),
        SetoranItemDraft(jenisSampahId: jenis, berat: 0),
      ]);

      expect(subject.itemIndexesWith(SetoranProblem.itemWithoutJenis), {0});
    });

    test('a form-level problem has no item indexes', () {
      expect(
        draft(nasabahId: null).itemIndexesWith(SetoranProblem.noNasabah),
        isEmpty,
        reason: 'noNasabah and noItems are about the form, not a card, so '
            'asking which cards they mark must be empty rather than wrong',
      );
    });
  });
}
