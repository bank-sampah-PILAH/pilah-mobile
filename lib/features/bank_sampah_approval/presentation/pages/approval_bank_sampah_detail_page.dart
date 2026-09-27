import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// Detail view for one membership, pushed from [ApprovalBankSampahListView]
/// with the tapped [NasabahMembershipEntity] passed directly via GoRouter's
/// `extra` — the list already holds the full object, so this never re-fetches
/// by id.
class ApprovalBankSampahDetailPage extends StatelessWidget {
  final NasabahMembershipEntity membership;

  const ApprovalBankSampahDetailPage({super.key, required this.membership});

  static const route = '/approval-bank-sampah/detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(membership.bankSampahNama)),
      body: const SizedBox.shrink(),
    );
  }
}
