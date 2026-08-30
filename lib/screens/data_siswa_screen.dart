import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class DataSiswaScreen extends StatefulWidget {
  final String kelas; // Menerima parameter kelas dari dashboard/login
  const DataSiswaScreen({Key? key, required this.kelas}) : super(key: key);

  @override
  _DataSisnaScreenState createState() => _DataSisnaScreenState();
}

class _DataSisnaScreenState extends State<DataSiswaScreen> {
  List<dynamic> listSiswa = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataSiswa();
  }

  Future<void> fetchDataSiswa() async {
    setState(() { isLoading = true; });
    try {
      var url = Uri.parse(AppConfig.apiUrl);
      var client = http.Client();
      
      var request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          "action": "getDataSiswa",
          "kelas": widget.kelas,
          "id_lembaga": idLembaga,
        });

      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (!mounted) return;

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> rawData = data['data'] ?? [];
          setState(() {
            listSiswa = rawData;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Siswa Kelas ${widget.kelas}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : listSiswa.isEmpty
              ? Center(child: Text("Tidak ada data siswa untuk kelas ini."))
              : ListView.builder(
                  itemCount: listSiswa.length,
                  itemBuilder: (context, index) {
                    var siswa = listSiswa[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          siswa['Nama'] ?? siswa['nama'] ?? 'Tanpa Nama',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}