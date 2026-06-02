import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityState {
  static final AccessibilityState instance = AccessibilityState._();
  AccessibilityState._();

  static final fontSizeStep = ValueNotifier<int>(1); // 0=malo, 1=normalno, 2=veliko
  static final dyslexia     = ValueNotifier<bool>(false);

  static Future<void> loadFromStorage() async {
    final p = await SharedPreferences.getInstance();
    fontSizeStep.value = p.getInt('a11y_font') ?? 1;
    dyslexia.value     = p.getBool('a11y_dys')  ?? false;
  }

  static Future<void> setFontStep(int step) async {
    fontSizeStep.value = step.clamp(0, 2);
    (await SharedPreferences.getInstance()).setInt('a11y_font', fontSizeStep.value);
  }

  static Future<void> toggleDyslexia() async {
    dyslexia.value = !dyslexia.value;
    (await SharedPreferences.getInstance()).setBool('a11y_dys', dyslexia.value);
  }

  static Future<void> reset() async {
    fontSizeStep.value = 1;
    dyslexia.value     = false;
    final p = await SharedPreferences.getInstance();
    p.setInt('a11y_font', 1);
    p.setBool('a11y_dys', false);
  }

  static double get textScale {
    switch (fontSizeStep.value) {
      case 0: return 0.85;
      case 2: return 1.30;
      default: return 1.0;
    }
  }

  static String? get fontFamily => dyslexia.value ? 'OpenDyslexic' : 'SF Pro Display';
}