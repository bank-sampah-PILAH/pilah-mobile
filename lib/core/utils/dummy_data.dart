import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Centralized mock data repository for the PILAH app.
/// All features should source their dummy data from here.
class DummyData {
  // ─────────────────────────────────────────────
  //  NASABAH
  // ─────────────────────────────────────────────

  static List<Map<String, dynamic>> nasabahList = [
    {
      'id': 'NAS-0891',
      'name': 'Ahmad Ridwan',
      'initials': 'AR',
      'phone': '0812-3456-7890',
      'address': 'Jl. Mawar No.12, RT.02/03, Kukusan',
      'balance': 'Rp 450.000',
      'isActive': true,
      'avatarColor': AppColors.greenLight,
      'textColor': AppColors.greenDark,
    },
    {
      'id': 'NAS-0892',
      'name': 'Budi Santoso',
      'initials': 'BS',
      'phone': '0857-1122-3344',
      'address': 'Jl. Kenanga No.5, RT.01/02, Beji',
      'balance': 'Rp 125.500',
      'isActive': true,
      'avatarColor': AppColors.statPurpleLight,
      'textColor': AppColors.statPurple,
    },
    {
      'id': 'NAS-0893',
      'name': 'Citra Wijaya',
      'initials': 'CW',
      'phone': '0896-9988-7766',
      'address': 'Jl. Dahlia No.8, RT.03/05, Pondok Cina',
      'balance': 'Rp 890.000',
      'isActive': true,
      'avatarColor': AppColors.avatarYellow,
      'textColor': AppColors.avatarYellowText,
    },
    {
      'id': 'NAS-0895',
      'name': 'Eko Prasetyo',
      'initials': 'EP',
      'phone': '0813-5678-9012',
      'address': 'Jl. Anggrek No.15, RT.04/01, Tanah Baru',
      'balance': 'Rp 215.000',
      'isActive': true,
      'avatarColor': const Color(0xFFE0F7FA),
      'textColor': const Color(0xFF00838F),
    },
    {
      'id': 'NAS-0894',
      'name': 'Dewi Putri',
      'initials': 'DP',
      'phone': '0811-2223-4455',
      'address': 'Jl. Melati No.3, RT.05/02, Kemiri Muka',
      'balance': 'Rp 35.000',
      'isActive': false,
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': const Color(0xFF9E9E9E),
    },
    {
      'id': 'NAS-0896',
      'name': 'Farida Hanum',
      'initials': 'FH',
      'phone': '0878-4321-0987',
      'address': 'Jl. Tulip No.22, RT.06/03, Srengseng Sawah',
      'balance': 'Rp 75.000',
      'isActive': false,
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': const Color(0xFF9E9E9E),
    },
  ];

  // ─────────────────────────────────────────────
  //  JENIS SAMPAH
  // ─────────────────────────────────────────────

  static List<Map<String, dynamic>> jenisSampahList = [
    {
      'name': 'Plastik PET',
      'price': 3500,
      'category': 'Plastik',
      'icon': Icons.recycling,
      'iconColor': Colors.green,
      'isActive': true,
    },
    {
      'name': 'Kertas HVS',
      'price': 2000,
      'category': 'Kertas',
      'icon': Icons.description,
      'iconColor': Colors.grey,
      'isActive': true,
    },
    {
      'name': 'Kardus',
      'price': 1500,
      'category': 'Kertas',
      'icon': Icons.inventory_2,
      'iconColor': Colors.brown,
      'isActive': true,
    },
    {
      'name': 'Logam Besi',
      'price': 4000,
      'category': 'Logam',
      'icon': Icons.settings,
      'iconColor': Colors.blueGrey,
      'isActive': true,
    },
    {
      'name': 'Aluminium',
      'price': 8000,
      'category': 'Logam',
      'icon': Icons.ad_units,
      'iconColor': Colors.redAccent,
      'isActive': true,
    },
  ];

  // ─────────────────────────────────────────────
  //  TRANSAKSI
  // ─────────────────────────────────────────────

  static List<Map<String, dynamic>> transaksiList = [
    {
      'header': 'HARI INI',
      'transactions': [
        {
          'initials': 'BS',
          'avatarColor': AppColors.greenLight,
          'textColor': AppColors.greenDark,
          'name': 'Budi Santoso',
          'subtitle': 'Plastik • 5.2 kg',
          'amount': '+Rp 15.600',
          'isWaSuccess': true,
          'time': '09:45',
          'balance': 'Rp 141.100',
          'items': [
            {'jenis': 'Plastik PET', 'berat': '5.2 kg', 'harga': 'Rp 3.000', 'subtotal': 'Rp 15.600'},
          ],
        },
        {
          'initials': 'WS',
          'avatarColor': AppColors.avatarYellow,
          'textColor': AppColors.avatarYellowText,
          'name': 'Warung Bu Siti',
          'subtitle': 'Logam • 2.1 kg',
          'amount': '+Rp 10.500',
          'isWaSuccess': false,
          'time': '08:30',
          'balance': 'Rp 45.500',
          'items': [
            {'jenis': 'Logam Besi', 'berat': '2.1 kg', 'harga': 'Rp 5.000', 'subtotal': 'Rp 10.500'},
          ],
        },
      ],
    },
    {
      'header': 'KEMARIN',
      'transactions': [
        {
          'initials': 'KD',
          'avatarColor': const Color(0xFFE8EAF6),
          'textColor': const Color(0xFF3F51B5),
          'name': 'Kantor Desa Mekar',
          'subtitle': 'Kertas • 12.0 kg',
          'amount': '+Rp 24.000',
          'isWaSuccess': true,
          'time': null,
          'balance': 'Rp 224.000',
          'items': [
            {'jenis': 'Kertas HVS', 'berat': '12.0 kg', 'harga': 'Rp 2.000', 'subtotal': 'Rp 24.000'},
          ],
        },
        {
          'initials': 'AY',
          'avatarColor': AppColors.greenLight,
          'textColor': AppColors.greenDark,
          'name': 'Ahmad Yani',
          'subtitle': 'Plastik • 3.5 kg',
          'amount': '+Rp 10.500',
          'isWaSuccess': true,
          'time': null,
          'balance': 'Rp 50.500',
          'items': [
            {'jenis': 'Plastik PET', 'berat': '3.5 kg', 'harga': 'Rp 3.000', 'subtotal': 'Rp 10.500'},
          ],
        },
      ],
    },
    {
      'header': '3 HARI LALU',
      'transactions': [
        {
          'initials': 'CW',
          'avatarColor': const Color(0xFFFCE4EC),
          'textColor': const Color(0xFFE91E63),
          'name': 'Citra Wijaya',
          'subtitle': 'Aluminium • 1.8 kg',
          'amount': '+Rp 14.400',
          'isWaSuccess': false,
          'time': null,
          'balance': 'Rp 104.400',
          'items': [
            {'jenis': 'Aluminium', 'berat': '1.8 kg', 'harga': 'Rp 8.000', 'subtotal': 'Rp 14.400'},
          ],
        },
      ],
    },
  ];
}
