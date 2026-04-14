import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class PushNotificationService {
  static const String _fallbackVapidKey =
      'BOLYRSwKpj7Mo9FcfA4aF8tQWQbV_ObogKStUb2XatumAlKIZT2aO-R6m6h2nGMdz1nHjlicTeO1_LHpQvAlNTM';
  static const String _envVapidKey = String.fromEnvironment(
    'FCM_WEB_VAPID_KEY',
    defaultValue: '',
  );
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _currentUserId;

  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    await _tokenRefreshSubscription?.cancel();
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final webVapidKey = _resolveWebVapidKey();
      final token = await messaging
          .getToken(vapidKey: kIsWeb ? webVapidKey : null)
          .timeout(const Duration(seconds: 8));

      if (token != null && token.isNotEmpty) {
        await _saveUserToken(userId, token);
      }

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        _saveUserToken(userId, newToken);
      });

      // Listen for foreground FCM messages and show overlay notification
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? '';
        final body = message.notification?.body ?? '';
        if (title.isNotEmpty) {
          NotificationService.showPushNotification(title, body);
        }
      });
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  String? _resolveWebVapidKey() {
    if (!kIsWeb) return null;
    final candidate = _envVapidKey.isNotEmpty
        ? _envVapidKey
        : _fallbackVapidKey;
    final normalized = candidate.trim();
    if (normalized.isEmpty || normalized.startsWith('REPLACE_WITH')) {
      return null;
    }

    final vapidPattern = RegExp(r'^[A-Za-z0-9_-]{80,}$');
    if (!vapidPattern.hasMatch(normalized)) {
      debugPrint('FCM VAPID key seems invalid format.');
      return null;
    }
    return normalized;
  }

  Future<void> _saveUserToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}
