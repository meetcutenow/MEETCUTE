// ============================================================
// ZAMJENI main.dart s ovom verzijom
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_state.dart';
import 'screens/app_read_state.dart';
import 'screens/company_auth_state.dart';
import 'screens/company_home_screen.dart';
import 'services/profile_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  }

  final profile = await ProfileStorage.loadProfile();
  if (profile != null) {
    globalProfileData = profile;
  }

  await AppReadState.loadFromStorage();

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