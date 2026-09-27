import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/data/datasources/bank_sampah_approval_remote_data_source.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

class _MockNetworkService extends Mock implements NetworkService {}

void main() {
  test('maps a successful GET nasabah/me response to memberships', () async {
    final network = _MockNetworkService();
    when(() => network.get('/api/v1/nasabah/me')).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/nasabah/me'),
        data: [
          {
            'id': 'membership-1',
            'bank_sampah': {
              'id': 'bank-1',
              'nama': 'Bank Sampah Sejahtera',
              'kota': 'Bandung',
              'alamat': 'Jl. Merdeka No. 10',
            },
            'status': 'pending',
            'is_active': true,
            'alasan_penolakan': null,
            'riwayat_persetujuan': [
              {
                'status': 'rejected',
                'catatan': 'Dokumen tidak lengkap',
                'created_at': '2026-09-20T10:00:00Z',
              },
              {
                'status': 'approved',
                'catatan': '',
                'created_at': '2026-09-25T08:00:00Z',
              },
            ],
          },
        ],
      ),
    );

    final memberships =
        await BankSampahApprovalRemoteDataSourceImpl(network).getMemberships();

    expect(memberships, hasLength(1));
    final membership = memberships.single;
    expect(membership.id, 'membership-1');
    expect(membership.bankSampahId, 'bank-1');
    expect(membership.bankSampahNama, 'Bank Sampah Sejahtera');
    expect(membership.bankSampahKota, 'Bandung');
    expect(membership.bankSampahAlamat, 'Jl. Merdeka No. 10');
    expect(membership.status, MembershipStatus.pending);
    expect(membership.isActive, isTrue);
    expect(membership.alasanPenolakan, isNull);
    expect(membership.riwayat, hasLength(2));
    expect(membership.riwayat[0].status, ApprovalLogStatus.rejected);
    expect(membership.riwayat[0].catatan, 'Dokumen tidak lengkap');
    expect(membership.riwayat[0].createdAt, DateTime.utc(2026, 9, 20, 10));
    expect(membership.riwayat[1].status, ApprovalLogStatus.approved);
  });
}
