/// Format jarak untuk tampilan pengguna (PIL-314): meter di bawah 1 km,
/// kilometer dengan satu desimal sisanya — gaya Indonesia.
String formatJarakId(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
