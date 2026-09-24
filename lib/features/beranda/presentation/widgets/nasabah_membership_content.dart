import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

/// Resolves the API's active membership, including explicit multi-bank choice.
class NasabahMembershipContent extends StatefulWidget {
  const NasabahMembershipContent(
      {super.key, this.membershipId, required this.builder});
  final String? membershipId;
  final Widget Function(String) builder;
  @override
  State<NasabahMembershipContent> createState() =>
      _NasabahMembershipContentState();
}

class _NasabahMembershipContentState extends State<NasabahMembershipContent> {
  Future<NasabahHome>? _request;
  @override
  void initState() {
    super.initState();
    if (widget.membershipId?.isNotEmpty != true) {
      _request = di<NasabahRepository>().home();
    }
  }

  void _load([String? id]) => setState(() {
        _request = di<NasabahRepository>().home(membershipId: id);
      });
  @override
  Widget build(BuildContext context) {
    final id = widget.membershipId;
    if (id != null && id.isNotEmpty) return widget.builder(id);
    return FutureBuilder<NasabahHome>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final api = error is NasabahApiException ? error : null;
            return Center(
                child: SingleChildScrollView(
                    child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(api?.message ?? 'Data gagal dimuat. Silakan coba lagi.'),
                for (final choice in api?.choices ?? <MembershipChoice>[])
                  TextButton(
                      onPressed: () => _load(choice.id),
                      child: Text(choice.bankName)),
                TextButton(
                    onPressed: () => _load(), child: const Text('Coba Lagi')),
              ]),
            )));
          }
          return widget.builder(snapshot.data!.membershipId);
        });
  }
}
