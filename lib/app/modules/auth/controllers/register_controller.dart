import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/utils/app_snackbar.dart';

class RegisterController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isObscurePassword = true.obs;
  final RxBool isObscureConfirmPassword = true.obs;

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      AppSnackbar.warning(
        'Pendaftaran Gagal',
        'Mohon isi semua kolom pendaftaran.',
      );
      return;
    }

    if (username.length < 3) {
      AppSnackbar.warning(
        'Username Terlalu Pendek',
        'Username minimal 3 karakter.',
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      AppSnackbar.warning(
        'Username Tidak Valid',
        'Username hanya boleh berisi huruf, angka, dan underscore.',
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      AppSnackbar.warning(
        'Format Email Salah',
        'Mohon masukkan alamat email yang valid.',
      );
      return;
    }

    if (password.length < 6) {
      AppSnackbar.warning(
        'Password Terlalu Pendek',
        'Password minimal 6 karakter.',
      );
      return;
    }

    if (password.length > 100) {
      AppSnackbar.warning(
        'Password Terlalu Panjang',
        'Password maksimal 100 karakter.',
      );
      return;
    }

    if (password != confirmPassword) {
      AppSnackbar.error(
        'Konfirmasi Password Salah',
        'Password dan Konfirmasi Password tidak cocok.',
      );
      return;
    }

    final success = await authService.register(
      username: username,
      email: email,
      password: password,
    );

    if (success) {
      Get.defaultDialog(
        title: 'Registrasi Berhasil!',
        middleText: 'Akun Anda berhasil dibuat. Silakan login menggunakan username atau email Anda.',
        textConfirm: 'Ke Halaman Login',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF8B4513),
        onConfirm: () {
          Get.back(); // Close Dialog
          Get.back(); // Back to Login Screen
        },
      );
    } else {
      AppSnackbar.error(
        'Registrasi Gagal',
        'Username atau Email sudah terdaftar. Gunakan yang lain.',
      );
    }
  }
}
