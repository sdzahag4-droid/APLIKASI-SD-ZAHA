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
  bool _isKelulusanMode = false; // Penanda mode kelulusan

  Future<void> _prosesKenaikanKelas() async {
    if (_kelasAsalController.text.isEmpty || _kelasTujuanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi kelas asal dan kelas tujuan/status kelulusan!")),
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
        setState(() => _isKelulusanMode = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Terjadi kesalahan")),
        );
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
        title: const Text("Form Kenaikan & Kelulusan Kelas"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Proses Kenaikan / Kelulusan Siswa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fitur ini akan mengubah semua siswa dari kelas asal ke kelas tujuan atau meluluskan siswa secara bersamaan.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _kelasAsalController,
              decoration: const InputDecoration(
                labelText: "Kelas Asal (Contoh: 6A atau 5A)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: 15),
            
            // Switch untuk mengubah mode ke Kelulusan
            SwitchListTile(
              title: const Text("Tandai sebagai Proses Kelulusan"),
              subtitle: const Text("Aktifkan jika siswa di kelas asal dinyatakan Lulus"),
              value: _isKelulusanMode,
              activeColor: Colors.green[800],
              onChanged: (bool value) {
                setState(() {
                  _isKelulusanMode = value;
                  if (_isKelulusanMode) {
                    _kelasTujuanController.text = "Lulus";
                  } else {
                    _kelasTujuanController.text = "";
                  }
                });
              },
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _kelasTujuanController,
              enabled: !_isKelulusanMode, // Jika mode lulus aktif, input dikunci agar tetap "Lulus"
              decoration: InputDecoration(
                labelText: "Kelas Tujuan / Status (Contoh: 6A atau Lulus)",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.school),
                filled: _isKelulusanMode,
                fillColor: _isKelulusanMode ? Colors.grey[200] : null,
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
                    : Text(
                        _isKelulusanMode ? "PROSES Kelulusan SISWA" : "PROSES KENAIKAN KELAS",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}