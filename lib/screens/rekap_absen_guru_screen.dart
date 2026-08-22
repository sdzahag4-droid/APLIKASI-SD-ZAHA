import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config.dart';

class RekapAbsenGuruScreen extends StatefulWidget {
  const RekapAbsenGuruScreen({Key? key}) : super(key: key);

  @override
  _RekapAbsenGuruScreenState createState() => _RekapAbsenGuruScreenState();
}

class _RekapAbsenGuruScreenState extends State<RekapAbsenGuruScreen> {
  List<dynamic> listRekapGuru = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRekapAbsenGuru();
  }

  Future<void> _fetchRekapAbsenGuru() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(iUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "getRekapAbsenGuru", // Sesuaikan dengan action di Apps Script backend Anda
          "id_lembaga": idLembaga,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            listRekapGuru = data['data'] ?? [];
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
      print("Error: $e");
    }
  }

  // Fungsi Cetak PDF Rekap Absen Guru sesuai kolom spreadsheet
  Future<void> _cetakPdfRekapGuru() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // Menggunakan landscape agar tabel muat banyak kolom
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "LAPORAN REKAPITULASI ABSENSI GURU & PEGAWAI",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No', 'Nama', 'Bulan', 'Hadir', 'Terlambat', 'Izin', 'Sakit', 'Cuti', 'Tidak Masuk', 'Total'],
                data: List.generate(listRekapGuru.length, (index) {
                  final guru = listRekapGuru[index];
                  return [
                    (index + 1).toString(),
                    guru['Nama'] ?? 'Tanpa Nama',
                    guru['Bulan'] ?? '-',
                    guru['Hadir']?.toString() ?? '0',
                    guru['Terlambat']?.toString() ?? '0',
                    guru['Izin']?.toString() ?? '0',
                    guru['Sakit']?.toString() ?? '0',
                    guru['Cuti']?.toString() ?? '0',
                    guru['Tidak Masuk']?.toString() ?? '0',
                    guru['Total Kehadiran']?.toString() ?? '0',
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.center,
                  7: pw.Alignment.center,
                  8: pw.Alignment.center,
                  9: pw.Alignment.center,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rekap_Absensi_Guru.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Absensi Guru & Pegawai"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.teal.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Data Kehadiran Guru",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total: ${listRekapGuru.length} Pegawai",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: listRekapGuru.isEmpty ? null : _cetakPdfRekapGuru,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text("Cetak PDF"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : listRekapGuru.isEmpty
                    ? const Center(child: Text("Belum ada data rekap absen guru."))
                    : ListView.builder(
                        itemCount: listRekapGuru.length,
                        itemBuilder: (context, index) {
                          final guru = listRekapGuru[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withOpacity(0.1),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                guru['Nama'] ?? 'Tanpa Nama',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Bulan: ${guru['Bulan'] ?? '-'}\n"
                                "Hadir: ${guru['Hadir'] ?? 0} | Terlambat: ${guru['Terlambat'] ?? 0} | Izin: ${guru['Izin'] ?? 0}\n"
                                "Sakit: ${guru['Sakit'] ?? 0} | Cuti: ${guru['Cuti'] ?? 0} | Absen: ${guru['Tidak Masuk'] ?? 0}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                              ),
                              isThreeLine: true,
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