/// Nilai satu item setoran dalam rupiah penuh, dibulatkan ke bawah per item
/// seperti backend (`hitung_subtotal`), supaya pratinjau sama dengan yang
/// tersimpan. Berat paling banyak tiga desimal, jadi selisih kecil akibat
/// bilangan pecahan biner (1000 × 0,29 = 289,99999999999994) ditambal dulu.
int setoranSubtotal(num harga, num berat) => (harga * berat + 1e-9).floor();
