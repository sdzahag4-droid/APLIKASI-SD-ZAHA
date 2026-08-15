import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.subscribeToTopic('semua_user');
    } catch (e) {
      debugPrint("Firebase init error (Non-Web): $e");
    }
  }

  runApp(const SDZAHAApp());
}

class SDZAHAApp extends StatelessWidget {
  const SDZAHAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
        ),
        useMaterial3: true,
        // DENGAN FALLBACK FONT UNTUK MENGHILANGKAN WARNING NOTO FONT DI WEB
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          fontFamilyFallback: ['Roboto', 'Noto Sans', 'sans-serif'],
        ),
      ),
      home: const LoginScreen(),
    );
  }
}