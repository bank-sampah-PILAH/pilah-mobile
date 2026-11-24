import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_appeal_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/draft_editor_provider.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/draft_list_provider.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/pilih_nasabah_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_search_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/edit_pencairan_provider.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/revisi_pencairan_provider.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/riwayat_pencairan_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/riwayat/presentation/providers/riwayat_history_provider.dart';
import 'package:pilah_mobile/features/statement/presentation/providers/statement_export_provider.dart';
import 'package:pilah_mobile/features/superadmin/presentation/providers/superadmin_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/setoran_sheet_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_utils.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../application/role_switch_coordinator.dart';
import '../../data/role_session_store.dart';
import '../../data/role_switch_repository.dart';
import '../states/authentication_states.dart';
import 'authentication_provider.dart';

final roleSwitchProvider = ChangeNotifierProvider<RoleSwitchCoordinator>((ref) {
  final repository = RoleSwitchRepository(di<NetworkService>());
  final store = RoleSessionStore(di<SecureDatabase>(), di<NetworkUtils>());
  return RoleSwitchCoordinator(
    readSession: () {
      final state = ref.read(authenticationProvider);
      return state is Authenticated ? state.authEntity : null;
    },
    requestRole: repository.request,
    persistSession: store.save,
    resetRoleState: () => resetRoleScopedState(ref),
    publishSession: (auth) => ref.read(authenticationProvider.notifier).applyRoleSession(auth),
  );
});

void resetRoleScopedState(Ref ref) {
  if (ref.exists(nasabahProvider)) ref.read(nasabahProvider.notifier).reset();
  if (ref.exists(hargaProvider)) ref.read(hargaProvider.notifier).reset();
  if (ref.exists(jadwalProvider)) ref.read(jadwalProvider.notifier).reset();
  if (ref.exists(pengumumanProvider)) ref.read(pengumumanProvider.notifier).reset();
  if (ref.exists(nasabahPengumumanProvider)) ref.read(nasabahPengumumanProvider.notifier).reset();
  if (ref.exists(transaksiProvider)) ref.read(transaksiProvider.notifier).reset();
  if (ref.exists(riwayatAktivitasProvider)) ref.read(riwayatAktivitasProvider.notifier).reset();
  if (ref.exists(profileProvider)) ref.read(profileProvider.notifier).reset();
  if (ref.exists(onboardingProvider)) {
    ref.read(onboardingProvider.notifier).clearProfileDraft();
  }
  ref.invalidate(nasabahAppealProvider);
  ref.invalidate(nasabahApprovalProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(recentActivityProvider);
  ref.invalidate(draftEditorProvider);
  ref.invalidate(draftListProvider);
  ref.invalidate(pilihNasabahProvider);
  ref.invalidate(hargaProvider);
  ref.invalidate(riwayatHargaProvider);
  ref.invalidate(jadwalProvider);
  ref.invalidate(nasabahProvider);
  ref.invalidate(nasabahSearchProvider);
  ref.invalidate(onboardingProvider);
  ref.invalidate(editPencairanProvider);
  ref.invalidate(revisiPencairanProvider);
  ref.invalidate(riwayatPencairanProvider);
  ref.invalidate(nasabahPengumumanProvider);
  ref.invalidate(pengumumanProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(riwayatHistoryProvider);
  ref.invalidate(statementExportProvider);
  ref.invalidate(superadminProvider);
  ref.invalidate(aktivitasSelectionProvider);
  ref.invalidate(riwayatAktivitasProvider);
  ref.invalidate(setoranSheetProvider);
  ref.invalidate(transaksiProvider);
}
