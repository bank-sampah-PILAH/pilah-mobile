import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';

void main() {
  test('states with the same content are equal and carry their props', () {
    final a = CariBankLoaded(
      items: const [],
      hasMore: true,
      isLoadingMore: false,
      totalCount: 3,
      searchQuery: 'mawar',
      kotaFilter: 'Depok',
      dalamRadiusKm: 5,
    );
    final b = CariBankLoaded(
      items: const [],
      hasMore: true,
      isLoadingMore: false,
      totalCount: 3,
      searchQuery: 'mawar',
      kotaFilter: 'Depok',
      dalamRadiusKm: 5,
    );
    expect(a, b);
    expect(a.props, b.props);
    // A page-2 failure is part of the loaded state, not a separate error one.
    expect(
      CariBankLoaded(
        items: const [],
        hasMore: true,
        isLoadingMore: false,
        totalCount: 3,
        searchQuery: 'mawar',
        kotaFilter: 'Depok',
        loadMoreError: 'gagal',
      ),
      isNot(a),
    );
    expect(CariBankInitial().props, isEmpty);
    expect(CariBankLoading().props, isEmpty);
    expect(const CariBankError('gagal').props, ['gagal']);
  });
}
