import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/search_analytics.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';

/// The session of searching the nasabah list, shared by the page that reports
/// it and the rows that end it.
final nasabahSearchProvider = Provider<SearchAnalytics>(
  (ref) => SearchAnalytics(ref.read(analyticsClientProvider), area: 'nasabah'),
);

/// A nasabah of the list was opened. When the list is showing a search, that is
/// the row it led to, and its position in the results is reported.
void nasabahSearchPicked(WidgetRef ref, String id) {
  // No search was ever reported, so there is nothing to end.
  if (!ref.exists(nasabahSearchProvider)) return;
  final state = ref.read(nasabahProvider);
  if (state is! NasabahLoaded) return;
  final index = state.nasabahList.indexWhere((nasabah) => nasabah.id == id);
  if (index >= 0) ref.read(nasabahSearchProvider).picked(position: index + 1);
}
