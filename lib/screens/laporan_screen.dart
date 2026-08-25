import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  // Helper untuk mengubah string tanggal menjadi format "Bulan Tahun" (contoh: "Agustus 2026")
  String _formatPeriode(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return 'Agustus 2026';

    try {
      DateTime dateTime = DateTime.parse(rawDate);
      const listBulan = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
      ];
      String namaBulan = listBulan[dateTime.month - 1];
      return "$namaBulan ${dateTime.year}";
    } catch (e) {
      return rawDate;
    }
  }

  // Mengambil string bulan untuk judul periode dari data laporan jika tersedia
  String _getJudulPeriode() {
    if (listLaporan.isNotEmpty) {
      for (var item in listLaporan) {
        if (item['Bulan'] != null && item['Bulan'].toString().isNotEmpty && item['Bulan'].toString() != '-') {
          return _formatPeriode(item['Bulan'].toString());
        }
      }
    }
    return "Agustus 2026";
  }

  // Fungsi untuk mendapatkan nama wali kelas secara otomatis berdasarkan kelas
  String _getWaliKelas(String kelas) {
    switch (kelas.toUpperCase()) {
      case '1A': return 'Mutmainnah, S.Pd.';
      case '1B': return 'Hairul Nizak, S.Pd.I.';
      case '1C': return 'Fitriyah Ningsih, S.Pd.I.';
      case '1D': return 'Afkarina Hasin, S.Pd.';
      case '2A': return 'Lusfiana M A, S.Pd.';
      case '2B': return 'Nurlaila, S.Pd.I.';
      case '2C': return 'Ely Dewi Cahyati, SE.';
      case '3A': return 'Rifqoh Thoyyibah, M.Pd.';
      case '3B': return 'Nihayati Putri Suseno, S.Pd.';
      case '3C': return 'Nadifatul Ainia, S.Pd.';
      case '4A': return 'Yuliatus Soliha, S.Pd.';
      case '4B': return 'Anang Firdaus, S.Pd.';
      case '4C': return 'Ach Riyan Firdaus, S.Pd.';
      case '5A': return 'Irawati, S.Pd.I.';
      case '5B': return 'Muhammad Qosim, S.Pd.';
      case '6A': return 'Nur Dyana Kholidah, S.Pd., Gr.';
      case '6B': return 'Syamsul Wahidin, S.Pd.';
      default: return 'Wali Kelas';
    }
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

  // Fungsi untuk Membuat dan Menampilkan Pratinjau/Cetak PDF dengan Baris Total di Bawah
  Future<void> _cetakPdfLaporan() async {
    final pdf = pw.Document();
    final namaWaliKelas = _getWaliKelas(widget.kelas);
    final String periodeTeks = _getJudulPeriode();

    // Menghitung akumulasi total keseluruhan kelas untuk baris bawah
    int totalHadirSemua = 0;
    int totalIzinSemua = 0;
    int totalSakitSemua = 0;
    int totalAlpaSemua = 0;

    for (var siswa in listLaporan) {
      totalHadirSemua += int.tryParse(siswa['Hadir']?.toString() ?? '0') ?? 0;
      totalIzinSemua += int.tryParse(siswa['Izin']?.toString() ?? '0') ?? 0;
      totalSakitSemua += int.tryParse(siswa['Sakit']?.toString() ?? '0') ?? 0;
      totalAlpaSemua += int.tryParse(siswa['Alpa']?.toString() ?? '0') ?? 0;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Menyiapkan data baris tabel siswa
          List<List<String>> dataTabel = List.generate(listLaporan.length, (index) {
            final siswa = listLaporan[index];
            final namaSiswa = siswa['Nama_Siswa'] ?? siswa['Nama'] ?? siswa['nama'] ?? 'Tanpa Nama';
            
            return [
              (index + 1).toString(),
              namaSiswa,
              siswa['Hadir']?.toString() ?? '0',
              siswa['Izin']?.toString() ?? '0',
              siswa['Sakit']?.toString() ?? '0',
              siswa['Alpa']?.toString() ?? '0',
            ];
          });

          // Menambahkan baris TOTAL di bagian paling bawah tabel
          dataTabel.add([
            '',
            'TOTAL KESELURUHAN',
            totalHadirSemua.toString(),
            totalIzinSemua.toString(),
            totalSakitSemua.toString(),
            totalAlpaSemua.toString(),
          ]);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "SD ZAINUL HASAN GENGGONG",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                "LAPORAN REKAPITULASI ABSENSI SISWA",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              // Keterangan Periode Bulan & Tahun
              pw.Text(
                "PERIODE: ${periodeTeks.toUpperCase()}",
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Text("Kelas: ${widget.kelas}", style: pw.TextStyle(fontSize: 12)),
              pw.Text("Wali Kelas: $namaWaliKelas", style: pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),
              
              // Tabel dengan Kolom: No, Nama Siswa, Hadir, Izin, Sakit, Alpa (Total di baris bawah)
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Siswa', 'Hadir', 'Izin', 'Sakit', 'Alpa'],
                data: dataTabel,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
              ),
            ],
          );
        },
      ),
    );

    // Membuka jendela print/preview PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Absensi_Kelas_${widget.kelas}.pdf',
    );
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
                    Text(
                      "Rekap Bulanan Kelas",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                  onPressed: listLaporan.isEmpty ? null : _cetakPdfLaporan,
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
                          final namaSiswa = siswa['Nama_Siswa'] ?? siswa['Nama'] ?? siswa['nama'] ?? 'Tanpa Nama';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              namaSiswa,
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