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
  draf,
  diterbitkan,
  dibatalkan,
  selesai;

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
