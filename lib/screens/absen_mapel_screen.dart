import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aplikasi_sd_zaha/config.dart';

class AbsenMapelScreen extends StatefulWidget {
  final String namaGuru;
  const AbsenMapelScreen({Key? key, required this.namaGuru}) : super(key: key);

  @override
  _AbsenMapelScreenState createState() => _AbsenMapelScreenState();
}

class _AbsenMapelScreenState extends State<AbsenMapelScreen> {
  bool isLoading = false;
  bool isLoadingSiswa = false;

  String? selectedKelas = 'Kelas 1A';
  String selectedMapel = 'Matematika';

  // Daftar kelas disesuaikan dengan format di tab Siswa (misal: 1A, 1B, dst.)
  List<String> listKelas = [
  'Kelas 1A', 'Kelas 1B', 'Kelas 1C', 'Kelas 1D',
  'Kelas 2A', 'Kelas 2B', 'Kelas 2C',
  'Kelas 3A', 'Kelas 3B', 'Kelas 3C',
  'Kelas 4A', 'Kelas 4B', 'Kelas 4C',
  'Kelas 5A', 'Kelas 5B', 'Kelas 5C',
  'Kelas 6A', 'Kelas 6B', 'Kelas 6C',
];
  List<String> listMapel = ['Matematika', 'Bahasa Indonesia', 'IPA', 'IPS', 'PPKn', 'PAI', 'PJOK', 'TIK'];

  List<Map<String, dynamic>> listSiswa = [];
  
  // Menyimpan controller untuk textfield nilai agar aman saat di-scroll/rebuild
  final List<TextEditingController> _nilaiControllers = [];

  @override
  void initState() {
    super.initState();
    fetchSiswaByKelas(selectedKelas!);
  }

  @override
  void dispose() {
    for (var controller in _nilaiControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Fungsi menarik data siswa dari Google Sheets berdasarkan kelas
  Future<void> fetchSiswaByKelas(String kelas) async {
    setState(() {
      isLoadingSiswa = true;
    });

    try {
      final response = await http.get(Uri.parse('${AppConfig.apiUrl}?action=get_siswa&kelas=$kelas'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
List tempuanData = data['data'] ?? [];

        // FILTER: Buang nama guru / wali kelas atau baris kosong
        var tempuanBersih = tempuanData.where((siswa) {
          String nama = siswa['nama_siswa'] ?? siswa['Nama'] ?? '';
          bool bukanGuru = !nama.toLowerCase().contains('s.pd') && 
                            !nama.toLowerCase().contains('guru') &&
                            nama != 'Irawati, S.Pd.I.';
          return bukanGuru;
        }).toList();

        // Bersihkan controller lama
        for (var c in _nilaiControllers) {
          c.dispose();
        }
        _nilaiControllers.clear();

        setState(() {
          listSiswa = tempuanBersih.map((siswa) {
            _nilaiControllers.add(TextEditingController(text: ''));
            return {
              'nama_siswa': siswa['nama_siswa'] ?? 'Tanpa Nama',
              'status_kehadiran': 'Hadir',
              'keterangan': '-',
              'nilai': '',
            };
          }).toList();
          isLoadingSiswa = false;
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
      for (int i = 0; i < listSiswa.length; i++) {
        var siswa = listSiswa[i];
        // Ambil nilai terbaru dari controller
        String nilaiInput = _nilaiControllers[i].text;

        final response = await http.post(
          Uri.parse(AppConfig.apiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'action': 'simpan_absen_mapel',
            'nama_guru': widget.namaGuru,
            'mata_pelajaran': selectedMapel,
            'kelas': selectedKelas!,
            'nama_siswa': siswa['nama_siswa'],
            'status_kehadiran': siswa['status_kehadiran'],
            'keterangan': siswa['keterangan'],
            'nilai': nilaiInput,
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
                            
                            // Pastikan value dropdown ada di dalam list item yang valid
                            String currentStatus = siswa['status_kehadiran'];
                            List<String> validStatuses = ['Hadir', 'Izin', 'Sakit', 'Alpa'];
                            if (!validStatuses.contains(currentStatus)) {
                              currentStatus = 'Hadir';
                            }

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
                                            value: currentStatus,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              labelText: 'Status',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: validStatuses.map((status) {
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
                                            controller: _nilaiControllers[index],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              labelText: 'Nilai',
                                              border: OutlineInputBorder(),
                                            ),
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