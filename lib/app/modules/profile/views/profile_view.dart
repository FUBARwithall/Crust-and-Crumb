import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/utils/app_snackbar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF8B4513)),
            onPressed: () {
              AppSnackbar.info('Layanan Pelanggan', 'Fitur Chat CS akan segera hadir!');
            },
          ),
        ],
      ),
      body: Obx(() {
        final isGuest = controller.authService.isGuest;
        final user = controller.authService.currentUser.value;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF8B4513),
                      child: Text(
                        (user?.username.isNotEmpty == true)
                            ? user!.username[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'Tamu / Guest',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isGuest ? 'Mode Pengguna Tamu' : (user?.email ?? ''),
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (isGuest)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Get.offAllNamed(Routes.LOGIN),
                        child: const Text('Daftar/Login', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Section 1: My Account
              _buildSectionHeader('My Account'),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      subtitle: isGuest ? 'Daftar untuk ubah profil' : (user?.username ?? ''),
                      onTap: () {
                        if (isGuest) {
                          _showGuestAlert();
                        } else {
                          _showEditProfileBottomSheet(context);
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      subtitle: 'Alamat utama & koordinat GPS',
                      onTap: () => _showAddressBottomSheet(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Bank Accounts / Cards',
                      subtitle: 'Metode pembayaran tersimpan',
                      onTap: () {
                        AppSnackbar.info('Bank & Cards', 'Pembayaran QRIS & COD tersedia saat checkout.');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 2: Settings
              _buildSectionHeader('Settings'),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notification Settings',
                      subtitle: 'Promo & pembaruan transaksi',
                      onTap: () => _showNotificationDialog(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.security_outlined,
                      title: 'Security & Password',
                      subtitle: 'Ubah password keamanan akun',
                      onTap: () {
                        if (isGuest) {
                          _showGuestAlert();
                        } else {
                          _showChangePasswordBottomSheet(context);
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Language / Język',
                      subtitle: controller.selectedLanguage.value,
                      onTap: () => _showLanguageBottomSheet(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 3: Support
              _buildSectionHeader('Support'),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help Centre',
                      onTap: () => _showInfoDialog(
                        context,
                        'Pusat Bantuan',
                        'Butuh bantuan pesanan? Hubungi CS Crust & Crumb via WhatsApp di +62 812-3456-7890.',
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.policy_outlined,
                      title: 'Policies',
                      onTap: () => _showInfoDialog(
                        context,
                        'Kebijakan & Syarat',
                        'Produk dipanggang segar setiap hari. Garansi ganti rugi 100% jika produk yang diterima rusak.',
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: 'About Crust & Crumb',
                      subtitle: 'Versi 1.0.0 (BMP Receipts & OpenStreetMap)',
                      onTap: () => _showInfoDialog(
                        context,
                        'Tentang Aplikasi',
                        'Crust & Crumb Bakery Mobile App v1.0.0.\nDilengkapi fitur thermal receipt BMP generator dan OpenStreetMap GPS tagging.',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Red Logout Button at Bottom (Matching Shopee reference image)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE4D2D), // Shopee red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888888),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF555555), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF222222),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Color(0xFFBBBBBB),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      indent: 52,
      endIndent: 0,
      color: Color(0xFFEEEEEE),
    );
  }

  void _showGuestAlert() {
    AppSnackbar.warning(
      'Akses Terbatas',
      'Silakan login atau buat akun permanen untuk mengubah pengaturan ini.',
    );
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.person, color: Color(0xFF8B4513)),
                  SizedBox(width: 10),
                  Text(
                    'Edit Profil Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2C11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.usernameController,
                decoration: _buildInputDecoration(
                  label: 'Username *',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  label: 'Email *',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                  label: 'Nomor Telepon *',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Simpan Profil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () => controller.saveProfile(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context) {
    controller.newPasswordController.clear();
    controller.confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.security, color: Color(0xFF8B4513)),
                  SizedBox(width: 10),
                  Text(
                    'Keamanan & Ubah Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2C11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan password baru Anda di bawah ini.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Obx(() => TextField(
                    controller: controller.newPasswordController,
                    obscureText: controller.isObscureNewPassword.value,
                    decoration: _buildInputDecoration(
                      label: 'Password Baru *',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isObscureNewPassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => controller.isObscureNewPassword.toggle(),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              Obx(() => TextField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.isObscureConfirmPassword.value,
                    decoration: _buildInputDecoration(
                      label: 'Konfirmasi Password Baru *',
                      icon: Icons.lock_reset,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isObscureConfirmPassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => controller.isObscureConfirmPassword.toggle(),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Simpan Password Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () => controller.updatePasswordOnly(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final languages = ['Bahasa Indonesia', 'English', 'Język Polski'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Bahasa / Select Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ...languages.map((lang) {
                return Obx(() => RadioListTile<String>(
                      activeColor: const Color(0xFF8B4513),
                      title: Text(lang),
                      value: lang,
                      groupValue: controller.selectedLanguage.value,
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedLanguage.value = val;
                          Get.back();
                          AppSnackbar.success('Bahasa', 'Bahasa diubah ke $val');
                        }
                      },
                    ));
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAddressBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on, color: Color(0xFFD2691E)),
                  SizedBox(width: 8),
                  Text(
                    'Alamat & GPS Pengiriman',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Alamat pengiriman dan pin koordinat GPS visual dapat Anda sesuaikan langsung secara interaktif saat melakukan Checkout di tab Keranjang.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'Pengaturan Notifikasi',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
      middleText: 'Notifikasi promo harian dan status pesanan aktif.',
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF8B4513),
      onConfirm: () => Get.back(),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
      middleText: message,
      textConfirm: 'Tutup',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF8B4513),
      onConfirm: () => Get.back(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'Konfirmasi Logout',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEE4D2D)),
      middleText: 'Apakah Anda yakin ingin keluar dari akun Anda?',
      textCancel: 'Batal',
      textConfirm: 'Keluar',
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF555555),
      buttonColor: const Color(0xFFEE4D2D),
      onConfirm: () {
        Get.back();
        controller.authService.logout();
        Get.offAllNamed(Routes.LOGIN);
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF8B4513)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFBF9F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8B4513), width: 1.5),
      ),
    );
  }
}
