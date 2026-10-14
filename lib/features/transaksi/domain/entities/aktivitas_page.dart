import 'aktivitas_entity.dart';

class AktivitasPage {
  const AktivitasPage(this.items, this.hasNext);
  final List<ActivitasEntity> items;
  final bool hasNext;
}
