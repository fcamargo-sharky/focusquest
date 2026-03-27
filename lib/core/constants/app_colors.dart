import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────────────
  /// Dusty horizon blue — calm water / 水色
  static const Color primary = Color(0xFF7E9EC0);

  /// Matcha sage — bamboo grove / 抹茶
  static const Color secondary = Color(0xFF9AAD8A);

  // ── Dark backgrounds ──────────────────────────────────────────────────────
  /// Deep ink black — sumi-e brushed / 墨
  static const Color darkBg = Color(0xFF0D0D12);

  /// Ink surface — layered washi
  static const Color darkSurface = Color(0xFF141419);

  /// Soft ink card
  static const Color darkCard = Color(0xFF1B1B23);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Warm washi cream
  static const Color textPrimary = Color(0xFFE2DDD6);

  /// Warm stone grey
  static const Color textSecondary = Color(0xFFA39D96);

  /// Charcoal dust
  static const Color textMuted = Color(0xFF5A5651);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Soft sage green
  static const Color success = Color(0xFF8DAB89);

  /// Muted rose — wabi-sabi
  static const Color error = Color(0xFFB57A7A);

  // ── Priority ─────────────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF8DAB89);
  static const Color priorityMedium = Color(0xFFCDA070);
  static const Color priorityHigh = Color(0xFFB57A7A);

  // ── Accent ───────────────────────────────────────────────────────────────
  /// Antique bronze / 金
  static const Color xpColor = Color(0xFFCDA070);

  /// Terracotta autumn / 紅葉
  static const Color streakColor = Color(0xFFC4785A);

  // ── Subject palette — nature-inspired, muted ─────────────────────────────
  static const List<Color> subjectColors = [
    Color(0xFF7E9EC0), // dusty blue
    Color(0xFF8DAB89), // sage
    Color(0xFF7AABB0), // muted teal
    Color(0xFFCDA070), // warm amber
    Color(0xFFB57A7A), // muted rose
    Color(0xFF9E8EB8), // soft lavender
    Color(0xFF6E9CB5), // slate blue
    Color(0xFFAD8E8E), // dusty mauve
  ];
}
