import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AbsenWaliScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AbsenWaliScreen({super.key, required this.userData});

  @override
  State<AbsenWaliScreen> createState() => _AbsenWaliScreenState();
}

class _AbsenWaliScreenState extends State<AbsenWaliScreen> {
  late Map<String, dynamic> currentUser;
  bool _isUploading = false;
  bool _isLoadingSummary = true;
  final ImagePicker _picker = ImagePicker();

  int totalSiswa = 0;
  int totalHadir = 0;
  int totalIzin = 0;
  int totalAlpa = 0;

  @override
  void initState() {
    super.initState();
    currentUser = Map<String, dynamic>.from(widget.userData);
    _fetchRingkasanAbsen();
  }

  // Fungsi untuk mengambil ringkasan data siswa & absensi berdasarkan kelas guru aktif
  Future<void> _fetchRingkasanAbsen() async {
    setState(() => _isLoadingSummary = true);
    try {
      String kelas = currentUser['kelas'] ?? '5A';
      String idLembaga = currentUser['id_lembaga'] ?? '';

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}?action=getSiswaKelas&kelas=$kelas&id_lembaga=$idLembaga'),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        List dataSiswa = result['data'] ?? [];
        
        // Hitung statistik secara dinamis dari data API
        int hadir = 0;
        int izin = 0;
        int alpa = 0;

        for (var siswa in dataSiswa) {
          String status = (siswa['status'] ?? 'Hadir').toString().toLowerCase();
          if (status == 'hadir') {
            hadir++;
          } else if (status == 'izin' || status == 'sakit') {
            izin++;
          } else {
            alpa++;
          }
        }

        setState(() {
          totalSiswa = dataSiswa.length;
          totalHadir = hadir > 0 ? hadir : dataSiswa.length; // Default hadir jika belum absen
          totalIzin = izin;
          totalAlpa = alpa;
        });
      }
    } catch (e) {
      // Jika gagal, biarkan nilai default atau tangani error senyap
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  void _pickAndUploadImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const Text(
              "Ganti Foto Profil",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Pilih dari Galeri"),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("Ambil Foto dari Kamera"),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      List<int> imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      String username = currentUser['username'] ?? currentUser['nama'] ?? '';

      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'action': 'uploadFoto',
          'username': username,
          'fileBase64': base64Image,
        }),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          currentUser['foto'] = result['photo_url'];
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? "Gagal mengunggah foto.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengunggah foto: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildProfileAvatarWithEdit(String nama, String? photoUrl) {
    bool hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF334155),
            backgroundImage: hasPhoto
                ? (photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl)
                    : AssetImage(photoUrl) as ImageProvider)
                : null,
            child: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : (!hasPhoto
                    ? Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFeatureDialog(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(description),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String namaGuru = currentUser['nama'] ?? 'Irawati, S.Pd.I.';
    String kelas = currentUser['kelas'] ?? '5A';
    String? photoUrl = currentUser['foto'] ?? currentUser['photo_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dashboard Absensi Siswa'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.namaLembaga.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Selamat Datang,",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          namaGuru,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Wali Kelas $kelas",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildProfileAvatarWithEdit(namaGuru, photoUrl),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Ringkasan Kehadiran Hari Ini",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            _isLoadingSummary
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.groups,
                          label: "Siswa",
                          value: "$totalSiswa",
                          color: Colors.blue.shade700,
                          bgColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          label: "Hadir",
                          value: "$totalHadir",
                          color: Colors.green.shade700,
                          bgColor: Colors.green.shade50,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.info,
                          label: "Izin",
                          value: "$totalIzin",
                          color: Colors.amber.shade800,
                          bgColor: Colors.amber.shade50,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.cancel,
                          label: "Alpa",
                          value: "$totalAlpa",
                          color: Colors.red.shade700,
                          bgColor: Colors.red.shade50,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 24),

            const Text(
              "Menu Kelas",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              context,
              icon: Icons.assignment_turned_in,
              title: "Input Absensi Cepat",
              subtitle: "Input dan catat kehadiran harian secara ringkas",
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbsensiSiswaScreen(userData: currentUser),
                  ),
                ).then((_) => _fetchRingkasanAbsen()); // Refresh ringkasan setelah kembali
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.person_search,
              title: "Data Siswa",
              subtitle: "Lihat daftar dan profil siswa Kelas $kelas",
              color: const Color(0xFF0D9488),
              onTap: () {
                _showFeatureDialog(
                  context,
                  "Data Siswa Kelas $kelas",
                  "Fitur untuk melihat data profil siswa, kontak wali murid, dan riwayat siswa Kelas $kelas.",
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.analytics,
              title: "Rekap Kelas",
              subtitle: "Persentase kehadiran bulanan siswa",
              color: const Color(0xFF7C3AED),
              onTap: () {
                _showFeatureDialog(
                  context,
                  "Rekap Kehadiran",
                  "Fitur rekapitulasi persentase tingkat kehadiran siswa Kelas $kelas secara bulanan.",
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.description,
              title: "Laporan",
              subtitle: "Cetak dan ekspor laporan kelas",
              color: const Color(0xFFDC2626),
              onTap: () {
                _showFeatureDialog(
                  context,
                  "Laporan Kelas",
                  "Fitur untuk mengunduh dan mencetak laporan resmi absensi dalam format PDF/Excel.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bgColor,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ==========================================
// KELAS ABSENSI SISWA (DINAMIS MENGAMBIL API)
// ==========================================
class AbsensiSiswaScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AbsensiSiswaScreen({super.key, this.userData});

  @override
  State<AbsensiSiswaScreen> createState() => _AbsensiSiswaScreenState();
}

class _AbsensiSiswaScreenState extends State<AbsensiSiswaScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> daftarSisamDinamic = [];

  @override
  void initState() {
    super.initState();
    _fetchDataSiswaAPI();
  }

  Future<void> _fetchDataSiswaAPI() async {
    setState(() => _isLoading = true);
    try {
      String kelas = widget.userData?['kelas'] ?? '5A';
      String idLembaga = widget.userData?['id_lembaga'] ?? '';

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}?action=getSiswaKelas&kelas=$kelas&id_lembaga=$idLembaga'),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        List rawData = result['data'] ?? [];
        setState(() {
          daftarSisamDinamic = rawData.map<Map<String, dynamic>>((item) {
            return {
              "nis": item['nis'] ?? item['username'] ?? '-',
              "nama": item['nama'] ?? item['Nama'] ?? 'Tanpa Nama',
              "status": item['status'] ?? 'Hadir',
            };
          }).toList();
        });
      } else {
        throw Exception(result['message'] ?? 'Gagal memuat data siswa.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error memuat siswa: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _simpanAbsensi() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse(iUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "simpanAbsensiSiswa",
          "kelas": kelas,
          "wali_kelas": namaWaliKelas,
          "id_lembaga": idLembaga,
          "siswa": listSiswa.map((s) => {
            "id_siswa": s['id_user'] ?? s['id_siswa'],
            "nama_siswa": s['nama'] ?? s['nama_siswa'],
            "status": s['status']
          }).toList()
        }),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi berhasil disimpan!')),
        );
      }
    } catch (e) {
      print("Error simpan absensi: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    String kelas = widget.userData?['kelas'] ?? '5A';

    return Scaffold(
      appBar: AppBar(
        title: Text("Form Absensi Kelas $kelas"),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : daftarSisamDinamic.isEmpty
              ? const Center(
                  child: Text(
                    "Tidak ada data siswa untuk kelas ini.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: daftarSisamDinamic.length,
                        itemBuilder: (context, index) {
                          var siswa = daftarSisamDinamic[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(siswa['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("NIS: ${siswa['nis']}"),
                              trailing: DropdownButton<String>(
                                value: siswa['status'],
                                items: ["Hadir", "Izin", "Sakit", "Alpha"]
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    daftarSisamDinamic[index]['status'] = val!;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _simpanAbsensi,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Simpan & Kirim Absensi", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
    );
  }
}