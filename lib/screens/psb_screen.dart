import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
import '../config.dart';

class PsbScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PsbScreen({super.key, required this.userData});

  @override
  State<PsbScreen> createState() => _PsbScreenState();
}

class _PsbScreenState extends State<PsbScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD
  bool isAdmin = false;
=======
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a

  // Form Controllers
  final TextEditingController _namaSiswaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _waliController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _asalTkController = TextEditingController();
  final TextEditingController _noKkController = TextEditingController();
  String _jenisKelamin = 'Laki-laki';

  // Dummy Data Pendaftar (Bisa diintegrasikan ke Google Sheets)
  final List<Map<String, dynamic>> _daftarPendaftar = [
    {
      'no_reg': 'PSB-2026-001',
      'nama': 'Ahmad Fauzi',
      'jk': 'Laki-laki',
      'wali': 'Bambang S.',
      'status': 'Diterima',
      'tanggal': '10 Ags 2026'
    },
    {
      'no_reg': 'PSB-2026-002',
      'nama': 'Siti Aisyah',
      'jk': 'Perempuan',
      'wali': 'M. RIDWAN',
      'status': 'Pending',
      'tanggal': '11 Ags 2026'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
<<<<<<< HEAD
    _cekStatusAdmin();
  }

  Future<void> _cekStatusAdmin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool adminPref = prefs.getBool('isAdmin') ?? false;
    String role = widget.userData['role'] ?? '';
    bool roleAdmin = role.toLowerCase().contains('admin') || widget.userData['username'] == 'admin';

    setState(() {
      isAdmin = adminPref || roleAdmin;
    });
=======
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaSiswaController.dispose();
    _nikController.dispose();
    _waliController.dispose();
    _whatsappController.dispose();
    _nisController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _asalTkController.dispose();
    _noKkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _daftarPendaftar.add({
          'no_reg': 'PSB-2026-00${_daftarPendaftar.length + 1}',
          'nama': _namaSiswaController.text,
          'jk': _jenisKelamin,
          'wali': _waliController.text,
          'status': 'Pending',
          'tanggal': '12 Ags 2026',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran Calon Siswa Berhasil Disimpan!'),
          backgroundColor: Colors.green,
        ),
      );

      _namaSiswaController.clear();
      _nikController.clear();
      _waliController.clear();
      _whatsappController.clear();
      _nisController.clear();
      _tempatLahirController.clear();
      _tanggalLahirController.clear();
      _asalTkController.clear();
      _noKkController.clear();
      _tabController.animateTo(1); // Pindah ke tab Data Pendaftar
    }
  }

<<<<<<< HEAD
  // Fungsi untuk Menghapus Data Pendaftar (Khusus Admin)
  void _hapusPendaftar(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Pendaftar'),
        content: const Text('Apakah Anda yakin ingin menghapus data calon siswa ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _daftarPendaftar.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data pendaftar berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung jumlah status untuk statistik
    int totalPendaftar = _daftarPendaftar.length;
    int diterimaCount = _daftarPendaftar.where((e) => e['status'] == 'Diterima').length;
    int pendingCount = _daftarPendaftar.where((e) => e['status'] == 'Pending').length;

=======
  @override
  Widget build(BuildContext context) {
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Penerimaan Siswa Baru (PSB)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1), text: "Formulir"),
            Tab(icon: Icon(Icons.list_alt), text: "Data Pendaftar"),
            Tab(icon: Icon(Icons.info_outline), text: "Syarat & Alur"),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER STATISTIK KUOTA PSB
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
<<<<<<< HEAD
                _buildStatCard("Total Pendaftar", "$totalPendaftar", Colors.blue),
                _buildStatCard("Diterima", "$diterimaCount", Colors.green),
                _buildStatCard("Pending", "$pendingCount", Colors.orange),
=======
                _buildStatCard("Total Pendaftar", "${_daftarPendaftar.length}", Colors.blue),
                _buildStatCard("Diterima", "1", Colors.green),
                _buildStatCard("Pending", "1", Colors.orange),
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormPendaftaran(),
                _buildDataPendaftarList(),
                _buildSyaratAlur(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // TAB 1: FORMULIR PENDAFTARAN
  Widget _buildFormPendaftaran() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Form Pendaftaran Calon Siswa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaSiswaController,
                  decoration: const InputDecoration(labelText: "Nama Lengkap Calon Siswa", border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nisController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "NIS (Nomor Induk Siswa)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "NIK Calon Siswa", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tempatLahirController,
                        decoration: const InputDecoration(labelText: "Tempat Lahir", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tanggalLahirController,
                        decoration: const InputDecoration(labelText: "Tanggal Lahir (DD-MM-YYYY)", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _jenisKelamin,
                  decoration: const InputDecoration(labelText: "Jenis Kelamin", border: OutlineInputBorder()),
                  items: ['Laki-laki', 'Perempuan']
                      .map((jk) => DropdownMenuItem(value: jk, child: Text(jk)))
                      .toList(),
                  onChanged: (val) => setState(() => _jenisKelamin = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _asalTkController,
                  decoration: const InputDecoration(labelText: "Asal TK / PAUD", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noKkController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "No. KK (Kartu Keluarga)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _waliController,
                  decoration: const InputDecoration(labelText: "Nama Orang Tua / Wali", border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Nama Orang Tua wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "No. WhatsApp Wali", border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'No. WhatsApp wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                    child: const Text("Simpan Pendaftaran", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 2: DAFTAR PENDAFTAR
  Widget _buildDataPendaftarList() {
<<<<<<< HEAD
    if (_daftarPendaftar.isEmpty) {
      return const Center(child: Text("Belum ada data pendaftar.", style: TextStyle(color: Colors.grey)));
    }

=======
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _daftarPendaftar.length,
      itemBuilder: (context, index) {
        var data = _daftarPendaftar[index];
        bool isDiterima = data['status'] == 'Diterima';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDiterima ? Colors.green[100] : Colors.orange[100],
              child: Icon(isDiterima ? Icons.check_circle : Icons.hourglass_top, color: isDiterima ? Colors.green : Colors.orange),
            ),
            title: Text(data['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("No. Reg: ${data['no_reg']} • Wali: ${data['wali']}\nTanggal: ${data['tanggal']}"),
<<<<<<< HEAD
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDiterima ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(data['status'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _hapusPendaftar(index),
                    tooltip: 'Hapus Pendaftar',
                  ),
                ],
              ],
=======
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDiterima ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data['status'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
            ),
          ),
        );
      },
    );
  }

  // TAB 3: SYARAT DAN ALUR
  Widget _buildSyaratAlur() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.format_list_numbered, color: Colors.blue),
              title: Text("Alur Pendaftaran", style: TextStyle(fontWeight: FontWeight.bold)),
<<<<<<< HEAD
              subtitle: Text("1. Isi Formulir Online\n2. Verifikasi Berkas oleh Panitia\n3.Pengumuman Kelulusan"),
=======
              subtitle: Text("1. Isi Formulir Online\n2. Verifikasi Berkas oleh Panitia\n3. Observasi Calon Siswa\n4. Pengumuman Kelulusan"),
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.file_present, color: Colors.green),
              title: Text("Persyaratan Berkas", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("• Fotokopi Akta Kelahiran\n• Fotokopi Kartu Keluarga (KK)\n• Pas Foto 3x4 (2 Lembar)\n• Fotokopi Ijazah TK/RA (Jika Ada)"),
            ),
          ),
        ],
      ),
    );
  }
}