import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/profile_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final isRegistered = await ProfileStorage.loadRegistration();
  if (isRegistered) {
    RegistrationState.instance.isRegistered = true;
    RegistrationState.instance.username = await ProfileStorage.loadUsername();
    RegistrationState.instance.displayName = await ProfileStorage.loadDisplayName();
    final profile = await ProfileStorage.loadProfile();
    if (profile != null) globalProfileData = profile;
  }

  runApp(const MeetCuteApp());
}

class MeetCuteApp extends StatelessWidget {
  const MeetCuteApp({super.key});

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
      home: RegistrationState.instance.isRegistered
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}