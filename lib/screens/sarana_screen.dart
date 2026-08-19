import 'package:flutter/material.dart';

class SaranaScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SaranaScreen({super.key, required this.userData});

  @override
  State<SaranaScreen> createState() => _SaranaScreenState();
}

class _SaranaScreenState extends State<SaranaScreen> {
  // Data Inventaris Sarana (Dapat ditambah atau dihapus oleh admin)
  final List<Map<String, String>> _saranaList = [
    {'nama': 'Gedung Utama', 'kondisi': 'Baik', 'jumlah': '3 Lantai'},
    {'nama': 'Laboratorium Komputer', 'kondisi': 'Baik', 'jumlah': '20 Unit'},
    {'nama': 'Perpustakaan', 'kondisi': 'Terawat', 'jumlah': '1 Ruang'},
    {'nama': 'Lapangan Olahraga', 'kondisi': 'Perlu Perbaikan', 'jumlah': '1 Area'},
    {'nama': 'Ruang UKS', 'kondisi': 'Baik', 'jumlah': '1 Ruang'},
  ];

  // Fungsi Dialog Konfirmasi Hapus Data Sarana (Khusus Admin)
  void _hapusSarana(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Sarana'),
        content: const Text('Apakah Anda yakin ingin menghapus data sarana & prasarana ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _saranaList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data sarana berhasil dihapus!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Fungsi Dialog Input Sarana Baru khusus Admin
  void _showAddSaranaDialog() {
    final TextEditingController namaController = TextEditingController();
    final TextEditingController kondisiController = TextEditingController();
    final TextEditingController jumlahController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Sarana & Prasarana'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Sarana / Ruangan')),
                TextField(controller: kondisiController, decoration: const InputDecoration(labelText: 'Kondisi (Cth: Baik / Perlu Perbaikan)')),
                TextField(controller: jumlahController, decoration: const InputDecoration(labelText: 'Jumlah / Kapasitas (Cth: 1 Unit)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
              onPressed: () {
                if (namaController.text.isNotEmpty) {
                  setState(() {
                    _saranaList.add({
                      'nama': namaController.text,
                      'kondisi': kondisiController.text.isEmpty ? 'Baik' : kondisiController.text,
                      'jumlah': jumlahController.text.isEmpty ? '1 Unit' : jumlahController.text,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sarana baru berhasil ditambahkan!')),
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
        title: const Text('Sarana & Prasarana', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _saranaList.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          var item = _saranaList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.domain, color: Colors.teal[900]),
            ),
            title: Text(item['nama']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Kondisi: ${item['kondisi']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(item['jumlah']!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.teal[50],
                ),
                // Tombol Hapus khusus Admin
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    onPressed: () => _hapusSarana(index),
                    tooltip: 'Hapus Sarana',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      // Tombol Tambah hanya muncul jika yang login adalah Admin
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddSaranaDialog,
              backgroundColor: Colors.teal[800],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Sarana'),
            )
          : null,
    );
  }
}