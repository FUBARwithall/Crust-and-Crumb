import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void _show({
    required String title,
    required String message,
    required Color titleColor,
    required IconData icon,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(icon, color: titleColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 13,
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE5E0D8),
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static void success(String title, String message) {
    _show(
      title: title,
      message: message,
      titleColor: const Color(0xFF2E7D32),
      icon: Icons.check_circle_outline,
    );
  }

  static void error(String title, String message) {
    _show(
      title: title,
      message: message,
      titleColor: const Color(0xFFA72626),
      icon: Icons.error_outline,
    );
  }

  static void warning(String title, String message) {
    _show(
      title: title,
      message: message,
      titleColor: const Color(0xFFD2691E),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void info(String title, String message) {
    _show(
      title: title,
      message: message,
      titleColor: const Color(0xFF8B4513),
      icon: Icons.info_outline,
    );
  }
}
