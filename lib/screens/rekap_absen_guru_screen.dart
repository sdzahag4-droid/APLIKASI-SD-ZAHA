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

  // Helper untuk mengubah tanggal raw (ISO) menjadi format "Bulan Tahun" (misal: "Agustus 2026")
  String _formatPeriode(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return '-';

    try {
      DateTime dateTime = DateTime.parse(rawDate);
      const listBulan = [
        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"
      ];

      String namaBulan = listBulan[dateTime.month - 1];
      return "$namaBulan ${dateTime.year}";
    } catch (e) {
      // Jika format bukan tanggal ISO, tampilkan string aslinya
      return rawDate;
    }
  }

  // Mengambil string bulan untuk judul periode header (diambil dari data pertama jika ada)
  String _getJudulPeriode() {
    if (listRekapGuru.isNotEmpty && listRekapGuru[0]['Bulan'] != null) {
      return _formatPeriode(listRekapGuru[0]['Bulan'].toString());
    }
    return "-";
  }

  Future<void> _fetchRekapAbsenGuru() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "getRekapAbsenGuru",
          "id_lembaga": AppConfig.idLembaga,
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
      debugPrint("Error: $e");
    }
  }

  // Fungsi Cetak PDF Rekap Absen Guru
  Future<void> _cetakPdfRekapGuru() async {
    final pdf = pw.Document();
    final periodeTeks = _getJudulPeriode();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // Orientasi landscape
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- JUDUL UTAMA ---
              pw.Text(
                  "SD ZAINUL HASAN GENGGONG",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "LAPORAN REKAPITULASI ABSENSI GURU & PEGAWAI",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),

              // --- KETERANGAN PERIODE BULAN & TAHUN ---
              pw.Text(
                "PERIODE: ${periodeTeks.toUpperCase()}",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 12),

              // --- TABEL DATA ---
              pw.Table.fromTextArray(
                headers: [
                  'No',
                  'Nama',
                  'Bulan',
                  'Hadir',
                  'Terlambat',
                  'Izin',
                  'Sakit',
                  'Cuti',
                  'Tidak Masuk',
                ],
                data: List.generate(listRekapGuru.length, (index) {
                  final guru = listRekapGuru[index];
                  return [
                    (index + 1).toString(),
                    guru['Nama'] ?? 'Tanpa Nama',
                    _formatPeriode(guru['Bulan']?.toString()),
                    guru['Hadir']?.toString() ?? '0',
                    guru['Terlambat']?.toString() ?? '0',
                    guru['Izin']?.toString() ?? '0',
                    guru['Sakit']?.toString() ?? '0',
                    guru['Cuti']?.toString() ?? '0',
                    guru['Tidak Masuk']?.toString() ?? '0',
                  ];
                }),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.teal),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total: ${listRekapGuru.length} Pegawai | Periode: ${_getJudulPeriode()}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      listRekapGuru.isEmpty ? null : _cetakPdfRekapGuru,
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
                    ? const Center(
                        child: Text("Belum ada data rekap absen guru."))
                    : ListView.builder(
                        itemCount: listRekapGuru.length,
                        itemBuilder: (context, index) {
                          final guru = listRekapGuru[index];
                          final periodeStr =
                              _formatPeriode(guru['Bulan']?.toString());

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withOpacity(0.1),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                guru['Nama'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Bulan: $periodeStr\n"
                                "Hadir: ${guru['Hadir'] ?? 0} | Terlambat: ${guru['Terlambat'] ?? 0} | Izin: ${guru['Izin'] ?? 0}\n"
                                "Sakit: ${guru['Sakit'] ?? 0} | Cuti: ${guru['Cuti'] ?? 0} | Absen: ${guru['Tidak Masuk'] ?? 0}",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[800]),
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