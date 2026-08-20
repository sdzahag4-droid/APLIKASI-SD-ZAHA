import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'absensi_screen.dart';
import 'login_screen.dart';
import 'profil_pegawai_screen.dart';
import 'informasi_screen.dart';
import 'absen_wali_screen.dart';
import 'kenaikan_kelas_screen.dart';
import 'psb_screen.dart';
import 'pembayaran_screen.dart';
import 'jadwal_screen.dart';
import 'agenda_screen.dart';
import 'sarana_screen.dart';
import 'tunggakan_screen.dart';
import 'data_siswa_screen.dart';
import 'rekap_kelas_screen.dart';
import 'laporan_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  void _showSocialMediaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sosial Media', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text('Instagram'),
              onTap: () {
                Navigator.pop(context);
                _openUrl(AppConfig.instagramUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.red),
              title: const Text('YouTube'),
              onTap: () {
                Navigator.pop(context);
                _openUrl(AppConfig.youtubeUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_collection, color: Colors.black),
              title: const Text('TikTok'),
              onTap: () {
                Navigator.pop(context);
                _openUrl(AppConfig.tiktokUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Twitter / X'),
              onTap: () {
                Navigator.pop(context);
                _openUrl(AppConfig.twitterUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.facebook, color: Colors.indigo),
              title: const Text('Facebook'),
              onTap: () {
                Navigator.pop(context);
                _openUrl(AppConfig.facebookUrl);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker(String username) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery, username);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera, username);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatAdminOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hubungi Admin SD ZAHA",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Silakan pilih platform komunikasi yang ingin Anda gunakan:",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.chat, color: Colors.green),
                ),
                title: const Text("WhatsApp Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Chat langsung via WhatsApp"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl("https://wa.me/${AppConfig.whatsappAdmin}?text=Halo%20Admin,%20saya%20ingin%20bertanya%20terkait%20layanan%20sekolah.");
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.send, color: Colors.blue),
                ),
                title: const Text("Telegram Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Chat langsung via Telegram"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _openUrl("https://t.me/${AppConfig.telegramAdmin}");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source, String username) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      Uint8List imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(AppConfig.apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'uploadProfilePhoto',
          'username': username,
          'image_base64': base64Image,
          'file_name': 'profile_$username.jpg',
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          setState(() {
            _photoUrl = res['photo_url'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto profil berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(res['message'] ?? 'Gagal mengunggah foto.');
        }
      } else {
        throw Exception("Server Error (${response.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal unggah foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String role = widget.userData['role'] ?? widget.userData['Role'] ?? '';
    String nama = widget.userData['nama'] ?? widget.userData['Nama'] ?? 'Pengguna';
    String username = widget.userData['username'] ?? widget.userData['Username'] ?? '';
    String? currentPhoto = _photoUrl ?? widget.userData['foto'] ?? widget.userData['Foto'];

    bool hasPhoto = currentPhoto != null && currentPhoto.toString().trim().isNotEmpty;

    String subtitle = "";
    if (role == 'Guru' || role == 'Karyawan') {
      subtitle = "Jabatan: ${widget.userData['jabatan'] ?? widget.userData['Jabatan'] ?? '-'}";
    } else if (role == 'Siswa') {
      subtitle = "Kelas: ${widget.userData['kelas'] ?? widget.userData['Kelas'] ?? '-'}";
    } else {
      subtitle = "Administrator Sistem";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${AppConfig.appName} - ${AppConfig.namaLembaga}"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourcePicker(username),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: hasPhoto
                              ? (currentPhoto.toString().startsWith('http')
                                  ? NetworkImage(currentPhoto)
                                  : AssetImage(currentPhoto) as ImageProvider)
                              : null,
                          child: !hasPhoto
                              ? Text(
                                  nama.isNotEmpty ? nama[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(blurRadius: 4, color: Colors.black26)
                              ],
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.green[800],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Role: $role | $subtitle",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Menu Utama",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                // Menu Khusus Admin atau Wali Kelas
                if (widget.userData['role'] == 'Admin' || widget.userData['jabatan'] == 'Wali Kelas') ...[
                  _buildMenuTile(
                    context,
                    Icons.people,
                    "Data Siswa",
                    Colors.blueAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataSiswaScreen(kelas: widget.userData['kelas'] ?? '1A'),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.school,
                    "Wali Kelas",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AbsenWaliScreen(userData: widget.userData),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.bar_chart,
                    "Rekap Kelas",
                    Colors.teal,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RekapKelasScreen(kelas: widget.userData['kelas'] ?? '1A'),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.description,
                    "Laporan",
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LaporanScreen(kelas: widget.userData['kelas'] ?? '1A'),
                        ),
                      );
                    },
                  ),
                ],

                // Menu Umum untuk Semua Pengguna
                _buildMenuTile(
                  context,
                  Icons.calendar_today,
                  "Jadwal",
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => JadwalScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.event,
                  "Agenda",
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => AgendaScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.domain,
                  "Sarana",
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => SaranaScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.assignment_ind,
                  "PSB",
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => PsbScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.payment,
                  "Pembayaran",
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TunggakanScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.chat,
                  "Chat Admin",
                  Colors.lightBlue,
                  () {
                    _showChatAdminOptions();
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.badge,
                  "Profil Pegawai",
                  Colors.amber[800]!,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ProfilPegawaiScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.share,
                  "Sosial Media",
                  Colors.pink,
                  () {
                    _showSocialMediaDialog(context);
                  },
                ),
                _buildMenuTile(
                  context,
                  Icons.info_outline,
                  "Informasi",
                  Colors.red,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => InformasiScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                if (role == 'Admin')
                  _buildMenuTile(
                    context,
                    Icons.swap_vert_circle,
                    "Kenaikan Kelas",
                    Colors.deepOrange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const KenaikanKelasScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}