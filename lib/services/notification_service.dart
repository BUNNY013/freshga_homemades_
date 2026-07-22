import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Request permissions and initialize FCM token
  static Future<void> initialize() async {
    try {
      // 1. Request Permission (shows native prompt on iOS/Android if needed)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permissions.');
        
        // 2. Fetch the FCM Device Token
        String? token = await _messaging.getToken();
        
        if (token != null) {
          debugPrint('FCM Token generated: $token');
          await _saveTokenToDatabase(token);
        }

        // 3. Listen to token refreshes and update DB
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToDatabase(newToken);
        });
      } else {
        debugPrint('User declined or has not accepted notification permissions.');
      }
    } catch (e) {
      debugPrint("Failed to initialize notifications: $e");
    }
  }

  /// Saves the FCM Token to the currently logged in user's document
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return; // Cannot save token if not logged in

    try {
      await _firestore.collection('customers').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("FCM token securely saved for user ${user.uid}");
    } catch (e) {
      debugPrint("Failed to save FCM token: $e");
    }
  }

  /// Clears the FCM Token from the currently logged in user's document upon logout
  static Future<void> clearToken() async {
    final user = _auth.currentUser;
    if (user == null) return; // No user logged in

    try {
      await _firestore.collection('customers').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Optionally delete the token from the device entirely
      await _messaging.deleteToken();
      
      debugPrint("FCM token securely cleared for user ${user.uid}");
    } catch (e) {
      debugPrint("Failed to clear FCM token: $e");
    }
  }
}
