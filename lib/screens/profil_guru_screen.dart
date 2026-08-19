import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProfilGuruScreen extends StatefulWidget {
  final String? idLembaga;

  const ProfilGuruScreen({super.key, this.idLembaga});

  @override
  State<ProfilGuruScreen> createState() => _ProfilGuruScreenState();
}

class _ProfilGuruScreenState extends State<ProfilGuruScreen> {
  List<dynamic> _listUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsersData();
  }

  // FUNGSI FETCH DATA USER DENGAN FILTER ROLE YANG LEBIH FLEKSIBEL
  Future<void> _fetchUsersData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Menyusun parameter request dengan aman
      String url = "${AppConfig.apiUrl}?action=Users";
      if (widget.idLembaga != null && widget.idLembaga!.isNotEmpty) {
        url += "&id_lembaga=${widget.idLembaga}";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['status'] == 'success') {
          List<dynamic> data = body['data'] ?? [];

          // Logika Filter Inklusif (Menampilkan Guru, Karyawan, Admin, Staf, dll)
          setState(() {
            _listUsers = data.where((user) {
              String role = (user['Role'] ?? user['role'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
              String jabatan = (user['Jabatan'] ?? user['jabatan'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();

              // Kriteria 1: Jangan tampilkan jika role secara eksplisit adalah 'Siswa'
              if (role == 'siswa') return false;

              // Kriteria 2: Ambil semua data yang mengandung kata kunci guru/karyawan/admin/staf/pengajar/dll.
              bool isGuruKaryawan = role.contains('guru') ||
                  role.contains('karyawan') ||
                  role.contains('admin') ||
                  role.contains('staf') ||
                  role.contains('staff') ||
                  role.contains('pengajar') ||
                  jabatan.contains('guru') ||
                  jabatan.contains('pembina') ||
                  jabatan.contains('kepala') ||
                  jabatan.contains('waka') ||
                  jabatan.contains('ops') ||
                  jabatan.contains('tata usaha') ||
                  jabatan.contains('bendahara') ||
                  jabatan.contains('satpam') ||
                  jabatan.contains('kebun') ||
                  jabatan.contains('penj.');

              // Kriteria 3: Jika role kosong tetapi memiliki jabatan (dan bukan siswa), tetap tampilkan
              bool isRoleEmptyButHasJabatan = role.isEmpty && jabatan.isNotEmpty;

              return isGuruKaryawan || isRoleEmptyHasJabatan;
            }).toList();

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = body['message'] ?? 'Gagal mengambil data dari server.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Server Error (${response.statusCode}). Periksa Deployment Apps Script!";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Slate Clean Background
      appBar: AppBar(
        title: const Text(
          'Profil Guru & Karyawan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A), // Dark Premium Navy
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsersData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchUsersData,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Coba Lagi"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : _listUsers.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada data Guru atau Karyawan.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUsersData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listUsers.length,
                        itemBuilder: (context, index) {
                          var user = _listUsers[index];
                          return _buildUserCard(index + 1, user);
                        },
                      ),
                    ),
    );
  }

  Widget _buildUserCard(int number, Map<String, dynamic> user) {
    String nama = user['Nama'] ?? user['nama'] ?? 'Tanpa Nama';
    String role = user['Role'] ?? user['role'] ?? 'Guru/Karyawan';
    String jabatan = user['Jabatan'] ?? user['jabatan'] ?? '-';
    String? photoUrl = user['foto'] ?? user['Foto'] ?? user['photo_url'];

    bool hasPhoto = photoUrl != null && photoUrl.toString().trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ELEGAN BADGE NOMOR URUT
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  "$number",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. AVATAR FOTO PROFIL
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF0F172A),
                backgroundImage: hasPhoto
                    ? (photoUrl.toString().startsWith('http')
                        ? NetworkImage(photoUrl)
                        : AssetImage(photoUrl) as ImageProvider)
                    : null,
                child: !hasPhoto
                    ? Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          title: Text(
            nama,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                // Tag Role (Guru / Karyawan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: role.toLowerCase().contains('guru')
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: role.toLowerCase().contains('guru')
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "•  $jabatan",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.badge_outlined, "Role", role),
                  _buildDetailRow(Icons.work_outline, "Jabatan", jabatan),
                  _buildDetailRow(Icons.class_outlined, "Kelas Tugas",
                      user['Kelas'] ?? user['kelas'] ?? '-'),
                  _buildDetailRow(Icons.phone_android, "WhatsApp",
                      user['WhatsApp'] ?? user['whatsapp'] ?? '-'),
                  _buildDetailRow(Icons.send, "Telegram",
                      user['Telegram'] ?? user['telegram'] ?? '-'),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    "Alamat",
                    "${user['Desa'] ?? user['desa'] ?? ''}, ${user['Kecamatan'] ?? user['kecamatan'] ?? ''}"
                        .trim(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Text(": ", style: TextStyle(color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}