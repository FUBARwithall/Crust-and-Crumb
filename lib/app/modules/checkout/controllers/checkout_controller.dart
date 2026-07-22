import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/utils/app_snackbar.dart';
import '../../../routes/app_pages.dart';
import '../../catalog/controllers/catalog_controller.dart';

class CheckoutController extends GetxController {
  final CatalogController catalogController = Get.find<CatalogController>();
  final OrderService orderService = Get.find<OrderService>();
  final AuthService authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final mapSearchController = TextEditingController();

  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;
  final RxBool isFetchingLocation = false.obs;
  final RxString locationStatus = 'GPS belum diambil'.obs;

  final RxList<Map<String, dynamic>> mapSearchResults = <Map<String, dynamic>>[].obs;
  final RxBool isSearchingMap = false.obs;
  final RxString mapSearchQuery = ''.obs;

  final RxString selectedShipping = 'express'.obs;
  final RxString selectedPayment = 'cod'.obs;

  @override
  void onInit() {
    super.onInit();
    final user = authService.currentUser.value;
    if (user != null && !user.isGuest) {
      nameController.text = user.username;
      phoneController.text = user.phone;
    }

    // Live debounced search as user types (350ms)
    debounce<String>(
      mapSearchQuery,
      (val) => searchMapLocation(val),
      time: const Duration(milliseconds: 350),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    mapSearchController.dispose();
    super.onClose();
  }

  Future<void> searchMapLocation(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 3) {
      mapSearchResults.clear();
      return;
    }

    isSearchingMap.value = true;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(cleanQuery)}&limit=5',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'CrustAndCrumbBakeryApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        mapSearchResults.assignAll(
          jsonList.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
    } catch (e) {
      debugPrint('[CheckoutController] Nominatim search error: $e');
    } finally {
      isSearchingMap.value = false;
    }
  }

  void selectMapSearchResult(Map<String, dynamic> result) {
    try {
      final double lat = double.parse(result['lat'].toString());
      final double lng = double.parse(result['lon'].toString());
      final String displayName = result['display_name'] ?? 'Lokasi Dipilih!';

      latitude.value = lat;
      longitude.value = lng;
      locationStatus.value = displayName;
      mapSearchResults.clear();
      mapSearchController.text = displayName;

      AppSnackbar.success(
        'Lokasi Ditemukan',
        'Pin peta berhasil dipindahkan ke lokasi pilihan Anda.',
      );
    } catch (e) {
      debugPrint('[CheckoutController] Select location parse error: $e');
    }
  }

  Future<void> fetchGPSLocation() async {
    isFetchingLocation.value = true;
    locationStatus.value = 'Mencari sinyal GPS...';

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationStatus.value = 'Layanan GPS mati. Mohon aktifkan GPS smartphone Anda.';
        AppSnackbar.warning(
          'GPS Tidak Aktif',
          'Silakan aktifkan GPS / Lokasi pada HP Anda.',
        );
        isFetchingLocation.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationStatus.value = 'Izin lokasi ditolak oleh pelanggan.';
          isFetchingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationStatus.value = 'Izin lokasi ditolak secara permanen. Mohon aktifkan dari Pengaturan HP.';
        isFetchingLocation.value = false;
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      latitude.value = position.latitude;
      longitude.value = position.longitude;
      locationStatus.value = 'Koordinat GPS Berhasil Ditemukan!';

      AppSnackbar.success(
        'GPS Ditemukan',
        'Titik koordinat rumah berhasil diperoleh!',
      );
    } catch (e) {
      locationStatus.value = 'Gagal mengambil GPS: $e';
      AppSnackbar.error(
        'Gagal Membaca GPS',
        'Gagal memperoleh lokasi. Anda dapat mencoba lagi.',
      );
    } finally {
      isFetchingLocation.value = false;
    }
  }

  Future<void> submitOrder() async {
    if (authService.isGuest) {
      AppSnackbar.warning(
        'Akun Terdaftar Diperlukan',
        'Pelanggan mode Tamu tidak dapat melakukan pemesanan. Silakan buat akun atau login terlebih dahulu.',
      );
      Get.toNamed(Routes.REGISTER);
      return;
    }

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error('Data Belum Lengkap', 'Mohon isi nama lengkap Anda.');
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      AppSnackbar.error('Data Belum Lengkap', 'Mohon isi nomor telepon / Whatsapp.');
      return;
    }

    if (latitude.value == 0.0 && longitude.value == 0.0) {
      AppSnackbar.warning(
        'GPS Diperlukan',
        'Mohon tekan tombol "Ambil Lokasi GPS Rumah Saya" sebelum memesan.',
      );
      return;
    }

    final List<OrderCartItem> cartItems = [];
    catalogController.cart.forEach((itemId, qty) {
      final item = orderService.products.firstWhereOrNull((p) => p.id == itemId);
      if (item != null) {
        cartItems.add(OrderCartItem(item: item, quantity: qty));
      }
    });

    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerName: nameController.text.trim(),
      customerPhone: phoneController.text.trim(),
      addressNotes: addressController.text.trim(),
      latitude: latitude.value,
      longitude: longitude.value,
      shippingMethod: _getShippingLabel(selectedShipping.value),
      paymentMethod: _getPaymentLabel(selectedPayment.value),
      items: cartItems,
      totalPrice: catalogController.totalCartPrice,
      orderTime: DateTime.now(),
    );

    await orderService.addOrder(newOrder);
    catalogController.clearCart();

    Get.defaultDialog(
      title: 'Pesanan Berhasil!',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
      middleText:
          'Terima kasih ${newOrder.customerName}! Pesanan Anda telah tersimpan di server. Admin akan memproses pengiriman ke lokasi GPS Anda.',
      textConfirm: 'Kembali ke Katalog',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF8B4513),
      onConfirm: () {
        Get.back();
        Get.back();
      },
    );
  }

  String _getShippingLabel(String code) {
    switch (code) {
      case 'sameday':
        return 'Ojek Online Same Day';
      case 'pickup':
        return 'Ambil di Toko (Self Pick-up)';
      case 'express':
      default:
        return 'Kurir Crust & Crumb Express';
    }
  }

  String _getPaymentLabel(String code) {
    switch (code) {
      case 'qris':
        return 'Transfer Bank & QRIS';
      case 'ewallet':
        return 'E-Wallet (GoPay/OVO/DANA)';
      case 'cod':
      default:
        return 'Bayar di Tempat (COD)';
    }
  }
}
