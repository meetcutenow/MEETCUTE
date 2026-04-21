import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meetcute/screens/notifications_screen.dart';
import 'package:meetcute/screens/theme_state.dart';
import 'screens/home_screen.dart';
import 'screens/auth_state.dart';
import 'screens/app_read_state.dart';
import 'screens/company_auth_state.dart';
import 'screens/company_home_screen.dart';
import 'services/profile_storage.dart';
import 'screens/profile_setup_screen.dart' show ProfileSetupData;
import 'screens/onboarding_screen.dart' show globalProfileData, RegistrationState, OnboardingScreen;
import 'screens/events_nearby.dart' show attendanceState;
import 'screens/notifications_screen.dart' show NotificationPollingService, NotificationState;

const String _base = 'http://localhost:8080/api';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeState.loadFromStorage();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 1. Provjeri company login
  final isCompanyLoggedIn = await CompanyAuthState.loadFromStorage();
  if (isCompanyLoggedIn) {
    runApp(MeetCuteApp(startLoggedIn: false, startAsCompany: true));
    return;
  }

  // 2. Provjeri user login
  final isLoggedIn = await AuthState.loadFromStorage();

  if (isLoggedIn) {
    RegistrationState.instance.isRegistered = true;
    RegistrationState.instance.username = AuthState.instance.username ?? '';
    RegistrationState.instance.displayName = AuthState.instance.displayName ?? '';

    // ── Povuci profil s backenda ──────────────────────────────
    try {
      final resp = await http.get(
        Uri.parse('$_base/users/me'),
        headers: {
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes))['data']
        as Map<String, dynamic>;

        final user    = data;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final photos  = List<String>.from(data['photoUrls'] ?? []);
        final interests = List<String>.from(data['interests'] ?? []);

        // Ažuriraj RegistrationState
        RegistrationState.instance.displayName = user['displayName'] ?? '';
        RegistrationState.instance.username    = user['username'] ?? '';

        // Popuni globalProfileData iz backenda
        globalProfileData = ProfileSetupData(
          photoPaths:    photos,
          birthDay:      profile['birthDay'],
          birthMonth:    profile['birthMonth'],
          birthYear:     profile['birthYear'],
          height:        profile['heightCm']?.toString(),
          gender:        profile['gender'],
          hairColor:     profile['hairColor'],
          eyeColor:      profile['eyeColor'],
          piercing:   profile['hasPiercing'] == true ? 'da' : 'ne',
          tattoo:     profile['hasTattoo']   == true ? 'da' : 'ne',
          interests:     interests,
          iceBreaker:    profile['iceBreaker'] ?? '',
          seekingGender: profile['seekingGender'],
          prefAgeFrom:   profile['prefAgeFrom'],
          prefAgeTo:     profile['prefAgeTo'],
        );

        // Spremi lokalno za offline rad
        await ProfileStorage.saveProfile(globalProfileData);
      } else {
        // Backend nije dostupan — učitaj lokalno
        final local = await ProfileStorage.loadProfile();
        if (local != null) globalProfileData = local;
      }
    } catch (_) {
      // Nema interneta — učitaj lokalno
      final local = await ProfileStorage.loadProfile();
      if (local != null) globalProfileData = local;
    }
    // ─────────────────────────────────────────────────────────
  }
  // Učitaj prijave na evente s backenda
  if (isLoggedIn) {
    try {
      final resp = await http.get(
        Uri.parse('$_base/events'),
        headers: {'Authorization': 'Bearer ${AuthState.instance.accessToken}'},
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List? ?? [];
        for (final e in list) {
          if (e['isAttending'] == true) {
            final title = e['title'] as String? ?? '';
            attendanceState[title] = true;
          }
        }
      }
    } catch (_) {}
  }

  if (isLoggedIn) {
    NotificationPollingService.start();
  }

  await AppReadState.loadFromStorage();
  await NotificationState.loadDeletedIds();

  runApp(MeetCuteApp(startLoggedIn: isLoggedIn, startAsCompany: false));
}

class MeetCuteApp extends StatelessWidget {
  final bool startLoggedIn;
  final bool startAsCompany;
  const MeetCuteApp({super.key, required this.startLoggedIn, required this.startAsCompany});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (startAsCompany) {
      home = const CompanyHomeScreen();
    } else if (startLoggedIn) {
      home = const HomeScreen();
    } else {
      home = const OnboardingScreen();
    }

    return MaterialApp(
      title: 'MeetCute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF700D25),
        ),
      ),
      home: home,
    );
  }
}