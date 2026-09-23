import 'package:flutter/material.dart';

/// RED-phase seam for the existing GET /nasabah/me/riwayat API.
/// The caller binds the authenticated membership; page starts at one.
typedef HistoryLoader = Future<Map<String, dynamic>> Function(int page);

class RiwayatNasabahPage extends StatelessWidget {
  const RiwayatNasabahPage({super.key, required this.loadPage});

  final HistoryLoader loadPage;

  @override
  Widget build(BuildContext context) {
    // Intentionally unimplemented: PIL-227 stops at RED.
    return const SizedBox.shrink();
  }
}
