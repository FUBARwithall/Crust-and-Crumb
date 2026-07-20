import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Checkout & Tagging Lokasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: Order Summary
            _buildStepHeader('1', 'Ringkasan Pesanan Roti & Kue'),
            const SizedBox(height: 10),
            _buildCartSummaryCard(),
            const SizedBox(height: 22),

            // STEP 2: Customer Contact Info
            _buildStepHeader('2', 'Informasi Pelanggan & Alamat'),
            const SizedBox(height: 10),
            _buildCustomerFormCard(),
            const SizedBox(height: 22),

            // STEP 3: GPS Coordinates Tagging
            _buildStepHeader('3', 'Koordinat GPS Smartphone'),
            const SizedBox(height: 10),
            _buildGpsCard(),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2691E),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: const Color(0xFFD2691E).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () => controller.submitOrder(),
                child: const Text(
                  'Kirim Pesanan Sekarang',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String stepNum, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Langkah $stepNum',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartSummaryCard() {
    final catCtrl = controller.catalogController;
    final orderService = controller.orderService;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ...catCtrl.cart.entries.map((entry) {
            final item = orderService.sampleProducts.firstWhere((p) => p.id == entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 45,
                        height: 45,
                        color: Colors.amber[100],
                        child: const Icon(Icons.bakery_dining, color: Color(0xFF8B4513)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Jumlah: ${entry.value}x',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice(item.price * entry.value)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                'Rp ${_formatPrice(catCtrl.totalCartPrice)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller.nameController,
            decoration: _buildInputDecoration(
              label: 'Nama Lengkap Pelanggan *',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration(
              label: 'Nomor HP / WhatsApp *',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.addressController,
            maxLines: 2,
            decoration: _buildInputDecoration(
              label: 'Catatan Alamat / Patokan Rumah',
              icon: Icons.home_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() {
            final hasLocation = controller.latitude.value != 0.0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasLocation ? Colors.green[50] : Colors.amber[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasLocation ? Colors.green : Colors.amber[800]!,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: hasLocation ? Colors.green[800] : Colors.amber[900],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.locationStatus.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: hasLocation ? Colors.green[900] : Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasLocation) ...[
                    const Divider(height: 16),
                    Text(
                      'Latitude  : ${controller.latitude.value}',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Longitude : ${controller.longitude.value}',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          Obx(() => SizedBox(
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
                  icon: controller.isFetchingLocation.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.gps_fixed),
                  label: Text(
                    controller.isFetchingLocation.value
                        ? 'Mengambil Lokasi...'
                        : 'Ambil Lokasi GPS Rumah Saya',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: controller.isFetchingLocation.value
                      ? null
                      : () => controller.fetchGPSLocation(),
                ),
              )),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF8B4513)),
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
