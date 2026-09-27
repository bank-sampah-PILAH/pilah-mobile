import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';

class JadwalPageModel {
  final List<JadwalModel> items;
  final int totalCount;
  final bool hasMore;

  const JadwalPageModel({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  factory JadwalPageModel.fromJson(Map<String, dynamic> json) =>
      JadwalPageModel(
        items: (json['results'] as List<dynamic>? ?? const [])
            .map((item) => JadwalModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalCount: json['count'] as int? ?? 0,
        hasMore: json['next'] != null,
      );
}
