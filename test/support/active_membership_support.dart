import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// [AppStorage] kept in memory, so selection tests never touch a platform
/// channel. [putFailure] makes the next write throw, which is how the
/// "saving the choice failed" paths are exercised.
class MemoryAppStorage implements AppStorage {
  final values = <String, Object>{};
  Object? putFailure;
  var puts = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> put(String key, dynamic value) async {
    puts++;
    final failure = putFailure;
    if (failure != null) {
      putFailure = null;
      throw failure;
    }
    values[key] = value as Object;
  }

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

/// A membership row as `GET /nasabah/me` reports it. [dibuka] is the
/// backend's `dapat_dibuka`, which alone decides whether the bank can be
/// opened.
NasabahMembershipEntity membershipRow(
  String id, {
  String nama = 'Bank Sampah',
  MembershipStatus status = MembershipStatus.approved,
  bool isActive = true,
  bool? dibuka,
}) =>
    NasabahMembershipEntity(
      id: id,
      bankSampahId: 'bank-$id',
      bankSampahNama: nama,
      bankSampahKota: 'Depok',
      bankSampahAlamat: 'Jl. Mawar',
      status: status,
      isActive: isActive,
      dapatDibuka: dibuka ?? (status == MembershipStatus.approved && isActive),
    );
