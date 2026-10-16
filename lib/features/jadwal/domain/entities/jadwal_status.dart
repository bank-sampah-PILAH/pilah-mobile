/// Aksi yang dapat mengubah status sebuah jadwal.
enum JadwalAction {
  batalkan,
  terbitkan,
  selesaikan,
}

/// Status sebuah jadwal, beserta aksi yang sah dari status tersebut.
///
/// Aturan transisi diletakkan pada status itu sendiri, bukan pada widget yang
/// kebetulan menggambar tombolnya, supaya hanya ada satu tempat yang perlu
/// diubah ketika status baru ditambahkan.
enum JadwalStatus {
  draf('draft'),
  diterbitkan('diterbitkan'),
  dibatalkan('dibatalkan'),
  selesai('selesai');

  const JadwalStatus(this.wireValue);

  /// Nilai status sebagaimana dikirim API. Hanya `draf` yang ejaannya berbeda.
  final String wireValue;

  /// Status untuk [value] dari API, atau null bila tidak dikenali.
  static JadwalStatus? fromWire(String value) {
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return null;
  }

  /// Aksi yang boleh dijalankan dari status ini.
  Set<JadwalAction> get availableActions => switch (this) {
        JadwalStatus.draf => const {
            JadwalAction.batalkan,
            JadwalAction.terbitkan,
          },
        JadwalStatus.diterbitkan => const {
            JadwalAction.batalkan,
            JadwalAction.selesaikan,
          },
        JadwalStatus.dibatalkan => const {},
        JadwalStatus.selesai => const {},
      };
}
