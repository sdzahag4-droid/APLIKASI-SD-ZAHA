import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class LaporanScreen extends StatefulWidget {
  final String kelas;
  const LaporanScreen({Key? key, required this.kelas}) : super(key: key);

  @override
  _LaporanScreenState createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<dynamic> listLaporan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLaporanData();
  }

  Future<void> _fetchLaporanData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse("$iUrl?action=getRekapAbsenSiswa&kelas=${widget.kelas}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            listLaporan = (data['data'] as List).where((item) {
              return item['Kelas']?.toString() == widget.kelas;
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _bukaGoogleSheets() async {
    final String url = "$iUrl?action=exportLaporan&kelas=${widget.kelas}";
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka tautan ekspor laporan.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Laporan Absensi Kelas ${widget.kelas}"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.indigo.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rekap Bulanan Kelas",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total Siswa: ${listLaporan.length} Orang",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _bukaGoogleSheets,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text("Cetak / Ekspor"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : listLaporan.isEmpty
                    ? const Center(
                        child: Text("Belum ada data laporan untuk kelas ini."),
                      )
                    : ListView.builder(
                        itemCount: listLaporan.length,
                        itemBuilder: (context, index) {
                          final siswa = listLaporan[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              siswa['Nama'] ?? 'Tanpa Nama',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Hadir: ${siswa['Hadir'] ?? 0} | Izin: ${siswa['Izin'] ?? 0} | Sakit: ${siswa['Sakit'] ?? 0} | Alpa: ${siswa['Alpa'] ?? 0}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}