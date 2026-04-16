import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_state.dart';
import 'screens/app_read_state.dart';
import 'services/profile_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 1. Učitaj auth token iz SharedPreferences
  final isLoggedIn = await AuthState.loadFromStorage();

  if (isLoggedIn) {
    RegistrationState.instance.isRegistered = true;
    RegistrationState.instance.username = AuthState.instance.username ?? '';
    RegistrationState.instance.displayName = AuthState.instance.displayName ?? '';
  }

  // 2. Uvijek učitaj profil (postoji i bez logina — lokalni podaci)
  final profile = await ProfileStorage.loadProfile();
  if (profile != null) {
    globalProfileData = profile;
  }

  // 3. Učitaj read state za notifikacije i chat
  await AppReadState.loadFromStorage();

  runApp(MeetCuteApp(startLoggedIn: isLoggedIn));
}

class MeetCuteApp extends StatelessWidget {
  final bool startLoggedIn;
  const MeetCuteApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
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
      home: startLoggedIn ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}