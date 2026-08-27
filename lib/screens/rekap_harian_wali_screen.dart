import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aplikasi_sd_zaha/config.dart';

class RekapHarianWaliScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RekapHarianWaliScreen({super.key, required this.userData});

  @override
  State<RekapHarianWaliScreen> createState() => _RekapHarianWaliScreenState();
}

class _RekapHarianWaliScreenState extends State<RekapHarianWaliScreen> {
  bool _isLoading = true;
  List<dynamic> _listRekap = [];
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _fetchRekapHarian();
  }

  Future<void> _fetchRekapHarian() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_rekap_harian_siswa",
          "tanggal": _selectedDate,
          "kelas": widget.userData['kelas'] ?? "", // Mengambil data kelas dari sesi login wali kelas
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listRekap = data['result'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error jika diperlukan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Harian Siswa'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Bagian Pilih Tanggal / Filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tanggal: $_selectedDate", style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked.toIso8601String().split('T')[0];
                      });
                      _fetchRekapHarian();
                    }
                  },
                  child: const Text("Pilih Tanggal"),
                ),
              ],
            ),
          ),
          const Divider(),
          // List Data Rekap
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listRekap.isEmpty
                    ? const Center(child: Text("Belum ada data rekap untuk tanggal ini."))
                    : ListView.builder(
                        itemCount: _listRekap.length,
                        itemBuilder: (context, index) {
                          final item = _listRekap[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(item['nama_siswa'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Status: ${item['status']} | Keterangan: ${item['keterangan'] ?? '-'}"),
                              trailing: Text(item['jam'] ?? ''),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}