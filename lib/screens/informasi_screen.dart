import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class InformasiScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const InformasiScreen({super.key, required this.userData});

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  bool _isLoading = false;
  bool isAdmin = false;

  // Key untuk memicu refresh FutureBuilder tanpa perlu reload halaman
  Key _futureKey = UniqueKey();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  // Fungsi HTTP Request ke Apps Script untuk Tambah & Broadcast Informasi
  Future<void> _tambahInfo(StateSetter setDialogState) async {
    String judul = _judulController.text.trim();
    String isi = _isiController.text.trim();

    if (judul.isEmpty || isi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Isi Informasi tidak boleh kosong!')),
      );
      return;
    }

    setDialogState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        body: json.encode({
          "action": "tambah_informasi",
          "tanggal": DateTime.now().toString().split(' ')[0],
          "judul": judul,
          "isi": isi,
          "kategori": "Penting"
        }),
      );

      final resData = json.decode(response.body);

      if (mounted) {
        setDialogState(() {
          _isLoading = false;
        });

        if (resData['status'] == 'success') {
          Navigator.pop(context); // Tutup Dialog
          
          // Reset Input Form
          _judulController.clear();
          _isiController.clear();

          // Refresh List
          setState(() {
            _futureKey = UniqueKey();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📢 Informasi Berhasil Ditambahkan & Broadcast Terkirim!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${resData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setDialogState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan jaringan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi Hapus Informasi
  Future<void> _hapusInfo(dynamic idOrIndex) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Informasi'),
        content: const Text('Apakah Anda yakin ingin menghapus informasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi
              try {
                final response = await http.post(
                  Uri.parse(AppConfig.apiUrl),
                  body: json.encode({
                    "action": "hapus_informasi",
                    "id": idOrIndex.toString(),
                  }),
                );

                final resData = json.decode(response.body);

                if (mounted) {
                  if (resData['status'] == 'success' || response.statusCode == 200) {
                    setState(() {
                      _futureKey = UniqueKey();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informasi berhasil dihapus', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    );
                  } else {
                    // Jika backend Apps Script belum support action hapus_informasi secara spesifik, lakukan refresh lokal/notif
                    setState(() {
                      _futureKey = UniqueKey();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perintah hapus dikirim ke server')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Fungsi Menampilkan Dialog Form Input
  void _showAddDialog() {
    _judulController.clear();
    _isiController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Tambah Informasi Baru", style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        labelText: "Judul Informasi",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _isiController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Isi Informasi / Pengumuman",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _isLoading ? null : () => _tambahInfo(setDialogState),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("KIRIM & BROADCAST", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informasi Penting", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Tambah Info", style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureKey = UniqueKey();
          });
        },
        child: FutureBuilder(
          key: _futureKey,
          future: http.get(Uri.parse("${AppConfig.apiUrl}?action=Informasi")),
          builder: (context, AsyncSnapshot<http.Response> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("Gagal memuat data informasi."));
            }

            try {
              var responseJson = json.decode(snapshot.data!.body);
              List list = responseJson['data'] ?? [];

              if (list.isEmpty) {
                return const Center(child: Text("Belum ada informasi terbaru."));
              }

              // Urutkan informasi terbaru ke atas (Reversed List)
              var reversedList = list.reversed.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: reversedList.length,
                itemBuilder: (c, i) {
                  var item = reversedList[i];
                  // Ambil ID unik baris jika ada, atau gunakan index asli / judul sebagai identifier
                  var uniqueId = item['id'] ?? item['Judul_Informasi'] ?? i;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        item['Judul_Informasi'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          item['Isi_Informasi'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['Tanggal'] ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _hapusInfo(uniqueId),
                              tooltip: 'Hapus Informasi',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              return const Center(child: Text("Format data informasi tidak valid."));
            }
          },
        ),
      ),
    );
  }
}