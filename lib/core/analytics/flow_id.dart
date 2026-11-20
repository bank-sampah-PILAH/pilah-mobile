import 'package:pilah_mobile/core/utils/uuid_v4.dart';

/// A random version 4 uuid that names one attempt at a task (`alur_id`), so a
/// funnel can count attempts and not only people. It is not an id of a person.
String newFlowId() => newUuidV4();
