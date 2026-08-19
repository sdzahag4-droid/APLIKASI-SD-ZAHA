import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan package ini untuk menyimpan sesi admin
import '../config.dart';
import '../services/fcm_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final usernameInput = _usernameController.text.trim();
    final passwordInput = _passwordController.text.trim();

    if (usernameInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username dan Password tidak boleh kosong!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. CEK LOGIN KHUSUS AKUN ADMIN
      if (usernameInput == 'admin' && passwordInput == 'sklhmju') {
        // Set status admin menjadi true di SharedPreferences
        await prefs.setBool('isAdmin', true);

        var adminUserData = {
          'id': 'ADMIN_01',
          'nama': 'Administrator',
          'username': 'admin',
          'role': 'admin',
        };

        if (!mounted) return;

        // Masuk ke Dashboard dengan membawa data admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(userData: adminUserData)),
        );
        return;
      }

      // 2. JIKA BUKAN ADMIN, LANJUTKAN LOGIN NORMAL VIA API SERVER
      await prefs.setBool('isAdmin', false); // Pastikan status admin false untuk user biasa

      final response = await http.get(
        Uri.parse(
          "${AppConfig.apiUrl}?action=login&username=${Uri.encodeComponent(usernameInput)}&password=${Uri.encodeComponent(passwordInput)}&id_lembaga=${AppConfig.idLembaga}"
        ),
      );

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        var userData = result['data'];

        // Kirim FCM Token
        FcmService.updateFcmToken(userData['id']);

        if (!mounted) return;
        
        // Masuk ke Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(userData: userData)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login gagal")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      debugPrint("Detail Login Error: $errorMessage");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal terhubung ke server. Periksa koneksi internet atau deployment Apps Script."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                AppConfig.appName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                AppConfig.namaLembaga,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}