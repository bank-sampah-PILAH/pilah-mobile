import 'package:flutter_test/flutter_test.dart';

import '../../../support/onboarding_support.dart';
import '../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

Map<String, dynamic> _row(String id, String nama) => {
      'id': id,
      'nama': nama,
      'alamat': 'Jl. $nama',
      'kota': 'Depok',
    };

/// PIL-308 pagination on the registration bank picker: every page is read and
/// a bare legacy list still works.
void main() {
  late StubApi api;

  setUp(() => api = StubApi());

  test('follows the next links and concatenates every page', () async {
    api.onRequest('GET', _directory, json: (options) {
      final page = options.queryParameters['page']?.toString() ?? '1';
      return page == '1'
          ? {
              'count': 2,
              'previous': null,
              'next': 'http://api.test/api/v1/bank-sampah?page=2',
              'results': [_row('b1', 'Bank Satu')],
            }
          : {
              'count': 2,
              'previous': 'http://api.test/api/v1/bank-sampah?page=1',
              'next': null,
              'results': [_row('b2', 'Bank Dua')],
            };
    });

    final rows = await buildOnboardingDataSource(api).listBankSampahDirectory();

    expect(rows.map((b) => b.nama), ['Bank Satu', 'Bank Dua']);
    expect(
      api.requests.map((r) => r.query['page']).whereType<String>(),
      ['2'],
      reason: 'the second request follows the next link',
    );
  });

  test('a bare legacy list is still accepted', () async {
    api.on('GET', _directory, json: [_row('b1', 'Bank Satu')]);

    final rows = await buildOnboardingDataSource(api).listBankSampahDirectory();

    expect(rows.map((b) => b.nama), ['Bank Satu']);
    expect(api.requests, hasLength(1));
  });
}
