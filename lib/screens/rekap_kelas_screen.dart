import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  // Mengambil string bulan untuk judul periode dari data rekap jika tersedia
  String _getJudulPeriode() {
    if (listRekap.isNotEmpty) {
      for (var item in listRekap) {
        if (item['Bulan'] != null && item['Bulan'].toString().isNotEmpty && item['Bulan'].toString() != '-') {
          return _formatPeriode(item['Bulan'].toString());
        }
      }
    }
    return "Agustus 2026"; // Default fallback yang rapi
  }

  Future<void> _fetchRekapData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.apiUrl}?action=getRekapAbsenSiswa&kelas=${widget.kelas}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
                  // Menyaring data berdasarkan kelas yang aktif
                  listRekap = (data['data'] as List).where((item) {
                    return item['Kelas']?.toString() == widget.kelas;
                  }).toList();

                  // --- TAMBAHKAN PENGHITUNG STATUS DI SINI ---
                  int hadir = listRekap.where((item) => item['Status']?.toString().toLowerCase() == 'hadir').length;
                  int sakit = listRekap.where((item) => item['Status']?.toString().toLowerCase() == 'sakit').length;
                  int alpa = listRekap.where((item) => item['Status']?.toString().toLowerCase() == 'alpa' || item['Status']?.toString().toLowerCase() == 'alpha').length;
                  // -------------------------------------------

                  isLoading = false;
                });
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

  // Fungsi untuk Membuat dan Mencetak/Menyimpan PDF dengan Keterangan Waktu & Kolom Total
  Future<void> _cetakPdfRekap() async {
    final pdf = pw.Document();
    final String periodeTeks = _getJudulPeriode();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "LAPORAN REKAPITULASI ABSENSI SISWA",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              // Keterangan Judul Waktu (Bulan dan Tahun)
              pw.Text(
                "PERIODE: ${periodeTeks.toUpperCase()}",
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Text("Kelas: ${widget.kelas}", style: pw.TextStyle(fontSize: 10)),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),
              
              // Tabel dengan Kolom Total Kehadiran
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Siswa', 'Hadir', 'Izin', 'Sakit', 'Alpa', 'Total'],
                data: List.generate(listRekap.length, (index) {
                  final siswa = listRekap[index];
                  
                  int hadir = int.tryParse(siswa['Hadir']?.toString() ?? '0') ?? 0;
                  int izin = int.tryParse(siswa['Izin']?.toString() ?? '0') ?? 0;
                  int sakit = int.tryParse(siswa['Sakit']?.toString() ?? '0') ?? 0;
                  int alpa = int.tryParse(siswa['Alpa']?.toString() ?? '0') ?? 0;
                  int totalKehadiran = hadir + izin + sakit + alpa;

                  return [
                    (index + 1).toString(),
                    siswa['Nama'] ?? siswa['Nama_Siswa'] ?? 'Tanpa Nama',
                    hadir.toString(),
                    izin.toString(),
                    sakit.toString(),
                    alpa.toString(),
                    totalKehadiran.toString(), // Kolom Total Kehadiran
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
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
                  6: pw.Alignment.center,
                },
              ),
            ],
          );
        },
      ),
    );

    // Membuka jendela preview cetak / simpan PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Absensi_Kelas_${widget.kelas}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rekap Absen Kelas ${widget.kelas}"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak / Ekspor PDF',
            onPressed: listRekap.isEmpty ? null : _cetakPdfRekap,
          ),
        ],
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
                              siswa['Nama_Siswa'] ?? siswa['Nama'] ?? siswa['nama'] ?? 'Tanpa Nama',
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