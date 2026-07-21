import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/order_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';
import 'widgets/receipt_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pengaturan Profil & Struk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final isGuest = controller.authService.isGuest;
          final user = controller.authService.currentUser.value;

          return Column(
            children: [
              // Avatar & User Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF8B4513),
                      child: Text(
                        (user?.username.isNotEmpty == true)
                            ? user!.username[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.username ?? 'Tamu / Guest',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Akun Pengguna Tamu' : (user?.email ?? ''),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Guest Info Banner
              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber[700]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[900]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Anda sedang menggunakan mode Tamu. Buat akun permanen untuk mengubah profil.',
                              style: TextStyle(color: Colors.amber[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Get.toNamed(Routes.REGISTER),
                          child: const Text('Daftar Akun Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form Container Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubah Informasi Akun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username Field
                    TextField(
                      controller: controller.usernameController,
                      enabled: !isGuest,
                      decoration: _buildInputDecoration(
                        label: 'Username *',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email Field
                    TextField(
                      controller: controller.emailController,
                      enabled: !isGuest,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        label: 'Alamat Email *',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Field
                    TextField(
                      controller: controller.phoneController,
                      enabled: !isGuest,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration(
                        label: 'Nomor Telepon / WhatsApp *',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Ubah Password (Opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // New Password Field
                    Obx(() => TextField(
                          controller: controller.newPasswordController,
                          enabled: !isGuest,
                          obscureText: controller.isObscureNewPassword.value,
                          decoration: _buildInputDecoration(
                            label: 'Password Baru (Kosongkan jika tidak diubah)',
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
                    const SizedBox(height: 14),

                    // Confirm New Password Field
                    Obx(() => TextField(
                          controller: controller.confirmPasswordController,
                          enabled: !isGuest,
                          obscureText: controller.isObscureConfirmPassword.value,
                          decoration: _buildInputDecoration(
                            label: 'Konfirmasi Password Baru',
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
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2691E),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isGuest ? null : () => controller.saveProfile(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Riwayat & Struk Belanja Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Riwayat & Struk Belanja',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        Icon(Icons.receipt_long, color: Color(0xFF8B4513)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Builder(builder: (context) {
                      final orderService = Get.find<OrderService>();
                      return Obx(() {
                        final orders = orderService.orders;
                        if (orders.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF9F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E0D8)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  'Belum ada transaksi pembelian.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lakukan pesanan di katalog untuk melihat struk digital.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: orders.map((order) => ReceiptCard(order: order)).toList(),
                        );
                      });
                    }),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
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
