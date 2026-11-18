import 'aktivitas_entity.dart';
import 'aktivitas_summary.dart';

class AktivitasPage {
  const AktivitasPage(this.items, this.hasNext,
      {this.summary, this.totalCount = 0});
  final List<ActivitasEntity> items;
  final bool hasNext;
  final int totalCount;
  final AktivitasSummary? summary;
}
