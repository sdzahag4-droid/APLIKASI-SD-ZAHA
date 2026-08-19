import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TunggakanScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TunggakanScreen({super.key, required this.userData});

  @override
  State<TunggakanScreen> createState() => _TunggakanScreenState();
}

class _TunggakanScreenState extends State<TunggakanScreen> {
  bool isAdmin = false;
  List<Map<String, dynamic>> _dataTunggakan = [];

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadTunggakanData();
  }

  // Periksa apakah user yang login adalah admin
  void _checkAdminRole() {
    final username = widget.userData['username'] ?? '';
    setState(() {
      isAdmin = (username == 'admin');
    });
  }

  // Muat data tunggakan (bisa diintegrasikan dengan SharedPreferences atau Local Storage)
  Future<void> _loadTunggakanData() async {
    final prefs = await SharedPreferences.getInstance();
    // Contoh data dummy/simulasi penyimpanan Excel lokal
    // Nantinya baris ini dapat dihubungkan dengan package pembaca file Excel (seperti excel / file_picker)
    setState(() {
      _dataTunggakan = [
        {'id_siswa': 'SD1', 'nama': 'Ahmad Siswa', 'bulan': 'Juli 2026', 'jumlah': 'Rp 150.000', 'status': 'Belum Lunas'},
        {'id_siswa': 'SD2', 'nama': 'Fatimah', 'bulan': 'Juli 2026', 'jumlah': 'Rp 150.000', 'status': 'Lunas'},
        {'id_siswa': 'SD1', 'nama': 'Ahmad Siswa', 'bulan': 'Agustus 2026', 'jumlah': 'Rp 150.000', 'status': 'Belum Lunas'},
      ];
    });
  }

  // Fungsi simulasi upload Excel khusus Admin
  void _uploadExcelSimulasi() {
    scaffoldMessengerShow(context, 'Fitur unggah file Excel berhasil disimulasikan.');
    // Tambahkan logika parsing file Excel di sini jika menggunakan file_picker & excel package
  }

  void scaffoldMessengerShow(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Jika bukan admin, saring data berdasarkan User ID siswa yang login
    final currentUserId = widget.userData['username'] ?? '';
    final filteredData = isAdmin 
        ? _dataTunggakan 
        : _dataTunggakan.where((item) => item['id_siswa'] == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Tunggakan Sekolah'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Panel Administrator: Upload Data Tunggakan', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _uploadExcelSimulasi,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pilih & Upload File Excel (.xlsx)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              isAdmin ? 'Semua Data Tunggakan Siswa (Admin View):' : 'Rincian Tunggakan Anak Anda:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredData.isEmpty
                  ? const Center(child: Text('Tidak ada data tunggakan.'))
                  : ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final item = filteredData[index];
                        final isLunas = item['status'] == 'Lunas';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLunas ? Colors.green : Colors.red,
                              child: Icon(isLunas ? Icons.check : Icons.warning, color: Colors.white),
                            ),
                            title: Text('${item['nama']} (ID: ${item['id_siswa']})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Bulan: ${item['bulan']} - Jumlah: ${item['jumlah']}'),
                            trailing: Chip(
                              label: Text(item['status'], style: const TextStyle(color: Colors.white)),
                              backgroundColor: isLunas ? Colors.green : Colors.redAccent,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}