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
  // Local state untuk menyimpan data user yang aktif (agar foto terbarui secara realtime)
  late Map<String, dynamic> currentUser;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Mockup data statistik (Dapat dihubungkan ke API/Apps Script nanti)
  int totalSiswa = 28;
  int totalHadir = 25;
  int totalIzin = 2;
  int totalAlpa = 1;

  @override
  void initState() {
    super.initState();
    currentUser = Map<String, dynamic>.from(widget.userData);
  }

  // ==========================================
  // FITUR UPLOAD FOTO PROFIL (KAMERA & GALERI)
  // ==========================================
  
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

      // Konversi gambar menjadi Base64
      List<int> imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      String username = currentUser['username'] ?? currentUser['nama'] ?? '';

      // Kirim data ke Google Apps Script (Code.gs)
      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {'Content-Type': 'application/json'},
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

  // WIDGET AVATAR DENGAN IKON KAMERA EDIT FOTO
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
        // Tombol Ikon Kamera kecil di pojok kanan bawah foto
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

  // ==========================================
  // HELPER FUNCTIONS (MODAL & DIALOG)
  // ==========================================

  void _showFormAbsensi(BuildContext context, String kelas) {
    String? selectedSiswa;
    String status = "Hadir";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Input Absensi Kelas $kelas",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Nama Siswa",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Ahmad Rizky", child: Text("Ahmad Rizky")),
                      DropdownMenuItem(
                          value: "Budi Santoso", child: Text("Budi Santoso")),
                      DropdownMenuItem(
                          value: "Siti Fatimah", child: Text("Siti Fatimah")),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedSiswa = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Status Kehadiran",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fact_check),
                    ),
                    value: status,
                    items: const [
                      DropdownMenuItem(value: "Hadir", child: Text("Hadir")),
                      DropdownMenuItem(value: "Izin", child: Text("Izin")),
                      DropdownMenuItem(value: "Sakit", child: Text("Sakit")),
                      DropdownMenuItem(value: "Alpha", child: Text("Alpha")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          status = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (selectedSiswa == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Silakan pilih nama siswa!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Absensi $selectedSiswa ($status) berhasil disimpan!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text(
                        "SIMPAN & KIRIM NOTIFIKASI",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  // ==========================================
  // BUILD METHOD UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    String namaGuru = currentUser['nama'] ?? 'Irawati, S.Pd.I.';
    String kelas = currentUser['kelas'] ?? '5A';
    String? photoUrl = currentUser['foto'] ?? currentUser['photo_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dashboard Wali Kelas'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER / HEADER PROFIL WALI KELAS DENGAN EDIT FOTO PROFIL
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
                  // Sisi Kiri: Teks Informasi
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

                  // Sisi Kanan: Avatar Foto Profil + Tombol Edit Kamera
                  _buildProfileAvatarWithEdit(namaGuru, photoUrl),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. STATISTIK KEHADIRAN RINGKAS
            const Text(
              "Ringkasan Kehadiran Hari Ini",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            Row(
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

            // 3. MENU UTAMA WALI KELAS
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
              title: "Absensi Siswa",
              subtitle: "Input dan catat kehadiran harian siswa",
              color: const Color(0xFF2563EB),
              onTap: () {
                _showFormAbsensi(context, kelas);
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
              icon: Icons.rate_review,
              title: "Catatan Wali Kelas",
              subtitle: "Catatan perkembangan dan perilaku siswa",
              color: const Color(0xFFD97706),
              onTap: () {
                _showFeatureDialog(
                  context,
                  "Catatan Wali Kelas",
                  "Fitur untuk mencatat jurnal perkembangan karakter, prestasi, maupun kedisiplinan siswa.",
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

  // Widget Kartu Statistik
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

  // Widget List Item Menu
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