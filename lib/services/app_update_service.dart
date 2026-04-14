import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';
import '../utils/web_reload_stub.dart'
    if (dart.library.html) '../utils/web_reload_web.dart';

class AppUpdateService {
  static const String _githubVersionUrl =
      'https://raw.githubusercontent.com/vitolog76-hub/moto-guzzi-club-pisa/main/docs/version.json';

  static bool _isChecking = false;
  static bool _hasScheduledReload = false;

  static Future<void> checkForUpdateAndReloadIfNeeded() async {
    if (!kIsWeb || _isChecking || _hasScheduledReload) {
      return;
    }

    _isChecking = true;

    try {
      final localVersion = await _fetchVersion(_buildLocalVersionUrl());
      final remoteVersion = await _fetchVersion(_buildRemoteVersionUrl());

      if (localVersion == null || remoteVersion == null) {
        return;
      }

      if (localVersion.trim() != remoteVersion.trim()) {
        _hasScheduledReload = true;
        showSimpleNotification(
          const Text(
            "Nuova versione disponibile. L'app si aggiornerà tra 5 secondi.",
            style: TextStyle(color: Colors.white),
          ),
          background: const Color(0xFF8B0000),
          duration: const Duration(seconds: 5),
        );

        await Future.delayed(const Duration(seconds: 5));
        reloadWebPage();
      }
    } catch (_) {
      // Silent fail: if check fails, app keeps running.
    } finally {
      _isChecking = false;
    }
  }

  static String _buildLocalVersionUrl() {
    final base = Uri.base.resolve('version.json').toString();
    return '$base?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _buildRemoteVersionUrl() {
    return '$_githubVersionUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<String?> _fetchVersion(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {'Cache-Control': 'no-cache'},
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded['version']?.toString();
  }
}
