import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aplikasi_sd_zaha/config.dart';

class AbsensiScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AbsensiScreen({super.key, required this.userData});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Pilih jenis kehadiran, lalu tekan tombol di bawah.';
  bool _isSuccess = false;
  
  // Status absensi yang dipilih (Default: Absen Masuk)
  String _selectedStatus = 'Absen Masuk';

  // Daftar pilihan status absensi guru beserta batasan jamnya (dalam format desimal jam)
  final List<Map<String, dynamic>> _daftarStatus = [
    {
      'title': 'Absen Masuk', 
      'subtitle': 'Wajib GPS & Jam 05:00 - 07:30', 
      'pakaiGps': true, 
      'jamMulai': 5.0,   // 05:00
      'jamSelesai': 7.5, // 07:30
      'color': Colors.green
    },
    {
      'title': 'Izin', 
      'subtitle': 'Tanpa GPS & Jam 05:00 - 07:15', 
      'pakaiGps': false, 
      'jamMulai': 5.0,    // 05:00
      'jamSelesai': 7.25, // 07:15
      'color': Colors.blue
    },
    {
      'title': 'Terlambat', 
      'subtitle': 'Tanpa GPS & Jam 07:00 - 08:00', 
      'pakaiGps': false, 
      'jamMulai': 7.0,   // 07:00
      'jamSelesai': 8.0, // 08:00
      'color': Colors.amber.shade800
    },
    {
      'title': 'Sakit', 
      'subtitle': 'Tanpa GPS aktif (Bebas jam)', 
      'pakaiGps': false, 
      'jamMulai': 0.0, 
      'jamSelesai': 24.0,
      'color': Colors.orange
    },
    {
      'title': 'Cuti', 
      'subtitle': 'Tanpa GPS aktif (Bebas jam)', 
      'pakaiGps': false, 
      'jamMulai': 0.0, 
      'jamSelesai': 24.0,
      'color': Colors.purple
    },
    {
      'title': 'Tidak Masuk', 
      'subtitle': 'Tanpa GPS aktif (Bebas jam)', 
      'pakaiGps': false, 
      'jamMulai': 0.0, 
      'jamSelesai': 24.0,
      'color': Colors.red
    },
  ];

  // Helper untuk mengubah angka desimal jam menjadi string "HH:MM"
  String _formatJam(double jamDecimal) {
    int jam = jamDecimal.floor();
    int menit = ((jamDecimal - jam) * 60).round();
    return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
  }

  // Fungsi untuk mengirim data absensi ke Google Apps Script / Google Sheets
  Future<void> _kirimAbsensiKeServer({
    required String nama,
    required String status,
    required dynamic jarak,
    required dynamic lat,
    required dynamic lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "simpan_absensi",
          "nama": nama,         // Mengambil dari parameter 'required String nama'
          "jabatan": "Guru",    // Bisa diisi string jabatan atau parameter tambahan jika ada
          "status": status,     // Mengambil dari parameter 'required String status'
          "jarak": jarak,       // Mengambil dari parameter 'required dynamic jarak'
          "lat": lat,           // Mengambil dari parameter 'required dynamic lat'
          "lng": lng,           // Mengambil dari parameter 'required dynamic lng'
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          print("Data absensi berhasil masuk ke Google Sheets!");
        } else {
          print("Gagal dari server: ${res['message']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Terjadi kesalahan saat mengirim data ke server: $e");
    }
  }

  // Fungsi proses utama saat tombol submit ditekan
  Future<void> _prosesAbsensi() async {
    final String namaUser = widget.userData['nama'] ?? widget.userData['username'] ?? 'Guru/Karyawan';
    
    // Ambil konfigurasi status yang dipilih
    final statusConfig = _daftarStatus.firstWhere((element) => element['title'] == _selectedStatus);
    bool pakaiGps = statusConfig['pakaiGps'];
    double jamMulai = statusConfig['jamMulai'];
    double jamSelesai = statusConfig['jamSelesai'];

    // 1. CEK VALIDASI WAKTU
    DateTime sekarang = DateTime.now();
    double waktuSekarangDecimal = sekarang.hour + (sekarang.minute / 60.0);

    if (jamMulai != 0.0 && (waktuSekarangDecimal < jamMulai || waktuSekarangDecimal > jamSelesai)) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Gagal! Fitur "$_selectedStatus" hanya dapat dilakukan pada pukul '
            '${_formatJam(jamMulai)} - ${_formatJam(jamSelesai)} WIB.\n'
            '(Waktu perangkat Anda: ${sekarang.hour.toString().padLeft(2, '0')}:${sekarang.minute.toString().padLeft(2, '0')} WIB)';
      });
      return;
    }

    // 2. JIKA TIDAK PAKAI GPS (Izin, Terlambat, Sakit, Cuti, Tidak Masuk)
    if (!pakaiGps) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Mengirim data $_selectedStatus ke server...';
      });

      await _kirimAbsensiKeServer(
        nama: namaUser,
        status: _selectedStatus,
        jarak: "-",
        lat: "-",
        lng: "-",
      );

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'Berhasil! Status "$_selectedStatus" telah dicatat.';
      });
      return;
    }

    // 3. JIKA PAKAI GPS (Absen Masuk)
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mendapatkan lokasi GPS Anda...';
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Layanan GPS tidak aktif. Harap aktifkan GPS Anda.';
          _isSuccess = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Izin akses lokasi ditolak.';
            _isSuccess = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Izin lokasi ditolak secara permanen di pengaturan HP.';
          _isSuccess = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double schoolLat = -7.787930; // Koordinat sekolah
      double schoolLng = 113.375122; // Koordinat sekolah
      double maxRadiusMeter = 50.0;

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        schoolLat,
        schoolLng,
      );

      setState(() {
        _isLoading = false;
        if (distanceInMeters <= maxRadiusMeter) {
          _isSuccess = true;
          _statusMessage = 'Absen Masuk Berhasil! Dalam area sekolah '
              '(${distanceInMeters.toStringAsFixed(1)} meter dari titik pusat).';
        } else {
          _isSuccess = false;
          _statusMessage = 'Absen Gagal! Anda di luar area sekolah '
              '(${distanceInMeters.toStringAsFixed(1)} meter). Maksimal radius 50 meter.';
        }
      });

      if (_isSuccess) {
        await _kirimAbsensiKeServer(
          nama: namaUser,
          status: _selectedStatus,
          jarak: double.parse(distanceInMeters.toStringAsFixed(2)),
          lat: position.latitude,
          lng: position.longitude,
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Terjadi kesalahan saat mendeteksi lokasi: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final namaUser = widget.userData['nama'] ?? widget.userData['username'] ?? 'Guru/Karyawan';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Absensi Guru'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.fingerprint, size: 70, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              'Halo, $namaUser',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Silakan pilih jenis keterangan absensi Anda di bawah ini:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Dropdown / Pilihan Status Absensi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: _daftarStatus.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['title'],
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: item['color']),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(item['subtitle'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                      _statusMessage = 'Dipilih: $_selectedStatus. Tekan tombol untuk mengirim.';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Kotak Informasi Status Pesan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isLoading 
                    ? Colors.blue.shade50 
                    : (_isSuccess ? Colors.green.shade50 : Colors.orange.shade50),
                border: Border.all(
                  color: _isLoading 
                      ? Colors.blue 
                      : (_isSuccess ? Colors.green : Colors.orange),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isLoading 
                      ? Colors.blue.shade800 
                      : (_isSuccess ? Colors.green.shade800 : Colors.orange.shade900),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Tombol Kirim / Aksi Absen
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _prosesAbsensi,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Memproses...' : 'Kirim Absen ($_selectedStatus)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}