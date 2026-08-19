import 'package:flutter/material.dart';
import '../config.dart';

class PembayaranScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PembayaranScreen({super.key, required this.userData});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tagihan Dummy (Dapat dihubungkan ke backend Google Sheets / Apps Script)
  final List<Map<String, dynamic>> _tagihanList = [
    {
      'id': 'INV-2026-0801',
      'jenis': 'SPP Bulan Agustus 2026',
      'nominal': 150000,
      'jatuh_tempo': '15 Ags 2026',
      'status': 'Belum Bayar',
    },
    {
      'id': 'INV-2026-0802',
      'jenis': 'Infaq Kegiatan Ekstrakurikuler',
      'nominal': 50000,
      'jatuh_tempo': '20 Ags 2026',
      'status': 'Belum Bayar',
    },
  ];

  // Riwayat Pembayaran Dummy
  final List<Map<String, dynamic>> _riwayatList = [
    {
      'id': 'INV-2026-0701',
      'jenis': 'SPP Bulan Juli 2026',
      'nominal': 150000,
      'tanggal_bayar': '05 Jul 2026',
      'metode': 'Transfer Bank Mandiri',
      'status': 'Lunas',
    },
    {
      'id': 'INV-2026-0601',
      'jenis': 'Daftar Ulang & Seragam',
      'nominal': 550000,
      'tanggal_bayar': '20 Jun 2026',
      'metode': 'Tunai melalui Bendahara',
      'status': 'Lunas',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  // Fungsi Dialog Hapus Tagihan Khusus Admin
  void _hapusTagihan(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Tagihan'),
        content: const Text('Apakah Anda yakin ingin menghapus data tagihan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _tagihanList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data tagihan berhasil dihapus!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

=======
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
  // Fungsi Dialog Input Tagihan Baru khusus Admin
  void _showAddTagihanDialog() {
    final TextEditingController jenisController = TextEditingController();
    final TextEditingController nominalController = TextEditingController();
    final TextEditingController jatuhTempoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Tagihan Siswa Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jenisController,
                  decoration: const InputDecoration(labelText: 'Jenis Tagihan (Cth: SPP September 2026)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nominalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nominal (Cth: 150000)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jatuhTempoController,
                  decoration: const InputDecoration(labelText: 'Jatuh Tempo (Cth: 15 Sep 2026)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
              onPressed: () {
                if (jenisController.text.isNotEmpty && nominalController.text.isNotEmpty) {
                  setState(() {
                    _tagihanList.add({
                      'id': 'INV-2026-080${_tagihanList.length + 3}',
                      'jenis': jenisController.text,
                      'nominal': int.tryParse(nominalController.text) ?? 0,
                      'jatuh_tempo': jatuhTempoController.text.isEmpty ? '30 Ags 2026' : jatuhTempoController.text,
                      'status': 'Belum Bayar',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tagihan baru berhasil ditambahkan oleh Admin!'), backgroundColor: Colors.green),
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

  void _bayarTagihan(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pilih Metode Pembayaran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text("Tagihan: ${item['jenis']}", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text("Nominal: Rp ${item['nominal']}", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Metode Transfer Bank Utama:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.blue, size: 32),
                title: const Text("Bank Mandiri"),
                subtitle: const Text("No. Rek: 143-000-137977-3\na.n. SD Zainul Hasan Genggong"),
                isThreeLine: true,
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _prosesKonfirmasi(item, "Transfer Bank Mandiri");
                  },
                  child: const Text("Pilih"),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Colors.green, size: 32),
                title: const Text("QRIS / E-Wallet / Bank Lain"),
                subtitle: const Text("Scan QRIS universal atau transfer instan"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _prosesKonfirmasi(item, "QRIS / E-Wallet");
                  },
                  child: const Text("Pilih"),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.orange, size: 32),
                title: const Text("Bayar Tunai di Sekolah"),
                subtitle: const Text("Pembayaran langsung melalui Bendahara SD ZAHA"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _prosesKonfirmasi(item, "Tunai di Sekolah");
                  },
                  child: const Text("Pilih"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _prosesKonfirmasi(Map<String, dynamic> item, String metode) {
    setState(() {
      _tagihanList.remove(item);
      _riwayatList.insert(0, {
        'id': item['id'],
        'jenis': item['jenis'],
        'nominal': item['nominal'],
        'tanggal_bayar': '12 Ags 2026',
        'metode': metode,
        'status': 'Menunggu Verifikasi',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran via $metode berhasil diajukan! Menunggu verifikasi admin.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah user yang login berstatus sebagai Admin
    String role = widget.userData['role'] ?? '';
    bool isAdmin = role.toLowerCase().contains('admin');

    String nama = widget.userData['nama'] ?? widget.userData['Nama'] ?? 'Siswa/Wali';
    int totalTagihan = _tagihanList.fold(0, (sum, item) => sum + (item['nominal'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pembayaran & SPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: "Tagihan"),
            Tab(icon: Icon(Icons.history), text: "Riwayat"),
            Tab(icon: Icon(Icons.account_balance), text: "Rekening"),
          ],
        ),
      ),
      body: Column(
        children: [
          // RINGKASAN TOTAL TAGIHAN
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.account_balance_wallet, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tagihan Aktif ($nama)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        "Rp $totalTagihan",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: totalTagihan > 0 ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
<<<<<<< HEAD
                _buildTagihanTab(isAdmin),
=======
                _buildTagihanTab(),
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
                _buildRiwayatTab(),
                _buildRekeningTab(),
              ],
            ),
          ),
        ],
      ),
      // Tombol Tambah Tagihan hanya muncul jika user yang login adalah Admin
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddTagihanDialog,
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tagihan'),
            )
          : null,
    );
  }

  // TAB 1: LIST TAGIHAN
<<<<<<< HEAD
  Widget _buildTagihanTab(bool isAdmin) {
=======
  Widget _buildTagihanTab() {
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
    if (_tagihanList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text("Tidak Ada Tagihan Aktif", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Semua kewajiban pembayaran telah dilunasi.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tagihanList.length,
      itemBuilder: (context, index) {
        var item = _tagihanList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['id'], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
<<<<<<< HEAD
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item['status'], style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        // Tombol Hapus Tagihan khusus Admin
                        if (isAdmin) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _hapusTagihan(index),
                            tooltip: 'Hapus Tagihan',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
=======
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item['status'], style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
>>>>>>> 11d11ec4b4b1ddcf8b2dcfa724c7cbbbad9f7c0a
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['jenis'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Jatuh Tempo: ${item['jatuh_tempo']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rp ${item['nominal']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ElevatedButton(
                      onPressed: () => _bayarTagihan(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Bayar Now"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 2: RIWAYAT
  Widget _buildRiwayatTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatList.length,
      itemBuilder: (context, index) {
        var item = _riwayatList[index];
        bool isLunas = item['status'] == 'Lunas';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLunas ? Colors.green[100] : Colors.orange[100],
              child: Icon(isLunas ? Icons.check : Icons.access_time, color: isLunas ? Colors.green : Colors.orange),
            ),
            title: Text(item['jenis'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Tanggal: ${item['tanggal_bayar']} • ${item['metode']}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Rp ${item['nominal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item['status'], style: TextStyle(fontSize: 11, color: isLunas ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: REKENING SEKOLAH
  Widget _buildRekeningTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.account_balance, color: Colors.blue, size: 36),
            title: Text("Bank Mandiri (Utama)", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("No. Rekening: 143-000-137977-3\na.n. SD Zainul Hasan Genggong"),
            isThreeLine: true,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.qr_code, color: Colors.green, size: 36),
            title: Text("QRIS SD ZAHA", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Dapat di-scan melalui Mobile Banking apa pun, Gopay, OVO, Dana, & ShopeePay"),
            isThreeLine: true,
          ),
        ),
      ],
    );
  }
}