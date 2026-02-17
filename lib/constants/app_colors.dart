import 'package:flutter/material.dart';

/// Цветовая палитра приложения
class AppColors {
  AppColors._();

  // Основные цвета
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF3F37C9);

  // Акцент
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9E9E);

  // Фоны
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF0F3460);

  // Текст
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // Игровые элементы
  static const Color tileBackground = Color(0xFF2A2A4A);
  static const Color tileSelected = Color(0xFF6C63FF);
  static const Color tileBorder = Color(0xFF3A3A5A);
  static const Color pathLine = Color(0xFF00E676);

  // Статус
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF5252);
}
