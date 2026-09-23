import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';

class JadwalPage extends StatefulWidget {
  static const route = '/jadwal';

  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  @override
  void initState() {
    super.initState();
    context.read<JadwalCubit>().loadJadwal();
  }

  void _openForm([JadwalEntity? initial]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<JadwalCubit>(),
        child: _JadwalForm(initial: initial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kegiatan')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'jadwal_page_fab',
        onPressed: _openForm,
        backgroundColor: AppColors.greenDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<JadwalCubit, JadwalState>(
        builder: (context, state) {
          if (state is JadwalInitial || state is JadwalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JadwalError) {
            return _RetryableMessage(
              message: state.message,
              buttonLabel: 'Coba Lagi',
              onPressed: () => context.read<JadwalCubit>().loadJadwal(),
            );
          }
          final items = (state as JadwalLoaded).items;
          if (items.isEmpty) {
            return _RetryableMessage(
              message: 'Belum ada jadwal kegiatan',
              buttonLabel: 'Muat Ulang',
              onPressed: () => context.read<JadwalCubit>().loadJadwal(),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<JadwalCubit>().loadJadwal(silent: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    onTap: () => _openForm(item),
                    leading: Icon(
                      item.jenisKegiatan == 'penimbangan'
                          ? Icons.scale_outlined
                          : Icons.payments_outlined,
                      color: AppColors.greenDark,
                    ),
                    title: Text(item.lokasi),
                    subtitle: Text(
                      '${_formatDateTime(item.mulaiPada.toLocal())}\n${_statusLabel(item.status)}',
                    ),
                    isThreeLine: true,
                    trailing: item.isOverlapping
                        ? const Tooltip(
                            message: 'Jadwal bertumpuk di lokasi yang sama',
                            child:
                                Icon(Icons.warning_amber, color: Colors.orange),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RetryableMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _RetryableMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
            ),
          ],
        ),
      );
}

class _JadwalForm extends StatefulWidget {
  final JadwalEntity? initial;

  const _JadwalForm({this.initial});

  @override
  State<_JadwalForm> createState() => _JadwalFormState();
}

class _JadwalFormState extends State<_JadwalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late String _activity;
  late String _audience;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _locationController = TextEditingController(text: initial?.lokasi ?? '');
    _descriptionController =
        TextEditingController(text: initial?.keterangan ?? '');
    _activity = initial?.jenisKegiatan ?? 'penimbangan';
    _audience = initial?.cakupanPenerima ?? 'semua_nasabah';
    _startsAt = initial?.mulaiPada.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    _endsAt = initial?.selesaiPada.toLocal() ??
        _startsAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _startsAt : _endsAt;
    final currentDate = DateUtils.dateOnly(current);
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = currentDate.isBefore(today) ? currentDate : today;
    final lastDate = today.add(const Duration(days: 730));
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate.isAfter(lastDate) ? lastDate : currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final value =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (start) {
        final duration = _endsAt.difference(_startsAt);
        _startsAt = value;
        _endsAt = value
            .add(duration.isNegative ? const Duration(hours: 2) : duration);
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.initial == null && _startsAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu mulai harus di masa depan')),
      );
      return;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Waktu selesai harus setelah waktu mulai')),
      );
      return;
    }
    final initial = widget.initial;
    final failure = await context.read<JadwalCubit>().saveJadwal(
          JadwalEntity(
            id: initial?.id ?? '',
            bankSampahId: initial?.bankSampahId ?? '',
            jenisKegiatan: _activity,
            mulaiPada: _startsAt,
            selesaiPada: _endsAt,
            lokasi: _locationController.text,
            keterangan: _descriptionController.text,
            cakupanPenerima: _audience,
            penerimaIds: initial?.penerimaIds ?? const [],
            status: initial?.status ?? 'draft',
            isOverlapping: initial?.isOverlapping ?? false,
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.displayMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.initial == null ? 'Buat Jadwal' : 'Ubah Jadwal',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _activity,
                  decoration:
                      const InputDecoration(labelText: 'Jenis kegiatan'),
                  items: const [
                    DropdownMenuItem(
                        value: 'penimbangan', child: Text('Penimbangan')),
                    DropdownMenuItem(
                        value: 'pencairan', child: Text('Pencairan')),
                  ],
                  onChanged: (value) => setState(() => _activity = value!),
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lokasi wajib diisi'
                      : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                  maxLines: 2,
                ),
                _DateTimeTile(
                  label: 'Mulai',
                  value: _startsAt,
                  onTap: () => _pickDateTime(start: true),
                ),
                _DateTimeTile(
                  label: 'Selesai',
                  value: _endsAt,
                  onTap: () => _pickDateTime(start: false),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  decoration:
                      const InputDecoration(labelText: 'Cakupan penerima'),
                  items: [
                    const DropdownMenuItem(
                      value: 'semua_nasabah',
                      child: Text('Semua nasabah'),
                    ),
                    if (widget.initial?.cakupanPenerima == 'nasabah_terpilih')
                      const DropdownMenuItem(
                        value: 'nasabah_terpilih',
                        child: Text('Nasabah terpilih'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _audience = value!),
                ),
                const SizedBox(height: 24),
                BlocBuilder<JadwalCubit, JadwalState>(
                  builder: (context, state) {
                    final isSaving = state is JadwalLoaded && state.isSaving;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving ? null : _submit,
                        child: Text(isSaving
                            ? 'Menyimpan...'
                            : widget.initial == null
                                ? 'Simpan Jadwal'
                                : 'Simpan Perubahan'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(_formatDateTime(value)),
      onTap: onTap,
    );
  }
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}, '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String _statusLabel(String status) => switch (status) {
      'draft' => 'Draf',
      'diterbitkan' => 'Diterbitkan',
      'dibatalkan' => 'Dibatalkan',
      'selesai' => 'Selesai',
      _ => status,
    };
