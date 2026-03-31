import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME STATE
// ═══════════════════════════════════════════════════════════════════════════════

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

// ─── Light palette ──────────────────────────────────────────────────────────
const Color kLightBg      = Color(0xFFF5EDEF);   // warm rosy surface
const Color kLightCard    = Color(0xFFFFFFFF);
const Color kLightCardEl  = Color(0xFFF2E8E9);   // elevated card / chips
const Color kLightPrimary = Color(0xFF700D25);   // bordo
const Color kLightAccent  = Color(0xFFF2E8E9);   // light pink
const Color kLightText    = Color(0xFF1C0A10);   // near-black
const Color kLightTextSub = Color(0xFF8C6A72);   // muted rosy grey

// ─── Dark palette ────────────────────────────────────────────────────────────
// Neutral dark — bordo as a vibrant accent, NOT as background
const Color kDarkBg       = Color(0xFF000000);   // near-black neutral
const Color kDarkCard     = Color(0xFF393737);   // card surface
const Color kDarkCardEl   = Color(0xFF5A5A61);   // elevated card / chips
const Color kDarkPrimary  = Color(0xFFBF8997);   // vivid rose-bordo — readable on dark
const Color kDarkAccent   = Color(0xFFF2A8B8);   // soft pastel pink
const Color kDarkText     = Color(0xFF785661);   // near-white
const Color kDarkTextSub  = Color(0xFF8E8E93);   // iOS-style secondary

// ─── Semantic getters ────────────────────────────────────────────────────────
extension AppColors on ThemeState {
  Color get bg       => isDark ? kDarkBg      : kLightBg;
  Color get card     => isDark ? kDarkCard    : kLightCard;
  Color get cardEl   => isDark ? kDarkCardEl  : kLightCardEl;
  Color get primary  => isDark ? kDarkPrimary : kLightPrimary;
  Color get accent   => isDark ? kDarkAccent  : kLightAccent;
  Color get text     => isDark ? kDarkText    : kLightText;
  Color get textSub  => isDark ? kDarkTextSub : kLightTextSub;
  // Nav badge always white-on-primary
  Color get badgeFg  => isDark ? kDarkBg      : Colors.white;
}