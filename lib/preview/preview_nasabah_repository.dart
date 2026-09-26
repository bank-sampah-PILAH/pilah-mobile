import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

/// Explicit offline fixture for the visual preview entrypoint only.
class PreviewNasabahRepository implements NasabahRepository {
  PreviewNasabahRepository(
      {this.name = 'Siti Aminah',
      this.email = 'preview@example.test',
      this.bankName = 'Bank Sampah Melati'});
  final String name, email, bankName;
  @override
  NetworkService get network => throw UnsupportedError('Offline preview');
  @override
  Future<NasabahHome> home({String? membershipId}) async => NasabahHome(
      await profile(),
      membershipId ?? 'preview-membership',
      await bank(''),
      await balance(''), const []);
  @override
  Future<NasabahIdentity> profile() async =>
      NasabahIdentity('preview-nasabah', name, email, 'nasabah');
  @override
  Future<NasabahBalance> balance(String membershipId) async =>
      const NasabahBalance('12500.50', null);
  @override
  Future<NasabahBank> bank(String membershipId) async =>
      NasabahBank(bankName, 'Jl. Melati', 'Depok', '08123456789');
  @override
  Future<NasabahHistory> history(String membershipId, {int page = 1}) async =>
      const NasabahHistory([], false);
}
