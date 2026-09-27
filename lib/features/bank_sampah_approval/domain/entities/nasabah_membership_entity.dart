/// Decision status of one entry in a membership's [ApprovalLogEntity] history.
enum ApprovalLogStatus { approved, rejected }

/// One decision recorded against a membership application (from
/// `riwayat_persetujuan` on `GET /nasabah/me`), newest-first as the backend
/// sends it.
class ApprovalLogEntity {
  final ApprovalLogStatus status;
  final String catatan;
  final DateTime createdAt;

  const ApprovalLogEntity({
    required this.status,
    required this.catatan,
    required this.createdAt,
  });

  factory ApprovalLogEntity.fromJson(Map<String, dynamic> json) {
    return ApprovalLogEntity(
      status: ApprovalLogStatus.values.byName(json['status'] as String),
      catatan: json['catatan']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Status of a nasabah's membership at one bank sampah unit.
enum MembershipStatus { pending, approved, rejected }

/// One row from `GET /nasabah/me`: a nasabah's membership at a single bank
/// sampah unit, plus the approval history behind its current [status].
///
/// A user can only hold one active/pending membership at a time today, but
/// the backend returns a list (one membership per row) so a future
/// concurrent-membership change doesn't require a shape rewrite here.
class NasabahMembershipEntity {
  final String id;
  final String bankSampahId;
  final String bankSampahNama;
  final String bankSampahKota;
  final MembershipStatus status;
  final bool isActive;

  /// Only non-null when [status] is [MembershipStatus.rejected].
  final String? alasanPenolakan;

  /// Newest-first, as the backend sends it. Empty for a fresh application
  /// with no decision yet.
  final List<ApprovalLogEntity> riwayat;

  const NasabahMembershipEntity({
    required this.id,
    required this.bankSampahId,
    required this.bankSampahNama,
    required this.bankSampahKota,
    required this.status,
    required this.isActive,
    this.alasanPenolakan,
    this.riwayat = const [],
  });

  factory NasabahMembershipEntity.fromJson(Map<String, dynamic> json) {
    final bank = json['bank_sampah'] as Map<String, dynamic>? ?? const {};
    final riwayat = (json['riwayat_persetujuan'] as List<dynamic>? ?? [])
        .map((e) => ApprovalLogEntity.fromJson(e as Map<String, dynamic>))
        .toList();
    return NasabahMembershipEntity(
      id: json['id']?.toString() ?? '',
      bankSampahId: bank['id']?.toString() ?? '',
      bankSampahNama: bank['nama']?.toString() ?? '',
      bankSampahKota: bank['kota']?.toString() ?? '',
      status: MembershipStatus.values.byName(json['status'] as String),
      isActive: json['is_active'] as bool? ?? false,
      alasanPenolakan: json['alasan_penolakan']?.toString(),
      riwayat: riwayat,
    );
  }
}
