import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config.dart';

class FcmService {
  static Future<void> updateFcmToken(dynamic userId) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await http.post(
          Uri.parse(AppConfig.apiUrl),
          body: json.encode({
            "action": "update_fcm_token",
            "id_user": userId,
            "fcm_token": fcmToken,
          }),
        );
      }
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }
}