import 'package:flutter/material.dart';

/// Предложение цветовой палитры и стиля для SAME SAME
/// 
/// Концепция: Уютный, спокойный, минималистичный стиль для интровертов
/// 
/// Цветовая палитра:
/// - Основной: Мягкий лавандовый/фиолетовый (#8B7EC8) - спокойный, но не скучный
/// - Фон: Теплый кремовый (#FAF9F6) - уютный, не белый
/// - Карточки: Мягкий белый (#FFFFFF) с легкой тенью
/// - Текст: Мягкий темно-серый (#2D2D2D) - не черный, более дружелюбный
/// - Акценты: Теплый коралловый (#FF6B9D) для лайков, мягкий мятный (#7FD8BE) для позитива
/// - Границы: Очень светлый серый (#E8E6E3) - едва заметные
/// 
/// Стиль:
/// - Большие скругления (16-20px) - мягкие формы
/// - Мягкие тени - глубина без агрессии
/// - Просторные отступы - не тесно
/// - Крупный, читаемый шрифт
/// - Плавные анимации

class AppThemeProposal {
  // Основные цвета
  static const Color primary = Color(0xFF8B7EC8); // Мягкий лавандовый
  static const Color primaryLight = Color(0xFFB5A9E0);
  static const Color primaryDark = Color(0xFF6B5F9A);
  
  // Фоны
  static const Color background = Color(0xFFFAF9F6); // Теплый кремовый
  static const Color surface = Color(0xFFFFFFFF); // Белый для карточек
  static const Color surfaceVariant = Color(0xFFF5F3F0); // Светлый вариант
  
  // Текст
  static const Color textPrimary = Color(0xFF2D2D2D); // Мягкий темно-серый
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);
  
  // Акценты
  static const Color accentLike = Color(0xFF7FD8BE); // Мягкий мятный для лайков
  static const Color accentDislike = Color(0xFFFFB3BA); // Мягкий розовый для дизлайков
  static const Color accentHighlight = Color(0xFFFF6B9D); // Теплый коралловый для важного
  
  // Границы и разделители
  static const Color border = Color(0xFFE8E6E3); // Очень светлый серый
  static const Color divider = Color(0xFFE8E6E3);
  
  // Статусы
  static const Color success = Color(0xFF7FD8BE);
  static const Color error = Color(0xFFFFB3BA);
  static const Color warning = Color(0xFFFFD6A5);
  
  // Создание темы
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Цветовая схема
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: accentLike,
        secondaryContainer: accentLike.withOpacity(0.2),
        surface: surface,
        surfaceVariant: surfaceVariant,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: background,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
        ),
        systemOverlayStyle: null,
      ),
      
      // Карточки
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(
            color: primary,
            width: 2,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input поля
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Типографика
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
      ),
    );
  }
  
  // Дополнительные стили для компонентов
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );
}

