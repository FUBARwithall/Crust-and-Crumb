import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/utils/app_snackbar.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isObscurePassword = true.obs;

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void login() {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      AppSnackbar.warning(
        'Login Gagal',
        'Mohon isi Username / Email dan Password Anda.',
      );
      return;
    }

    final success = authService.login(identifier: identifier, password: password);
    if (success) {
      Get.offAllNamed(Routes.CATALOG);
      AppSnackbar.success(
        'Login Berhasil',
        'Selamat datang kembali, ${authService.currentUser.value?.username}!',
      );
    } else {
      AppSnackbar.error(
        'Login Gagal',
        'Username / Email atau Password salah.',
      );
    }
  }

  void loginAsGuest() {
    authService.loginAsGuest();
    Get.offAllNamed(Routes.CATALOG);
    AppSnackbar.info(
      'Masuk sebagai Tamu',
      'Anda masuk sebagai pengguna tamu.',
    );
  }
}
