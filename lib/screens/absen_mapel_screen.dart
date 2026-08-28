import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aplikasi_sd_zaha/services/config.dart';

class AbsenMapelScreen extends StatefulWidget {
  final String namaGuru;
  const AbsenMapelScreen({Key? key, required this.namaGuru}) : super(key: key);

  @override
  _AbsenMapelScreenState createState() => _AbsenMapelScreenState();
}

class _AbsenMapelScreenState extends State<AbsenMapelScreen> {
  bool isLoading = false;
  bool isLoadingSiswa = false;
  
  String? selectedKelas = '1A';
  String selectedMapel = 'Matematika';
  
  // Daftar kelas disesuaikan dengan format di tab Siswa (misal: 1A, 1B, dst.)
  List<String> listKelas = ['1A', '1B', '2A', '2B', '3A', '3B', '4A', '4B', '5A', '5B', '6A', '6B'];
  List<String> listMapel = ['Matematika', 'Bahasa Indonesia', 'IPA', 'IPS', 'PPKn', 'PAI', 'PJOK', 'TIK'];

  List<Map<String, dynamic>> listSiswa = [];

  @override
  void initState() {
    super.initState();
    fetchSiswaByKelas(selectedKelas!);
  }

  // Fungsi menarik data siswa dari Google Sheets berdasarkan kelas
  Future<void> fetchSiswaByKelas(String kelas) async {
    setState(() {
      isLoadingSiswa = true;
    });

    try {
      final response = await http.get(Uri.parse('${Config.urlWebApps}?action=get_siswa&kelas=$kelas'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List tempData = data['data'];
          setState(() {
            listSiswa = tempData.map((siswa) {
              return {
                'nama_siswa': siswa['nama'] ?? 'Tanpa Nama',
                'status_kehadiran': 'Hadir',
                'keterangan': '-',
                'nilai': '',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching siswa: $e");
    } finally {
      setState(() {
        isLoadingSiswa = false;
      });
    }
  }

  // Fungsi mengirim absensi dan nilai mapel ke Google Sheets
  Future<void> simpanAbsenDanNilai() async {
    if (selectedKelas == null) return;

    setState(() {
      isLoading = true;
    });

    int successCount = 0;

    try {
      for (var siswa in listSiswa) {
        final response = await http.post(
          Uri.parse(Config.urlWebApps),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'action': 'simpan_absen_mapel',
            'nama_guru': widget.namaGuru,
            'mata_pelajaran': selectedMapel,
            'kelas': selectedKelas!,
            'nama_siswa': siswa['nama_siswa'],
            'status_kehadiran': siswa['status_kehadiran'],
            'keterangan': siswa['keterangan'],
            'nilai': siswa['nilai'],
          },
        );

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['status'] == 'success') {
            successCount++;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil menyimpan data untuk $successCount siswa!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi & Penilaian Mapel'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown Mapel & Kelas
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMapel,
                    decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
                    items: listMapel.map((mapel) {
                      return DropdownMenuItem(value: mapel, child: Text(mapel));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedMapel = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedKelas,
                    decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                    items: listKelas.map((kelas) {
                      return DropdownMenuItem(value: kelas, child: Text('Kelas $kelas'));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedKelas = val!;
                        fetchSiswaByKelas(selectedKelas!);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Daftar Siswa & Input Nilai:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // List Siswa
            Expanded(
              child: isLoadingSiswa
                  ? const Center(child: CircularProgressIndicator())
                  : listSiswa.isEmpty
                      ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                      : ListView.builder(
                          itemCount: listSiswa.length,
                          itemBuilder: (context, index) {
                            final siswa = listSiswa[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${siswa['nama_siswa']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Pilihan Status Hadir/Izin/Sakit/Alpa
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<String>(
                                            value: siswa['status_kehadiran'],
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              labelText: 'Status',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: ['Hadir', 'Izin', 'Sakit', 'Alpa'].map((status) {
                                              return DropdownMenuItem(value: status, child: Text(status));
                                            }).toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                listSiswa[index]['status_kehadiran'] = val!;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Kolom Input Nilai Opsional
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            initialValue: siswa['nilai'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              labelText: 'Nilai',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (val) {
                                              listSiswa[index]['nilai'] = val;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                onPressed: isLoading ? null : simpanAbsenDanNilai,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan & Kirim Rekap Absen',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}