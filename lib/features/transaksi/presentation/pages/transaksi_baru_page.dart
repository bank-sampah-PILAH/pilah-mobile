import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaksi_berhasil_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/transaction_summary_section.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/item_setoran_card.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/setoran_draft.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/wa_deeplink.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_outlined_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Satu jenis sampah hanya boleh muncul sekali (CPBI-08): backend
/// menggabungkan item jenis sama, jadi UI mencegahnya sejak awal.
/// Jenis belum dipilih (null) tidak dianggap duplikat: kartu kosong lebih dari
/// satu tidak saling bertabrakan dan edit berat di kartu kosong tetap lolos.
@visibleForTesting
bool jenisSampahSudahAda(
    List<Map<String, dynamic>> setoranItems, int index, String? newId) {
  if (newId == null) return false;
  return setoranItems
      .asMap()
      .entries
      .any((e) => e.key != index && e.value['jenis_sampah_id'] == newId);
}

@visibleForTesting
String newTransaksiIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class TransaksiBaruPage extends StatefulWidget {
  const TransaksiBaruPage({super.key});

  static const route = '/transaksi-baru';

  @override
  State<TransaksiBaruPage> createState() => _TransaksiBaruPageState();
}

class _TransaksiBaruPageState extends State<TransaksiBaruPage> {
  NasabahEntity? selectedCustomer;
  List<Map<String, dynamic>> setoranItems = [];
  bool _hasSubmitted = false;
  bool _isSaving = false;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    // The harga picker reads an app-scoped singleton that is otherwise only
    // populated by the Harga page. Load it here so the dropdown has options
    // even when arriving straight from the dashboard. The nasabah picker
    // fetches its own list when it opens, so it needs no preload.
    context.read<HargaCubit>().loadHarga();

    // The WhatsApp draft built on success renders the pengelola's saved
    // template, which lives in the app-scoped ProfileCubit and is otherwise only
    // populated by the Profile page. Fetched here — once per session, since a
    // template already in hand needs no refresh — so someone who goes straight
    // from the dashboard to a transaksi still gets their own wording instead of
    // silently falling back to the default.
    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state.waTemplate == null) {
      profileCubit.load(silent: true);
    }
  }

  /// Keadaan form sebagai draft, supaya aturan kelayakannya hidup di satu
  /// tempat dan dapat diuji tanpa widget.
  SetoranDraft get _draft => SetoranDraft(
        nasabahId: selectedCustomer?.id,
        items: setoranItems
            .map((item) => SetoranItemDraft(
                  jenisSampahId: item['jenis_sampah_id'] as String?,
                  berat: (item['berat'] as num?)?.toDouble() ?? 0,
                ))
            .toList(growable: false),
      );

  void _addItem() {
    setState(() {
      setoranItems.add(
          {'jenis': null, 'jenis_sampah_id': null, 'harga': 0, 'berat': 1.0});
    });
  }

  /// Tombol simpan. Satu definisi dipakai dua layout: di telepon ia menjadi
  /// bottomNavigationBar, di layar lebar ia duduk di panel samping.
  Widget _saveButton() => CustomPrimaryButton(
        title: _isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
        icon: Icons.save_outlined,
        onPressed: _isSaving ? null : _handleSubmit,
      );

  /// Pesan untuk kartu ke-[index]. Jenis diperiksa lebih dulu: tanpa jenis,
  /// beratnya belum berarti apa pun.
  String? _itemErrorText(int index) {
    if (index >= _draft.items.length) return null;
    final item = _draft.items[index];
    if (!item.hasJenis) return 'Pilih jenis sampah';
    if (!item.hasPositiveBerat) return 'Berat harus lebih dari 0';
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _hasSubmitted = true);

    if (!_draft.isValid) return;

    final idempotencyKey = _idempotencyKey ?? newTransaksiIdempotencyKey();
    _idempotencyKey = idempotencyKey;
    final request = TransaksiRequest(
      nasabahId: selectedCustomer!.id,
      idempotencyKey: idempotencyKey,
      items: setoranItems
          .map((item) => ItemSetoranRequest(
                jenisSampahId: item['jenis_sampah_id'] as String,
                berat: (item['berat'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
    );

    final cubit = context.read<TransaksiCubit>();
    // Resolved before the await, so the WhatsApp template is read without
    // reaching back through a BuildContext across an async gap.
    final waTemplate = context.read<ProfileCubit>().state.waTemplate?.template;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isSaving = true);
    final result = await cubit.addTransaksi(request);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.error != null) {
      AppNotification.showError(
        context,
        title: 'Gagal Menyimpan',
        message: result.error!.displayMessage,
      );
      return;
    }

    // Refresh the shell tabs that stay alive and won't re-init on their own.
    // loadStats updates the dashboard metrics (Total Kas / Sampah / Transaksi);
    // the dashboard's "Aktivitas Terbaru" and the Laporan list are separate
    // cubits and each needs its own nudge — silent so those lists update in
    // place rather than flashing skeletons behind the success sheet. Fire-and-
    // forget (not awaited), matching loadStats, so the success modal isn't blocked.
    context.read<DashboardCubit>().loadStats();
    context.read<RecentActivityCubit>().load(silent: true);
    context.read<RiwayatAktivitasCubit>().load(silent: true);

    final created = result.created!;
    _idempotencyKey = null;

    // Built here, before the sheet opens, so the draft is a snapshot of what was
    // actually submitted rather than of whatever the form holds by the time the
    // pengelola taps the button.
    final waLink = buildWaSetoranLink(
      phone: selectedCustomer!.phone,
      nama: selectedCustomer!.name,
      items: setoranItems
          .map((item) => WaSetoranItem(
                namaSampah: (item['jenis'] as String?) ?? '',
                berat: (item['berat'] as num?)?.toDouble() ?? 0,
                // Only `{daftar_item_harga}` reads this; the form already holds
                // the per-kg price it used to compute the running total.
                hargaPerKg: (item['harga'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      customTemplate: waTemplate,
      // Backend-authoritative, not the form's running total — the server fills
      // each item's price from the master jenis sampah record, so its figures
      // are the ones the nasabah's balance actually moved by.
      total: created.totalNilai,
      saldo: created.saldoSetelah,
    );

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) => TransaksiBerhasilBottomSheet(
        customerName: selectedCustomer!.name,
        totalSetoran: created.totalNilai,
        newBalance: created.saldoSetelah,
        itemCount: created.itemCount,
        onKirimWaSelesai: () async {
          // Both navigators are resolved up front, before the await. Reaching
          // back for a BuildContext afterwards is what the
          // use_build_context_synchronously diagnostic was pointing at, and the
          // `mounted` check below can't cover it: that reports on this State,
          // while `sheetContext` belongs to the modal route this callback is
          // about to remove.
          final sheetNavigator = Navigator.of(sheetContext);
          final router = GoRouter.of(context);

          // TEMP (Twilio outage): the backend no longer dispatches this message,
          // so instead of asking it to (`cubit.resendWa`) we open WhatsApp with
          // the same text pre-filled and let the pengelola press send.
          // externalApplication hands the link to the installed WhatsApp rather
          // than an in-app webview.
          var opened = false;
          try {
            opened =
                await launchUrl(waLink, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Neither WhatsApp nor a browser could take the link, or the
            // platform refused the intent outright. Same outcome as `false`:
            // the transaksi is already saved, only the draft didn't open.
            opened = false;
          }
          if (!mounted) return;

          sheetNavigator.pop();
          router.pop();

          // Deferred rather than raised here. A Flushbar shows itself by
          // pushing a route, and Navigator anchors an imperatively pushed route
          // to the page-based one beneath it — in this frame that is a page
          // already on its way out, so the toast would be torn down along with
          // it. [AppNotification.afterNavigation] waits for the destination to
          // settle and shows on the root navigator instead.
          if (opened) {
            // Deliberately not "terkirim": all that happened is that a draft was
            // opened. The pengelola still has to press send inside WhatsApp, and
            // claiming otherwise would leave them thinking the nasabah was
            // notified when they closed the draft.
            AppNotification.afterNavigation(
              (toastContext) => AppNotification.showSuccess(
                toastContext,
                title: 'Berhasil',
                message:
                    'Transaksi disimpan. Pesan WhatsApp sudah disiapkan — tekan kirim di WhatsApp.',
              ),
            );
          } else {
            // The transaksi itself was saved — only the WhatsApp draft failed to
            // open. Red would read as "your transaction didn't go through".
            AppNotification.afterNavigation(
              (toastContext) => AppNotification.showWarning(
                toastContext,
                title: 'Peringatan',
                message:
                    'Transaksi disimpan, namun WhatsApp tidak dapat dibuka. Silakan hubungi nasabah secara manual.',
              ),
            );
          }
        },
      ),
    );
  }

  int get grandTotal {
    return setoranItems.fold(0, (sum, item) {
      final harga = item['harga'] as int? ?? 0;
      final berat = item['berat'] as num? ?? 1.0;
      return sum + (harga * berat).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lebar jendela menentukan apakah ringkasan menemani isian atau
    // mengikutinya. Di bawah expanded tidak ada ruang untuk dua kolom, jadi
    // layout telepon dipertahankan apa adanya.
    final sideBySide = context.layoutBreakpoint == LayoutBreakpoint.expanded;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ContentBounds(
            child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: Colors.grey[800], size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Transaksi Baru',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: PILIH NASABAH
                          Text(
                            'PILIH NASABAH',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PilihNasabahSection(
                            selectedCustomer: selectedCustomer,
                            onCustomerSelected: (customer) {
                              setState(() {
                                selectedCustomer = customer;
                              });
                            },
                            hasError: _hasSubmitted && selectedCustomer == null,
                            errorText: 'Nasabah harus dipilih',
                          ),
                          const SizedBox(height: 24),

                          // Section 2: DAFTAR SETORAN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DAFTAR SETORAN',
                                style: AppTextStyle.extraSmall.copyWith(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '${setoranItems.length} item',
                                style: AppTextStyle.small.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Items or Empty State
                          if (setoranItems.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: (_hasSubmitted &&
                                                setoranItems.isEmpty)
                                            ? const Color(0xFFDC2626)
                                            : Colors.grey[300]!,
                                        width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(Icons.add,
                                            color: Colors.grey[400], size: 24),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Belum Ada Item Setoran',
                                        style: AppTextStyle.title1.copyWith(
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap tombol di bawah untuk menambah item.',
                                        style: AppTextStyle.small.copyWith(
                                          color: Colors.grey[400],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_hasSubmitted && setoranItems.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Daftar setoran tidak boleh kosong',
                                      style: AppTextStyle.small.copyWith(
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            Column(
                              children:
                                  List.generate(setoranItems.length, (index) {
                                return ItemSetoranCard(
                                  index: index,
                                  itemData: setoranItems[index],
                                  hasError: _hasSubmitted &&
                                      _draft.invalidItemIndexes.contains(index),
                                  errorText: _itemErrorText(index),
                                  onChanged: (updatedItem) {
                                    final newId = updatedItem['jenis_sampah_id']
                                        as String?;
                                    final bool duplicateExists =
                                        jenisSampahSudahAda(
                                            setoranItems, index, newId);
                                    if (duplicateExists) {
                                      AppNotification.showWarning(
                                        context,
                                        title: 'Jenis Sudah Dipilih',
                                        message:
                                            'Jenis sampah ini sudah ada di daftar item. Ubah berat pada item yang sudah ada.',
                                      );
                                      return;
                                    }
                                    setState(() {
                                      setoranItems[index] = updatedItem;
                                    });
                                  },
                                  onDelete: () {
                                    setState(() {
                                      setoranItems.removeAt(index);
                                    });
                                    AppNotification.showSuccess(
                                      context,
                                      title: 'Item Dihapus',
                                      message: 'Item setoran berhasil dihapus.',
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 16),

                          // Add Item Button
                          CustomOutlinedButton(
                            title: 'Tambah Item Setoran',
                            icon: Icons.add,
                            borderColor: Colors.grey[300]!,
                            textColor: AppColors.greenDark,
                            onPressed: _addItem,
                          ),
                          const SizedBox(height: 24),

                          if (!sideBySide) ...[
                            TransactionSummarySection(grandTotal: grandTotal),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (sideBySide) ...[
                    const SizedBox(width: 24),
                    _SummaryPanel(
                      grandTotal: grandTotal,
                      saveButton: _saveButton(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        )),
      ),
      bottomNavigationBar: sideBySide
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_saveButton()],
                ),
              ),
            ),
    );
  }
}

/// Panel kanan pada layar lebar: ringkasan dan tombol simpan tetap terlihat
/// sementara daftar item di kiri digulir.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.grandTotal, required this.saveButton});

  final int grandTotal;
  final Widget saveButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransactionSummarySection(grandTotal: grandTotal),
            const SizedBox(height: 16),
            saveButton,
          ],
        ),
      ),
    );
  }
}
