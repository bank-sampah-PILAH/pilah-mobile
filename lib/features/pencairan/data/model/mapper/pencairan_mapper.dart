import '../responses/pencairan_response.dart';
import '../../../domain/model/pencairan.dart';

class PencairanMapper {
  static Pencairan mapResponseToDomain(PencairanResponse response) {
    return Pencairan(id: response.id);
  }
}
