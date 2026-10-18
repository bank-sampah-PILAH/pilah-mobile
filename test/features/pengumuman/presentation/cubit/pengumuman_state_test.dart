import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';

void main() {
  test('stateless states are equal to each other', () {
    // Non-const: identical const instances short-circuit before props runs.
    expect(PengumumanInitial(), PengumumanInitial());
    expect(PengumumanLoading(), PengumumanLoading());
  });

  test('errors with the same message are equal', () {
    expect(const PengumumanError('x'), const PengumumanError('x'));
    expect(const PengumumanError('x'), isNot(const PengumumanError('y')));
  });
}
