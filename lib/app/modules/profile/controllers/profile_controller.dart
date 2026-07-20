import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/utils/app_snackbar.dart';

class ProfileController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isObscureNewPassword = true.obs;
  final RxBool isObscureConfirmPassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    final user = authService.currentUser.value;
    if (user != null && !user.isGuest) {
      usernameController.text = user.username;
      emailController.text = user.email;
      phoneController.text = user.phone;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> saveProfile() async {
    if (authService.isGuest) {
      AppSnackbar.warning(
        'Mode Tamu',
        'Anda berada dalam mode Tamu. Silakan daftar akun untuk menyimpan profil.',
      );
      return;
    }

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || phone.isEmpty) {
      AppSnackbar.warning(
        'Data Tidak Lengkap',
        'Mohon isi Username, Email, dan Nomor Telepon.',
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

    if (newPassword.isNotEmpty) {
      if (newPassword.length < 4) {
        AppSnackbar.warning(
          'Password Terlalu Pendek',
          'Password baru minimal 4 karakter.',
        );
        return;
      }

      if (newPassword != confirmPassword) {
        AppSnackbar.error(
          'Konfirmasi Password Salah',
          'Password baru dan konfirmasi password tidak cocok.',
        );
        return;
      }
    }

    final success = await authService.updateProfile(
      username: username,
      email: email,
      phone: phone,
      newPassword: newPassword.isNotEmpty ? newPassword : null,
    );

    if (success) {
      newPasswordController.clear();
      confirmPasswordController.clear();
      AppSnackbar.success(
        'Profil Diperbarui',
        'Data profil Anda berhasil disimpan!',
      );
    } else {
      AppSnackbar.error(
        'Gagal Memperbarui',
        'Username atau Email tersebut telah digunakan oleh pengguna lain.',
      );
    }
  }
}
