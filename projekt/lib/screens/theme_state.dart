import 'package:flutter/material.dart';


class ThemeState extends ChangeNotifier {
  static final ThemeState instance = ThemeState._();
  ThemeState._();

  bool _isDark = false;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// ─── Svijetla paleta ──────────────────────────────────────────────────────────
const Color kLightBg      = Color(0xFFF5EDEF);
const Color kLightCard    = Color(0xFFFFFFFF);
const Color kLightCardEl  = Color(0xFFF2E8E9);
const Color kLightPrimary = Color(0xFF700D25);
const Color kLightAccent  = Color(0xFFF2E8E9);
const Color kLightText    = Color(0xFF1C0A10);
const Color kLightTextSub = Color(0xFF8C6A72);

// ─── Tamna paleta ────────────────────────────────────────────────────────────
const Color kDarkBg       = Color(0xFF000000);
const Color kDarkCard     = Color(0xFF393737);
const Color kDarkCardEl   = Color(0xFF5A5A61);
const Color kDarkPrimary  = Color(0xFFBF8997);
const Color kDarkAccent   = Color(0xFFF2A8B8);
const Color kDarkText     = Color(0xFFB58E97);
const Color kDarkTextSub  = Color(0xFF8E8E93);

// ─── Getteri ────────────────────────────────────────────────────────
extension AppColors on ThemeState {
  Color get bg       => isDark ? kDarkBg      : kLightBg;
  Color get card     => isDark ? kDarkCard    : kLightCard;
  Color get cardEl   => isDark ? kDarkCardEl  : kLightCardEl;
  Color get primary  => isDark ? kDarkPrimary : kLightPrimary;
  Color get accent   => isDark ? kDarkAccent  : kLightAccent;
  Color get text     => isDark ? kDarkText    : kLightText;
  Color get textSub  => isDark ? kDarkTextSub : kLightTextSub;
  Color get badgeFg  => isDark ? kDarkBg      : Colors.white;
}