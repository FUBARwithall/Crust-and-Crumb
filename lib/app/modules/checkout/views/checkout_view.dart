import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
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
            _buildStepHeader('Ringkasan Pesanan Roti & Kue'),
            const SizedBox(height: 12),
            _buildCartSummaryCard(),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E0D8), height: 24, thickness: 1),
            const SizedBox(height: 16),

            // STEP 2: Customer Contact Info
            _buildStepHeader('Informasi Pelanggan & Alamat'),
            const SizedBox(height: 12),
            _buildCustomerFormCard(),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E0D8), height: 24, thickness: 1),
            const SizedBox(height: 16),

            // STEP 3: GPS Coordinates Tagging
            _buildStepHeader('Koordinat GPS Smartphone'),
            const SizedBox(height: 12),
            _buildGpsCard(context),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E0D8), height: 24, thickness: 1),
            const SizedBox(height: 16),

            // STEP 4: Shipping Option
            _buildStepHeader('Opsi Pengiriman'),
            const SizedBox(height: 12),
            _buildShippingOptionsCard(),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E0D8), height: 24, thickness: 1),
            const SizedBox(height: 16),

            // STEP 5: Payment Option
            _buildStepHeader('Metode Pembayaran'),
            const SizedBox(height: 12),
            _buildPaymentOptionsCard(),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E0D8), height: 24, thickness: 1),
            const SizedBox(height: 24),

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

  Widget _buildStepHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B4513),
      ),
    );
  }

  Widget _buildCartSummaryCard() {
    final catCtrl = controller.catalogController;
    final orderService = controller.orderService;

    return Obx(() {
      if (catCtrl.cart.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Keranjang Anda Kosong',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return Column(
        children: [
          ...catCtrl.cart.entries.map((entry) {
            final item = orderService.products.firstWhereOrNull((p) => p.id == entry.key);
            if (item == null) return const SizedBox.shrink();
            final qty = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${_formatPrice(item.price)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Quantity Stepper Widget (- 1 +)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF9F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E0D8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => catCtrl.removeFromCart(item),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.remove, size: 16, color: Color(0xFF8B4513)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => catCtrl.addToCart(item),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.add, size: 16, color: Color(0xFF8B4513)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Rp ${_formatPrice(item.price * qty)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
      );
    });
  }

  Widget _buildCustomerFormCard() {
    return Column(
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
    );
  }

  Widget _buildGpsCard(BuildContext context) {
    return Obx(() {
      final lat = controller.latitude.value != 0.0 ? controller.latitude.value : -6.2088;
      final lng = controller.longitude.value != 0.0 ? controller.longitude.value : 106.8456;
      final hasLocation = controller.latitude.value != 0.0;
      final mapCenter = LatLng(lat, lng);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Search Input Bar (Real-time Google-style suggestions)
          TextField(
            controller: controller.mapSearchController,
            onChanged: (val) => controller.mapSearchQuery.value = val,
            onSubmitted: (val) => controller.searchMapLocation(val),
            textInputAction: TextInputAction.search,
            decoration: _buildInputDecoration(
              label: 'Cari Nama Tempat / Jalan (e.g. Monas, Malioboro)...',
              icon: Icons.search,
            ).copyWith(
              suffixIcon: Obx(() {
                if (controller.isSearchingMap.value) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4513)),
                    ),
                  );
                }
                if (controller.mapSearchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      controller.mapSearchController.clear();
                      controller.mapSearchQuery.value = '';
                      controller.mapSearchResults.clear();
                    },
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF8B4513)),
                  onPressed: () => controller.searchMapLocation(controller.mapSearchController.text),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Search Suggestions Dropdown Overlay
          Obx(() {
            final results = controller.mapSearchResults;
            if (results.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E0D8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: results.map((result) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, color: Color(0xFFD2691E)),
                    title: Text(
                      result['display_name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onTap: () => controller.selectMapSearchResult(result),
                  );
                }).toList(),
              ),
            );
          }),

          // Visual Map Container (FlutterMap)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E0D8), width: 1.5),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    key: ValueKey('map_${lat}_$lng'),
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: hasLocation ? 16.0 : 12.0,
                      onTap: (tapPosition, point) {
                        controller.latitude.value = point.latitude;
                        controller.longitude.value = point.longitude;
                        controller.locationStatus.value = 'Lokasi Dipilih dari Peta!';
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.junior_mobile_programmer',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: mapCenter,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFD2691E),
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // GPS Status Badge (Top Right Corner Overlay)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (hasLocation ? Colors.green[50] : Colors.amber[50])!.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasLocation ? Colors.green : Colors.amber[800]!,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location,
                            color: hasLocation ? Colors.green[800] : Colors.amber[900],
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              controller.locationStatus.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: hasLocation ? Colors.green[900] : Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E0D8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app, size: 16, color: Color(0xFF8B4513)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasLocation
                                  ? 'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Ketuk peta untuk geser pin)'
                                  : 'Ketuk lokasi di peta atau gunakan deteksi GPS otomatis',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2C11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Auto-detect GPS Button
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
                    : 'Deteksi Otomatis GPS HP',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: controller.isFetchingLocation.value
                  ? null
                  : () => controller.fetchGPSLocation(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildShippingOptionsCard() {
    return Obx(() => Column(
          children: [
            _buildOptionTile(
              value: 'express',
              groupValue: controller.selectedShipping.value,
              title: 'Kurir Crust & Crumb Express',
              subtitle: 'Pengiriman cepat hangat 30-45 mnt (Gratis)',
              icon: Icons.two_wheeler,
              onTap: () => controller.selectedShipping.value = 'express',
            ),
            const Divider(height: 12),
            _buildOptionTile(
              value: 'sameday',
              groupValue: controller.selectedShipping.value,
              title: 'Ojek Online Same Day',
              subtitle: 'GoSend / GrabExpress (Rp 15.000)',
              icon: Icons.local_shipping_outlined,
              onTap: () => controller.selectedShipping.value = 'sameday',
            ),
            const Divider(height: 12),
            _buildOptionTile(
              value: 'pickup',
              groupValue: controller.selectedShipping.value,
              title: 'Ambil Sendiri di Outlet (Self Pick-up)',
              subtitle: 'Ambil di toko cabang terdekat',
              icon: Icons.storefront_outlined,
              onTap: () => controller.selectedShipping.value = 'pickup',
            ),
          ],
        ));
  }

  Widget _buildPaymentOptionsCard() {
    return Obx(() => Column(
          children: [
            _buildOptionTile(
              value: 'cod',
              groupValue: controller.selectedPayment.value,
              title: 'Bayar di Tempat (COD)',
              subtitle: 'Bayar tunai saat kurir tiba di rumah',
              icon: Icons.payments_outlined,
              onTap: () => controller.selectedPayment.value = 'cod',
            ),
            const Divider(height: 12),
            _buildOptionTile(
              value: 'qris',
              groupValue: controller.selectedPayment.value,
              title: 'Transfer Bank & QRIS Instant',
              subtitle: 'BCA, Mandiri, BRI & QRIS',
              icon: Icons.qr_code_scanner,
              onTap: () => controller.selectedPayment.value = 'qris',
            ),
            const Divider(height: 12),
            _buildOptionTile(
              value: 'ewallet',
              groupValue: controller.selectedPayment.value,
              title: 'E-Wallet',
              subtitle: 'GoPay, OVO, DANA, ShopeePay',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => controller.selectedPayment.value = 'ewallet',
            ),
          ],
        ));
  }

  Widget _buildOptionTile({
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B4513).withValues(alpha: 0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF8B4513) : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF8B4513),
              onChanged: (_) => onTap(),
            ),
          ],
        ),
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
