import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../config.dart' as config;

class TunggakanScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TunggakanScreen({super.key, required this.userData});

  @override
  State<TunggakanScreen> createState() => _TunggakanScreenState();
}

class _TunggakanScreenState extends State<TunggakanScreen> {
  bool isAdmin = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _dataTunggakan = [];

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadTunggakanDataFromBackend();
  }

  // Periksa apakah user yang login adalah admin
  void _checkAdminRole() {
    final username = widget.userData['username'] ?? '';
    setState(() {
      isAdmin = (username == 'admin' || widget.userData['role'] == 'Admin');
    });
  }

  // 1. AMBIL DATA DARI GOOGLE SHEETS VIA APPS SCRIPT
  Future<void> _loadTunggakanDataFromBackend() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse(config.AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_tunggakan"}),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success' && res['data'] != null) {
          setState(() {
            _dataTunggakan = List<Map<String, dynamic>>.from(res['data']);
          });
        }
      }
    } catch (e) {
      scaffoldMessengerShow(context, 'Gagal memuat data: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 2. FITUR UPLOAD FILE EXCEL NYATA KE SERVER
  Future<void> _uploadExcelKeServer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      String fileName = result.files.single.name;
      String base64File = base64Encode(fileBytes);

      setState(() { _isLoading = true; });
      try {
        final response = await http.post(
        Uri.parse(config.AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
            "action": "upload_tunggakan",
            "filename": fileName,
            "filedata": base64File,
          }),
        );

        if (response.statusCode == 200) {
          final res = jsonDecode(response.body);
          scaffoldMessengerShow(context, res['message'] ?? 'Berhasil diupload');
          _loadTunggakanDataFromBackend(); // Refresh data setelah upload
        } else {
          scaffoldMessengerShow(context, 'Gagal mengunggah file.');
        }
      } catch (e) {
        scaffoldMessengerShow(context, 'Error koneksi: $e');
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  // 3. FITUR HAPUS DATA TUNGGAKAN (KHUSUS ADMIN)
  Future<void> _hapusTunggakan(String idUnik) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data tunggakan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { _isLoading = true; });
      try {
        final response = await http.post(
        Uri.parse(config.AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "hapus_tunggakan",
          "id": idUnik,
        }),
      );

        if (response.statusCode == 200) {
          final res = jsonDecode(response.body);
          scaffoldMessengerShow(context, res['message'] ?? 'Berhasil dihapus');
          _loadTunggakanDataFromBackend();
        }
      } catch (e) {
        scaffoldMessengerShow(context, 'Gagal menghapus: $e');
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  void scaffoldMessengerShow(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userData['username'] ?? '';
    final filteredData = isAdmin 
        ? _dataTunggakan 
        : _dataTunggakan.where((item) => item['id_siswa'].toString() == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Tunggakan Sekolah'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTunggakanDataFromBackend,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                            onPressed: _uploadExcelKeServer,
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text(item['status'], style: const TextStyle(color: Colors.white)),
                                        backgroundColor: isLunas ? Colors.green : Colors.redAccent,
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _hapusTunggakan(item['id'] ?? item['id_siswa']),
                                        ),
                                      ],
                                    ],
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