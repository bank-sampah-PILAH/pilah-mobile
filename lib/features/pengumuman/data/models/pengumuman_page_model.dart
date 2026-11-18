import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_model.dart';

class PengumumanPageModel {
  final List<PengumumanModel> items;
  final int totalCount;
  final bool hasMore;

  const PengumumanPageModel({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  factory PengumumanPageModel.fromJson(Map<String, dynamic> json) =>
      PengumumanPageModel(
        items: (json['results'] as List<dynamic>? ?? const [])
            .map((item) =>
                PengumumanModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalCount: json['count'] as int? ?? 0,
        hasMore: json['next'] != null,
      );
}
