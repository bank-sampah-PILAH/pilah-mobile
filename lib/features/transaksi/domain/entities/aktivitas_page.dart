import 'aktivitas_entity.dart';
import 'aktivitas_summary.dart';

class AktivitasPage {
  const AktivitasPage(this.items, this.hasNext, {this.summary});
  final List<ActivitasEntity> items;
  final bool hasNext;
  final AktivitasSummary? summary;
}
