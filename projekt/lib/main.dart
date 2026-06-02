import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:meetcute/screens/theme_state.dart';
import 'package:meetcute/screens/accessibility_state.dart';
import 'package:meetcute/screens/notifications_screen.dart';
import 'package:meetcute/screens/home_screen.dart';
import 'package:meetcute/screens/auth_state.dart';
import 'package:meetcute/screens/app_read_state.dart';
import 'package:meetcute/screens/company_auth_state.dart';
import 'package:meetcute/screens/company_home_screen.dart';
import 'package:meetcute/services/profile_storage.dart';
import 'package:meetcute/services/api_http.dart';

import 'package:meetcute/screens/profile_setup_screen.dart' show ProfileSetupData;
import 'package:meetcute/screens/onboarding_screen.dart'
    show globalProfileData, RegistrationState, OnboardingScreen;
import 'package:meetcute/screens/events_nearby.dart' show attendanceState;
import 'package:meetcute/screens/notifications_screen.dart'
    show NotificationPollingService, NotificationState;

const String _base = 'http://localhost:8080/api';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeState.loadFromStorage();
  await AccessibilityState.loadFromStorage();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final isCompanyLoggedIn = await CompanyAuthState.loadFromStorage();
  if (isCompanyLoggedIn) {
    runApp(const MeetCuteApp(startLoggedIn: false, startAsCompany: true));
    return;
  }

  final isLoggedIn = await AuthState.loadFromStorage();

  if (isLoggedIn) {
    RegistrationState.instance.isRegistered = true;
    RegistrationState.instance.username = AuthState.instance.username ?? '';
    RegistrationState.instance.displayName = AuthState.instance.displayName ?? '';

    try {
      final resp = await http
          .get(
        Uri.parse('$_base/users/me'),
        headers: {
          'Authorization': 'Bearer ${AuthState.instance.accessToken}',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 401) {
        await AuthState.instance.clear();
        runApp(const MeetCuteApp(startLoggedIn: false, startAsCompany: false));
        return;
      }

      if (resp.statusCode == 200) {
        final data =
        jsonDecode(utf8.decode(resp.bodyBytes))['data'] as Map<String, dynamic>;

        final user = data;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final photos = List<String>.from(data['photoUrls'] ?? []);
        final interests = List<String>.from(data['interests'] ?? []);

        RegistrationState.instance.displayName = user['displayName'] ?? '';
        RegistrationState.instance.username = user['username'] ?? '';

        globalProfileData = ProfileSetupData(
          photoPaths: photos,
          birthDay: profile['birthDay'],
          birthMonth: profile['birthMonth'],
          birthYear: profile['birthYear'],
          height: profile['heightCm']?.toString(),
          gender: profile['gender'],
          hairColor: profile['hairColor'],
          eyeColor: profile['eyeColor'],
          piercing: profile['hasPiercing'] == true ? 'da' : 'ne',
          tattoo: profile['hasTattoo'] == true ? 'da' : 'ne',
          interests: interests,
          iceBreaker: profile['iceBreaker'] ?? '',
          seekingGender: profile['seekingGender'],
          prefAgeFrom: profile['prefAgeFrom'],
          prefAgeTo: profile['prefAgeTo'],
        );

        await ProfileStorage.saveProfile(globalProfileData);
      } else {
        final local = await ProfileStorage.loadProfile();
        if (local != null) globalProfileData = local;
      }
    } catch (_) {
      final local = await ProfileStorage.loadProfile();
      if (local != null) globalProfileData = local;
    }
  }

  if (isLoggedIn) {
    try {
      final resp = await http
          .get(
        Uri.parse('$_base/events'),
        headers: {'Authorization': 'Bearer ${AuthState.instance.accessToken}'},
      )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final list =
            jsonDecode(utf8.decode(resp.bodyBytes))['data'] as List? ?? [];

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

  runApp(
    MeetCuteApp(
      startLoggedIn: isLoggedIn,
      startAsCompany: false,
    ),
  );
}

class MeetCuteApp extends StatefulWidget {
  final bool startLoggedIn;
  final bool startAsCompany;

  const MeetCuteApp({
    super.key,
    required this.startLoggedIn,
    required this.startAsCompany,
  });

  @override
  State<MeetCuteApp> createState() => _MeetCuteAppState();
}

class _MeetCuteAppState extends State<MeetCuteApp> {

  @override
  void initState() {
    super.initState();
    ThemeState.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    ThemeState.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (widget.startAsCompany) {
      home = const CompanyHomeScreen();
    } else if (widget.startLoggedIn) {
      home = const HomeScreen();
    } else {
      home = const OnboardingScreen();
    }

    // ValueListenableBuilder reagira ODMAH na svaku promjenu ValueNotifiera
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityState.dyslexia,
      builder: (_, dys, __) => ValueListenableBuilder<int>(
        valueListenable: AccessibilityState.fontSizeStep,
        builder: (_, fontStep, __) {
          final dark       = ThemeState.instance.isDark;
          final fontFamily = AccessibilityState.fontFamily ?? 'SF Pro Display';

          return MediaQuery(
            data: MediaQueryData.fromView(View.of(context)).copyWith(
              textScaler: TextScaler.linear(AccessibilityState.textScale),
            ),
            child: MaterialApp(
              title: 'MeetCute',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: ThemeData(
                fontFamily: fontFamily,
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF700D25),
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                // Eksplicitno postavi fontFamily na SVAKI TextStyle u temi
                textTheme: Typography.material2021().black.apply(fontFamily: fontFamily),
              ),
              // builder se poziva za SVAKI screen u Navigator stacku
              // Theme.of(context) se nasljeđuje svugdje, uključujući AnimatedDefaultTextStyle
              builder: (ctx, child) {
                final currentTheme = Theme.of(ctx);
                return Theme(
                  data: currentTheme.copyWith(
                    textTheme: currentTheme.textTheme.apply(fontFamily: fontFamily),
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(fontFamily: fontFamily, inherit: true),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: home,
            ),
          );
        },
      ),
    );
  }
}