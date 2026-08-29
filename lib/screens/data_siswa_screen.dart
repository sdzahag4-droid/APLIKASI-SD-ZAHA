import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class DataSiswaScreen extends StatefulWidget {
  final String kelas; // Menerima parameter kelas dari dashboard/login
  const DataSiswaScreen({Key? key, required this.kelas}) : super(key: key);

  @override
  _DataSisnaScreenState createState() => _DataSisnaScreenState();
}

class _DataSisnaScreenState extends State<DataSiswaScreen> {
  List<dynamic> listSiswa = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataSiswa();
  }

  Future<void> fetchDataSiswa() async {
    try {
      final response = await http.post(
        Uri.parse(iUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "getDataSiswa",
          "kelas": widget.kelas,
          "id_lembaga": idLembaga,
        }),
      );

      // Cek apakah widget masih aktif sebelum mengubah state
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> rawData = data['data'] ?? [];

          // Filter ketat: Hanya ambil data yang benar-benar siswa murni
          List<dynamic> filteredData = rawData.where((item) {
            String role = (item['Role'] ?? item['role'] ?? '').toString().toLowerCase();
            String jabatan = (item['Jabatan'] ?? item['jabatan'] ?? '').toString().toLowerCase();
            String nama = (item['Nama'] ?? item['nama'] ?? '').toString().toLowerCase();

            // Buang jika terdeteksi sebagai guru, admin, karyawan, wali kelas, atau nama guru terkait
            if (role == 'guru' || 
                role == 'admin' || 
                role == 'karyawan' || 
                jabatan.contains('wali') || 
                jabatan.contains('guru') ||
                nama.contains('ely dewi')) {
              return false; 
            }
            
            return true; // Loloskan hanya untuk siswa
          }).toList();

          if (!mounted) return;
          setState(() {
            listSiswa = filteredData;
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          print("Gagal memuat data: ${data['message']}");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Siswa Kelas ${widget.kelas}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : listSiswa.isEmpty
              ? Center(child: Text("Tidak ada data siswa untuk kelas ini."))
              : ListView.builder(
                  itemCount: listSiswa.length,
                  itemBuilder: (context, index) {
                    var siswa = listSiswa[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          siswa['Nama'] ?? siswa['nama'] ?? 'Tanpa Nama',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}