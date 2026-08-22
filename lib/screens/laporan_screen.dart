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

  // Fungsi untuk Membuat dan Menampilkan Pratinjau/Cetak PDF
  Future<void> _cetakPdfLaporan() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "LAPORAN REKAPITULASI ABSENSI SISWA",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text("Kelas: ${widget.kelas}", style: pw.TextStyle(fontSize: 14)),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Siswa', 'Hadir', 'Izin', 'Sakit', 'Alpa'],
                data: List.generate(listLaporan.length, (index) {
                  final siswa = listLaporan[index];
                  return [
                    (index + 1).toString(),
                    siswa['Nama'] ?? 'Tanpa Nama',
                    siswa['Hadir']?.toString() ?? '0',
                    siswa['Izin']?.toString() ?? '0',
                    siswa['Sakit']?.toString() ?? '0',
                    siswa['Alpa']?.toString() ?? '0',
                  ];
                }),
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