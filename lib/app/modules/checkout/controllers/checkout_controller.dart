import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/utils/app_snackbar.dart';
import '../../catalog/controllers/catalog_controller.dart';

class CheckoutController extends GetxController {
  final CatalogController catalogController = Get.find<CatalogController>();
  final OrderService orderService = Get.find<OrderService>();
  final AuthService authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;
  final RxBool isFetchingLocation = false.obs;
  final RxString locationStatus = 'GPS belum diambil'.obs;

  @override
  void onInit() {
    super.onInit();
    final user = authService.currentUser.value;
    if (user != null && !user.isGuest) {
      nameController.text = user.username;
      phoneController.text = user.phone;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
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
      final item = orderService.sampleProducts.firstWhere((p) => p.id == itemId);
      cartItems.add(OrderCartItem(item: item, quantity: qty));
    });

    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerName: nameController.text.trim(),
      customerPhone: phoneController.text.trim(),
      addressNotes: addressController.text.trim(),
      latitude: latitude.value,
      longitude: longitude.value,
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
}
