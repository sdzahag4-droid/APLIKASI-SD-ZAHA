import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class KenaikanKelasScreen extends StatefulWidget {
  const KenaikanKelasScreen({super.key});

  @override
  State<KenaikanKelasScreen> createState() => _KenaikanKelasScreenState();
}

class _KenaikanKelasScreenState extends State<KenaikanKelasScreen> {
  final _kelasAsalController = TextEditingController();
  final _kelasTujuanController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _prosesKenaikanKelas() async {
    if (_kelasAsalController.text.isEmpty || _kelasTujuanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi kelas asal dan kelas tujuan!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        body: json.encode({
          "action": "naik_kelas",
          "kelas_asal": _kelasAsalController.text.trim(),
          "kelas_tujuan": _kelasTujuanController.text.trim(),
        }),
      );

      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
        _kelasAsalController.clear();
        _kelasTujuanController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Kenaikan Kelas"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Proses Kenaikan Kelas Siswa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fitur ini akan mengubah semua siswa dari kelas asal ke kelas tujuan secara bersamaan.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _kelasAsalController,
              decoration: const InputDecoration(
                labelText: "Kelas Asal (Contoh: 4A)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _kelasTujuanController,
              decoration: const InputDecoration(
                labelText: "Kelas Tujuan (Contoh: 5A)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                onPressed: _isSubmitting ? null : _prosesKenaikanKelas,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "PROSES KENAIKAN KELAS",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}