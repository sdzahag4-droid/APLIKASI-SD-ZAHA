import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RekapKelasScreen extends StatefulWidget {
  final String kelas;
  const RekapKelasScreen({Key? key, required this.kelas}) : super(key: key);

  @override
  _RekapKelasScreenState createState() => _RekapKelasScreenState();
}

class _RekapKelasScreenState extends State<RekapKelasScreen> {
  List<dynamic> listRekap = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRekapData();
  }

  Future<void> _fetchRekapData() async {
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
            // Menyaring data berdasarkan kelas yang aktif
            listRekap = (data['data'] as List).where((item) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rekap Absen Kelas ${widget.kelas}"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : listRekap.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada data rekap absensi untuk kelas ini.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listRekap.length,
                  itemBuilder: (context, index) {
                    final siswa = listRekap[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              siswa['Nama'] ?? 'Tanpa Nama',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBadge("Hadir", siswa['Hadir'] ?? '0', Colors.green),
                                _buildBadge("Izin", siswa['Izin'] ?? '0', Colors.orange),
                                _buildBadge("Sakit", siswa['Sakit'] ?? '0', Colors.blue),
                                _buildBadge("Alpa", siswa['Alpa'] ?? '0', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildBadge(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            "$value",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}