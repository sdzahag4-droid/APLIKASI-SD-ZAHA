import 'package:flutter/material.dart';

class JadwalScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const JadwalScreen({super.key, required this.userData});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Minggu', 'Sabtu'];

  // Data Jadwal (Bisa ditambah manual oleh admin)
  final Map<String, List<Map<String, String>>> _jadwalData = {
    'Senin': [
      {'jam': '07.30 - 08.15', 'mapel': 'Upacara Bendera / Pend. Agama', 'guru': 'Tim Guru'},
      {'jam': '08.15 - 09.30', 'mapel': 'Matematika Dasar', 'guru': 'Ahmad Taufiq, S.Pd.'},
      {'jam': '09.45 - 11.00', 'mapel': 'Bahasa Indonesia', 'guru': 'Wali Kelas'},
    ],
    'Selasa': [
      {'jam': '07.30 - 09.00', 'mapel': 'IPA (Ilmu Pengetahuan Alam)', 'guru': 'Wali Kelas'},
      {'jam': '09.15 - 11.00', 'mapel': 'Bahasa Inggris', 'guru': 'Guru Mapel'},
    ],
    'Rabu': [
      {'jam': '07.30 - 08.45', 'mapel': 'Pendidikan Pancasila', 'guru': 'Wali Kelas'},
      {'jam': '08.45 - 10.00', 'mapel': 'Matematika Lanjutan', 'guru': 'Ahmad Taufiq, S.Pd.'},
    ],
    'Kamis': [
      {'jam': '07.30 - 08.45', 'mapel': 'PJOK (Olahraga)', 'guru': 'Guru Olahraga'},
      {'jam': '08.45 - 10.00', 'mapel': 'Bahasa Arab / Ke-NU-an', 'guru': 'Guru Diniyah'},
    ],
    'Minggu': [
      {'jam': '07.30 - 08.30', 'mapel': 'Jumat Bersih & Dhuha Berjamaah', 'guru': 'Semua Guru'},
      {'jam': '08.30 - 10.00', 'mapel': 'Matematika / Literasi', 'guru': 'Wali Kelas'},
    ],
    'Sabtu': [
      {'jam': '07.30 - 10.00', 'mapel': 'Ekstrakurikuler Pramuka', 'guru': 'Pembina Ekskul'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  // Fungsi untuk menampilkan Dialog Input Jadwal Manual oleh Admin
  void _showAddJadwalDialog() {
    String selectedDay = _days[0];
    final TextEditingController jamController = TextEditingController();
    final TextEditingController mapelController = TextEditingController();
    final TextEditingController guruController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Jadwal Pelajaran Manual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  items: _days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedDay = val;
                  },
                  decoration: const InputDecoration(labelText: 'Pilih Hari'),
                ),
                TextField(controller: jamController, decoration: const InputDecoration(labelText: 'Jam (Cth: 07.30 - 09.00)')),
                TextField(controller: mapelController, decoration: const InputDecoration(labelText: 'Mata Pelajaran')),
                TextField(controller: guruController, decoration: const InputDecoration(labelText: 'Nama Pengajar / Guru')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
              onPressed: () {
                if (jamController.text.isNotEmpty && mapelController.text.isNotEmpty) {
                  setState(() {
                    _jadwalData[selectedDay]?.add({
                      'jam': jamController.text,
                      'mapel': mapelController.text,
                      'guru': guruController.text.isEmpty ? '-' : guruController.text,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jadwal berhasil ditambahkan secara manual!')),
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
    // Cek apakah user yang login adalah Admin atau berhak menginput
    String role = widget.userData['role'] ?? '';
    bool isAdmin = role.toLowerCase().contains('admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan & Pelajaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((day) {
          final listJadwal = _jadwalData[day] ?? [];
          if (listJadwal.isEmpty) {
            return const Center(child: Text('Tidak ada jadwal / Libur', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listJadwal.length,
            itemBuilder: (context, index) {
              var item = listJadwal[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[150],
                    child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  ),
                  title: Text(item['mapel']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Pengajar: ${item['guru']}"),
                  trailing: Text(item['jam']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              );
            },
          );
        }).toList(),
      ),
      // Tombol Tambah Manual hanya muncul jika Admin
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddJadwalDialog,
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Jadwal'),
            )
          : null,
    );
  }
}