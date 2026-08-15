import 'package:flutter/material.dart';

class AgendaScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AgendaScreen({super.key, required this.userData});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  // Data Agenda Sekolah (Dapat ditambah manual oleh admin)
  final List<Map<String, String>> _agendaList = [
    {
      'tanggal': '17 Agustus 2026',
      'waktu': '07.30 WIB - Selesai',
      'judul': 'Upacara HUT RI ke-81 & Lomba Anak',
      'lokasi': 'Halaman Utama SD ZAHA',
      'kategori': 'Nasional / Sekolah',
    },
    {
      'tanggal': '25 Agustus 2026',
      'waktu': '08.00 - 11.00 WIB',
      'judul': 'Rapat Koordinasi Wali Murid & Guru',
      'lokasi': 'Aula Gedung Utama',
      'kategori': 'Rapat Resmi',
    },
    {
      'tanggal': '05 September 2026',
      'waktu': '07.30 - 10.00 WIB',
      'judul': 'Pemeriksaan Kesehatan Berkala Siswa',
      'lokasi': 'UKS / Ruang Kelas',
      'kategori': 'Kesehatan',
    },
    {
      'tanggal': '15 - 20 September 2026',
      'waktu': '07.30 WIB',
      'judul': 'Penilaian Tengah Semester (PTS) Ganjil',
      'lokasi': 'Ruang Kelas Masing-masing',
      'kategori': 'Akademik',
    },
  ];

  // Fungsi untuk menampilkan Dialog Input Agenda oleh Admin
  void _showAddAgendaDialog() {
    final TextEditingController tanggalController = TextEditingController();
    final TextEditingController waktuController = TextEditingController();
    final TextEditingController judulController = TextEditingController();
    final TextEditingController lokasiController = TextEditingController();
    final TextEditingController kategoriController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Agenda Kegiatan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tanggalController, decoration: const InputDecoration(labelText: 'Tanggal (Cth: 10 Oktober 2026)')),
                TextField(controller: waktuController, decoration: const InputDecoration(labelText: 'Waktu (Cth: 08.00 - Selesai)')),
                TextField(controller: judulController, decoration: const InputDecoration(labelText: 'Judul / Nama Kegiatan')),
                TextField(controller: lokasiController, decoration: const InputDecoration(labelText: 'Lokasi Kegiatan')),
                TextField(controller: kategoriController, decoration: const InputDecoration(labelText: 'Kategori (Cth: Akademik / Umum)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800], foregroundColor: Colors.white),
              onPressed: () {
                if (judulController.text.isNotEmpty && tanggalController.text.isNotEmpty) {
                  setState(() {
                    _agendaList.insert(0, {
                      'tanggal': tanggalController.text,
                      'waktu': waktuController.text.isEmpty ? '08.00 WIB' : waktuController.text,
                      'judul': judulController.text,
                      'lokasi': lokasiController.text.isEmpty ? 'SD ZAHA' : lokasiController.text,
                      'kategori': kategoriController.text.isEmpty ? 'Umum' : kategoriController.text,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agenda baru berhasil ditambahkan!')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah user yang login adalah Admin
    String role = widget.userData['role'] ?? '';
    bool isAdmin = role.toLowerCase().contains('admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Kegiatan Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _agendaList.length,
        itemBuilder: (context, index) {
          var item = _agendaList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['kategori']!,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple[800]),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(item['tanggal']!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['judul']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item['waktu']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item['lokasi']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Tombol Tambah Agenda hanya muncul jika yang login adalah Admin
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddAgendaDialog,
              backgroundColor: Colors.purple[800],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Agenda'),
            )
          : null,
    );
  }
}