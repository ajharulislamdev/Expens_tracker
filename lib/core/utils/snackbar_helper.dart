import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static void success(String message) =>
      _show('Success', message, Colors.green);

  static void error(String message) => _show('Error', message, Colors.red);

  static void info(String message) => _show('Info', message, Colors.blueGrey);

  static void _show(String title, String message, Color color) {
    Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }
}
