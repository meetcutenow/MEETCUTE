import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/auth_state.dart';
import '../screens/onboarding_screen.dart' show OnboardingScreen, RegistrationState;
import '../screens/notifications_screen.dart' show NotificationState, NotificationPollingService;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiHttp {
  static const String base = 'http://localhost:8080/api';

  static Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && AuthState.instance.isLoggedIn) {
      headers['Authorization'] = 'Bearer ${AuthState.instance.accessToken}';
    }
    return headers;
  }

  static Future<http.Response> get(String path, {bool auth = true}) async {
    final resp = await http.get(
      Uri.parse('$base$path'),
      headers: _headers(auth: auth),
    ).timeout(const Duration(seconds: 10));
    _check401(resp);
    return resp;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final resp = await http.post(
      Uri.parse('$base$path'),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    _check401(resp);
    return resp;
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final resp = await http.put(
      Uri.parse('$base$path'),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    _check401(resp);
    return resp;
  }

  static Future<http.Response> delete(String path, {bool auth = true}) async {
    final resp = await http.delete(
      Uri.parse('$base$path'),
      headers: _headers(auth: auth),
    ).timeout(const Duration(seconds: 10));
    _check401(resp);
    return resp;
  }

  static void _check401(http.Response resp) {
    if (resp.statusCode == 401) {
      _logout();
    }
  }

  static Future<void> _logout() async {
    if (!AuthState.instance.isLoggedIn) return;

    NotificationPollingService.stop();
    NotificationState.instance.clearLocal();
    await AuthState.instance.clear();
    RegistrationState.instance.isRegistered = false;

    navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
          (route) => false,
    );
  }
}