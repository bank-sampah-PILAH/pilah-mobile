import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';

/// Shows the nasabah's own profile and lets them edit the fields the backend
/// allows (nama, no_hp, jenis_kelamin, tanggal_lahir, alamat). Email, role and
/// id are always read-only.
class ProfilNasabahPage extends StatelessWidget {
  const ProfilNasabahPage({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppLocations.dashboard);
    }
  }

  void _logout(BuildContext context) =>
      context.read<AuthenticationBloc>().add(LogoutRequested());

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          return Scaffold(
            backgroundColor: NasabahStyle.background,
            appBar: AppBar(
              backgroundColor: NasabahStyle.background,
              surfaceTintColor: Colors.transparent,
              title: Text('Profil',
                  style: NasabahStyle.text(20, weight: FontWeight.w700)),
              leading: IconButton(
                  tooltip: 'Kembali ke Beranda',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _back(context)),
            ),
            body: SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: NasabahStyle.maxWidth),
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (auth?.role != 'nasabah')
                                Text('Silakan masuk untuk melihat profil Anda.',
                                    style: NasabahStyle.text(15))
                              else
                                NasabahResource<NasabahIdentity>(
                                  key: ValueKey((auth!.id, auth.email)),
                                  load: () => di<NasabahRepository>().profile(),
                                  builder: (context, identity) => _ProfileBody(
                                      key: ObjectKey(identity),
                                      identity: identity,
                                      onLogout: () => _logout(context)),
                                ),
                            ])))),
          );
        },
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => NasabahCard(
      padding: 24,
      radius: 24,
      child: Column(children: [
        CircleAvatar(
            radius: 36,
            backgroundColor: NasabahStyle.emeraldLight,
            child: Text(
                name.isEmpty ? 'N' : name.characters.first.toUpperCase(),
                style: NasabahStyle.text(28,
                    weight: FontWeight.w700, color: NasabahStyle.emeraldDark))),
        const SizedBox(height: 16),
        Text(name.isEmpty ? 'Nama belum tersedia' : name,
            textAlign: TextAlign.center,
            style: NasabahStyle.text(20, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: NasabahStyle.emeraldLight,
                borderRadius: BorderRadius.circular(8)),
            child: Text('Nasabah',
                style: NasabahStyle.text(13,
                    weight: FontWeight.w600, color: NasabahStyle.emeraldDark))),
      ]));
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email});
  final String email;
  @override
  Widget build(BuildContext context) => NasabahCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.mail_outline, color: NasabahStyle.emerald),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EMAIL',
              style: NasabahStyle.text(11,
                  weight: FontWeight.w600, color: NasabahStyle.labelMuted)),
          const SizedBox(height: 4),
          Text(email.isEmpty ? 'Email belum tersedia' : email,
              style: NasabahStyle.text(15)),
        ])),
      ]));
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => NasabahCard(
      padding: 20,
      radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  color: NasabahStyle.emeraldLight, shape: BoxShape.circle),
              child: const Icon(Icons.logout,
                  color: NasabahStyle.emeraldDark, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Keluar dari Akun',
                    style: NasabahStyle.text(15, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Anda perlu masuk kembali untuk mengakses akun ini.',
                    style: NasabahStyle.text(13, color: NasabahStyle.muted)),
              ])),
        ]),
        const SizedBox(height: 16),
        SizedBox(
            height: 46,
            child: OutlinedButton(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NasabahStyle.line),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('Keluar',
                    style: NasabahStyle.text(15, weight: FontWeight.w600)))),
      ]));
}

String _jenisKelaminLabel(String value) => switch (value) {
      'laki-laki' => 'Laki-laki',
      'perempuan' => 'Perempuan',
      _ => 'Belum diisi',
    };

/// Owns the nasabah's editable fields locally so a save reflects instantly —
/// [NasabahResource] only knows how to re-run its GET, not merge a PATCH
/// result back into the tree above it.
class _ProfileBody extends StatefulWidget {
  const _ProfileBody(
      {super.key, required this.identity, required this.onLogout});
  final NasabahIdentity identity;
  final VoidCallback onLogout;
  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  late NasabahIdentity _identity = widget.identity;
  bool _editing = false;
  bool _saving = false;
  String? _error;
  late final _namaCtrl = TextEditingController(text: _identity.name);
  late final _noHpCtrl = TextEditingController(text: _identity.noHp);
  late final _alamatCtrl = TextEditingController(text: _identity.alamat);
  late String _jenisKelamin = _identity.jenisKelamin;
  DateTime? _tanggalLahir;

  @override
  void initState() {
    super.initState();
    _tanggalLahir = _identity.tanggalLahir;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _resetFields() {
    _namaCtrl.text = _identity.name;
    _noHpCtrl.text = _identity.noHp;
    _alamatCtrl.text = _identity.alamat;
    _jenisKelamin = _identity.jenisKelamin;
    _tanggalLahir = _identity.tanggalLahir;
  }

  void _startEdit() => setState(() {
        _resetFields();
        _editing = true;
        _error = null;
      });

  void _cancel() => setState(() {
        _resetFields();
        _editing = false;
        _error = null;
      });

  bool _sameDate(DateTime? a, DateTime? b) =>
      a == null && b == null ||
      (a != null &&
          b != null &&
          a.year == b.year &&
          a.month == b.month &&
          a.day == b.day);

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      // The app theme's primary is teal-blue; this screen speaks emerald.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: NasabahStyle.emerald,
              onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final nama = _namaCtrl.text.trim();
    final noHp = _noHpCtrl.text.trim();
    final alamat = _alamatCtrl.text.trim();
    try {
      final updated = await di<NasabahRepository>().updateProfile(
        nama: nama != _identity.name ? nama : null,
        noHp: noHp != _identity.noHp ? noHp : null,
        jenisKelamin:
            _jenisKelamin != _identity.jenisKelamin ? _jenisKelamin : null,
        tanggalLahir:
            _sameDate(_tanggalLahir, _identity.tanggalLahir)
                ? null
                : _tanggalLahir,
        alamat: alamat != _identity.alamat ? alamat : null,
      );
      if (!mounted) return;
      setState(() {
        _identity = updated;
        _editing = false;
        _saving = false;
      });
      _resetFields();
    } on NasabahApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Perubahan gagal disimpan. Periksa koneksi dan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityCard(name: _identity.name.trim()),
          const SizedBox(height: 24),
          Text('Informasi Akun',
              style: NasabahStyle.text(17, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          _AccountCard(email: _identity.email.trim()),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Informasi Pribadi',
                  style: NasabahStyle.text(17, weight: FontWeight.w600)),
              if (!_editing)
                IconButton(
                    tooltip: 'Ubah profil',
                    onPressed: _startEdit,
                    icon: const Icon(Icons.edit_outlined,
                        color: NasabahStyle.emerald)),
            ],
          ),
          const SizedBox(height: 12),
          _editing
              ? _ProfileEditForm(
                  namaCtrl: _namaCtrl,
                  noHpCtrl: _noHpCtrl,
                  alamatCtrl: _alamatCtrl,
                  jenisKelamin: _jenisKelamin,
                  tanggalLahir: _tanggalLahir,
                  saving: _saving,
                  error: _error,
                  onJenisKelamin: (v) => setState(() => _jenisKelamin = v),
                  onPickTanggalLahir: _pickTanggalLahir,
                  onCancel: _saving ? null : _cancel,
                  onSave: _saving ? null : _save,
                )
              : _ProfileDetailsCard(identity: _identity),
          const SizedBox(height: 24),
          _LogoutCard(onLogout: widget.onLogout),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: NasabahStyle.emerald),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: NasabahStyle.text(11,
                  weight: FontWeight.w600, color: NasabahStyle.labelMuted)),
          const SizedBox(height: 4),
          Text(value, style: NasabahStyle.text(15)),
        ])),
      ]);
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.identity});
  final NasabahIdentity identity;
  @override
  Widget build(BuildContext context) => NasabahCard(
        child: Column(children: [
          _DetailRow(
              icon: Icons.phone_iphone_outlined,
              label: 'NOMOR HP',
              value: identity.noHp.isEmpty ? 'Belum diisi' : identity.noHp),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: NasabahStyle.line)),
          _DetailRow(
              icon: Icons.wc_outlined,
              label: 'JENIS KELAMIN',
              value: _jenisKelaminLabel(identity.jenisKelamin)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: NasabahStyle.line)),
          _DetailRow(
              icon: Icons.cake_outlined,
              label: 'TANGGAL LAHIR',
              value: identity.tanggalLahir == null
                  ? 'Belum diisi'
                  : nasabahDate(identity.tanggalLahir!)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: NasabahStyle.line)),
          _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'ALAMAT',
              value: identity.alamat.isEmpty ? 'Belum diisi' : identity.alamat),
        ]),
      );
}

class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.namaCtrl,
    required this.noHpCtrl,
    required this.alamatCtrl,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.saving,
    required this.error,
    required this.onJenisKelamin,
    required this.onPickTanggalLahir,
    required this.onCancel,
    required this.onSave,
  });
  final TextEditingController namaCtrl, noHpCtrl, alamatCtrl;
  final String jenisKelamin;
  final DateTime? tanggalLahir;
  final bool saving;
  final String? error;
  final ValueChanged<String> onJenisKelamin;
  final VoidCallback onPickTanggalLahir;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: NasabahStyle.text(11,
              weight: FontWeight.w600, color: NasabahStyle.labelMuted)));

  Widget _genderOption(String value, String label) {
    final selected = jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onJenisKelamin(value),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: selected ? NasabahStyle.emerald : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? NasabahStyle.emerald : NasabahStyle.line)),
          child: Text(label,
              style: NasabahStyle.text(14,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : NasabahStyle.ink)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => NasabahCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _fieldLabel('NAMA LENGKAP'),
          TextField(
              controller: namaCtrl,
              style: NasabahStyle.text(15),
              cursorColor: NasabahStyle.emerald,
              decoration: NasabahStyle.input()),
          const SizedBox(height: 16),
          _fieldLabel('NOMOR HP'),
          TextField(
              controller: noHpCtrl,
              keyboardType: TextInputType.phone,
              style: NasabahStyle.text(15),
              cursorColor: NasabahStyle.emerald,
              decoration: NasabahStyle.input()),
          const SizedBox(height: 16),
          _fieldLabel('JENIS KELAMIN'),
          Row(children: [
            _genderOption('laki-laki', 'Laki-laki'),
            const SizedBox(width: 12),
            _genderOption('perempuan', 'Perempuan'),
          ]),
          const SizedBox(height: 16),
          _fieldLabel('TANGGAL LAHIR'),
          InkWell(
            onTap: onPickTanggalLahir,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  border: Border.all(color: NasabahStyle.line),
                  borderRadius:
                      BorderRadius.circular(NasabahStyle.inputRadius)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: NasabahStyle.emerald),
                const SizedBox(width: 8),
                Text(
                    tanggalLahir == null
                        ? 'Pilih tanggal lahir'
                        : nasabahDate(tanggalLahir!),
                    style: NasabahStyle.text(15)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('ALAMAT'),
          TextField(
              controller: alamatCtrl,
              maxLines: 3,
              style: NasabahStyle.text(15),
              cursorColor: NasabahStyle.emerald,
              decoration: NasabahStyle.input()),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!,
                style:
                    NasabahStyle.text(13, color: Colors.red.shade700)),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NasabahStyle.line),
                        foregroundColor: NasabahStyle.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Batal'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: NasabahStyle.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'))),
          ]),
        ]),
      );
}
