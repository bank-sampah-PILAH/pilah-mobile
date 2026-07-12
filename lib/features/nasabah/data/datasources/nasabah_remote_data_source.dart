import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahRemoteDataSource {
  Future<List<NasabahModel>> getNasabah();
  Future<NasabahRingkasan> getNasabahRingkasan(String id);
  Future<NasabahModel> addNasabah(NasabahRequest request);
  Future<NasabahModel> updateNasabah(String id, NasabahRequest request);
  Future<void> setStatus(String id, bool isActive);
}
