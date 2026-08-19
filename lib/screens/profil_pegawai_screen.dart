import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ProfilPegawaiScreen extends StatelessWidget {
  const ProfilPegawaiScreen({super.key});

  Future<List<dynamic>> _fetchPegawai() async {
    final res = await http.get(Uri.parse("${AppConfig.apiUrl}?action=Users"));
    final data = json.decode(res.body);
    // Filter hanya Role Guru & Karyawan
    return data['data'].where((user) => user['Role'] == 'Guru' || user['Role'] == 'Karyawan').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Guru & Karyawan"), backgroundColor: Colors.amber[800]),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchPegawai(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var peg = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(peg['Nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${peg['Role']} - ${peg['Jabatan']}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📱 WhatsApp : ${peg['WhatsApp']}"),
                          Text("✈️ Telegram : ${peg['Telegram']}"),
                          const Divider(),
                          Text("🏡 Alamat   : Desa ${peg['Desa']}, Kec. ${peg['Kecamatan']}, Prov. ${peg['Provinsi']}"),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}