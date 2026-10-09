import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_cubit.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);

DraftEditorCubit _editor() =>
    DraftEditorCubit(_MockUseCases())..startNew(const [_ahmad, _budi, _citra]);

List<int> _nominal(DraftEditorCubit editor) =>
    editor.state.items.map((i) => i.nominal).toList();

void main() {
  group('JumlahUmum', () {
    test('100 percent is the whole saldo, and is what Penuh means', () {
      expect(JumlahUmum.penuh, const JumlahUmum(JumlahJenis.persen, 100));
      expect(JumlahUmum.penuh.hitung(465600), 465600);
      expect(JumlahUmum.penuh.hitung(1), 1);
    });

    test('Persen is a share of the saldo, rounded down to whole rupiah', () {
      const lima = JumlahUmum(JumlahJenis.persen, 50);
      const aneh = JumlahUmum(JumlahJenis.persen, 33.33);

      expect(lima.hitung(465601), 232800);
      expect(aneh.hitung(50000), 16665);
    });

    test('Nominal is the same rupiah for everyone, but never above a saldo',
        () {
      const seratus = JumlahUmum(JumlahJenis.rupiah, 100000);

      expect(seratus.hitung(465600), 100000);
      expect(seratus.hitung(50000), 50000,
          reason: 'paid at most their saldo, not flagged');
    });

    test('is valid when it can be applied', () {
      expect(const JumlahUmum(JumlahJenis.rupiah, 1).valid, isTrue);
      expect(const JumlahUmum(JumlahJenis.rupiah, 0).valid, isFalse);
      expect(const JumlahUmum(JumlahJenis.persen, 100).valid, isTrue);
      expect(const JumlahUmum(JumlahJenis.persen, 100.5).valid, isFalse);
      expect(const JumlahUmum(JumlahJenis.persen, 0).valid, isFalse);
    });

    test('there are two kinds, Persen and Nominal, in the potongan order', () {
      expect(JumlahJenis.values.map((j) => j.label), ['Persen', 'Nominal']);
    });
  });

  group('terapkanUmum', () {
    test('a jumlah rewrites every nominal and nothing else', () {
      final editor = _editor();

      editor.terapkanUmum(jumlah: const JumlahUmum(JumlahJenis.rupiah, 100000));

      expect(_nominal(editor), [100000, 50000, 100000]);
      expect(editor.state.dirty, isTrue);
      expect(editor.state.items.every((i) => i.metode == MetodePencairan.tunai),
          isTrue);
      expect(editor.state.potonganDefault, Potongan.nol);
    });

    test('a metode changes every item, leaving the amounts', () {
      final editor = _editor();

      editor.terapkanUmum(metode: MetodePencairan.transfer);

      expect(
          editor.state.items.every((i) => i.metode == MetodePencairan.transfer),
          isTrue);
      expect(_nominal(editor), [465600, 50000, 250000]);
    });

    test('a potongan becomes the draft default, items keep their own', () {
      final editor = _editor()
        ..setItemPotongan('n-2', const Potongan(PotonganJenis.rupiah, 500));

      editor.terapkanUmum(potongan: const Potongan(PotonganJenis.persen, 10));

      expect(editor.state.potonganDefault,
          const Potongan(PotonganJenis.persen, 10));
      expect(editor.state.items[1].potongan,
          const Potongan(PotonganJenis.rupiah, 500));
      expect(_nominal(editor), [465600, 50000, 250000]);
    });

    test('all three together land in one edit', () {
      final editor = _editor();

      editor.terapkanUmum(
        metode: MetodePencairan.transfer,
        jumlah: const JumlahUmum(JumlahJenis.persen, 50),
        potongan: const Potongan(PotonganJenis.persen, 10),
      );

      expect(_nominal(editor), [232800, 25000, 125000]);
      expect(editor.state.items.first.metode, MetodePencairan.transfer);
      expect(editor.state.totalPotongan, 23280 + 2500 + 12500);
    });

    test('Penuh brings back the whole saldo after a manual change', () {
      final editor = _editor()..setItemNominal('n-1', 1000);

      editor.terapkanUmum(jumlah: JumlahUmum.penuh);

      expect(_nominal(editor), [465600, 50000, 250000]);
    });

    test('applying nothing changes nothing, and is not an edit', () {
      final editor = _editor();
      final before = editor.state;

      editor.terapkanUmum();

      expect(editor.state, before);
      expect(editor.state.dirty, isFalse);
    });

    test('a jumlah lifts the server complaint about the items it rewrites', () {
      final editor = _editor();
      editor
          .emit(editor.state.copyWith(itemErrors: {'n-1': 'Nasabah nonaktif'}));

      editor.terapkanUmum(jumlah: JumlahUmum.penuh);

      expect(editor.state.itemErrors, isEmpty);
    });

    test('a tiny saldo can end at zero, which the editor then flags', () {
      final editor = DraftEditorCubit(_MockUseCases())
        ..startNew(const [
          Kandidat(id: 'n-9', kode: 'NAS-0009', nama: 'Receh', saldo: 1),
        ]);

      editor.terapkanUmum(jumlah: const JumlahUmum(JumlahJenis.persen, 50));

      expect(editor.state.items.single.nominal, 0);
      expect(editor.state.localError(editor.state.items.single), isNotNull);
    });
  });
}
