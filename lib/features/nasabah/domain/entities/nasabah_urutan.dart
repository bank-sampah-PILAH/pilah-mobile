/// Urutan server, selalu memakai nomor sebagai pemutus seri (PIL-442).
enum NasabahUrutan {
  nomor('nomor', 'Nomor'),
  nama('nama', 'Nama A–Z'),
  terbaru('terbaru', 'Terbaru bergabung'),
  saldoTerbesar('saldo_terbesar', 'Saldo terbesar'),
  saldoTerkecil('saldo_terkecil', 'Saldo terkecil');

  const NasabahUrutan(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
