import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  final RxList<Map<String, dynamic>> mapSearchResults =
      <Map<String, dynamic>>[].obs;
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
  void onReady() {
    super.onReady();
    // On web: skip auto-fetch — browser requires a visible user interaction
    // before it will show the geolocation permission popup reliably.
    // The user taps "Deteksi Otomatis GPS HP" button to trigger it.
    // On native: auto-detect on load is fine.
    if (!kIsWeb) {
      fetchGPSLocation();
    }
  }

  @override
  void onClose() {
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
      final response = await http
          .get(uri, headers: {'User-Agent': 'CrustAndCrumbBakeryApp/1.0'})
          .timeout(const Duration(seconds: 5));

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
    locationStatus.value = 'Mendapatkan sinyal GPS perangkat...';
    debugPrint('[GPS] ▶ fetchGPSLocation() started. kIsWeb=$kIsWeb');

    try {
      debugPrint('[GPS] 📱 Checking location service...');

      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint('[GPS] isLocationServiceEnabled: $serviceEnabled');
        if (!serviceEnabled) {
          _setFallbackLocation('Layanan GPS HP Mati');
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint('[GPS] checkPermission: $permission');
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          debugPrint('[GPS] requestPermission: $permission');
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _setFallbackLocation('Izin GPS Ditolak');
          return;
        }
      }

      final gpsTimeout = kIsWeb ? 5 : 20;
      debugPrint('[GPS] 📡 Calling getCurrentPosition (medium accuracy, ${gpsTimeout}s timeout)...');
      Position? position;
      try {
        final getFuture = Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: gpsTimeout),
          ),
        );
        position = await getFuture.timeout(
          Duration(seconds: gpsTimeout),
          onTimeout: () {
            debugPrint('[GPS] ⏰ Dart timeout fired — browser may be waiting for permission or signal.');
            throw TimeoutException('GPS timed out after ${gpsTimeout}s');
          },
        );
        debugPrint('[GPS] ✅ Position: lat=${position.latitude}, lng=${position.longitude}');
      } on TimeoutException catch (posErr) {
        debugPrint('[GPS] ⏰ Timeout: $posErr');
        if (kIsWeb) {
          debugPrint('[GPS] 🌐 Browser GPS timed out — trying IP geolocation...');
          await _fetchIPLocation();
          return; // _fetchIPLocation handles status/snackbar itself
        }
        // getLastKnownPosition is NOT supported on web — only call on native.
        if (!kIsWeb) {
          debugPrint('[GPS] 🔄 Trying getLastKnownPosition...');
          position = await Geolocator.getLastKnownPosition();
          debugPrint('[GPS] lastKnown: $position');
        }
      } catch (posErr) {
        debugPrint('[GPS] ❌ getCurrentPosition error: $posErr');
        if (kIsWeb) {
          debugPrint('[GPS] 🌐 Browser GPS error — trying IP geolocation...');
          await _fetchIPLocation();
          return; // _fetchIPLocation handles status/snackbar itself
        }
        // getLastKnownPosition is NOT supported on web — only call on native.
        if (!kIsWeb) {
          debugPrint('[GPS] 🔄 Trying getLastKnownPosition...');
          position = await Geolocator.getLastKnownPosition();
          debugPrint('[GPS] lastKnown: $position');
        }
      }

      if (position != null) {
        debugPrint('[GPS] 📌 Setting: lat=${position.latitude}, lng=${position.longitude}');
        latitude.value = position.latitude;
        longitude.value = position.longitude;
        locationStatus.value =
            'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        AppSnackbar.success(
          'Lokasi Perangkat Ditemukan',
          'Koordinat (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}) berhasil dideteksi!',
        );
        debugPrint('[GPS] 🗺 Starting reverse geocode...');
        _reverseGeocode(position.latitude, position.longitude);
      } else {
        debugPrint('[GPS] ⚠ Position null.');
        if (kIsWeb) {
          // Browser GPS unavailable (common in flutter run -d chrome dev mode).
          // Fall back to IP-based geolocation for approximate location.
          debugPrint('[GPS] 🌐 Trying IP geolocation fallback...');
          await _fetchIPLocation();
        } else {
          _setFallbackLocation('Sinyal GPS Lemah');
        }
      }
    } catch (e, stack) {
      debugPrint('[GPS] 💥 Unhandled error: $e');
      debugPrint('[GPS] Stack: $stack');
      _setFallbackLocation('Gagal membaca GPS');
    } finally {
      debugPrint('[GPS] 🏁 finished. isFetchingLocation → false');
      isFetchingLocation.value = false;
    }
  }


  /// Fallback for web: uses ipapi.co to get approximate location from IP address.
  /// No browser permission required. Accuracy: city-level (~1-5 km).
  Future<void> _fetchIPLocation() async {
    try {
      debugPrint('[GPS] 🌐 Calling ipapi.co...');
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await http
          .get(uri, headers: {'User-Agent': 'CrustAndCrumbBakeryApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final city = data['city'] as String? ?? '';
        final region = data['region'] as String? ?? '';
        if (lat != null && lng != null) {
          debugPrint('[GPS] 🌐 IP location: lat=$lat, lng=$lng, city=$city');
          latitude.value = lat;
          longitude.value = lng;
          locationStatus.value = 'IP: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
          final areaLabel = [city, region].where((s) => s.isNotEmpty).join(', ');
          AppSnackbar.success(
            'Lokasi Perkiraan (via IP)',
            'Area: $areaLabel. GPS timeout — jika menggunakan Vivaldi/Chrome, nonaktifkan Shield/AdBlocker untuk situs ini agar lokasi lebih akurat.',
          );
          return;
        }
      }
      debugPrint('[GPS] 🌐 IP geolocation failed (status ${response.statusCode}).');
    } catch (e) {
      debugPrint('[GPS] 🌐 IP geolocation error: $e');
    }
    _setFallbackLocation('Sinyal GPS Lemah');
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'CrustAndCrumbBakeryApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] ?? '';
        if (displayName.isNotEmpty) {
          locationStatus.value = displayName;
          mapSearchController.text = displayName;
        }
      }
    } catch (e) {
      debugPrint('[CheckoutController] Reverse geocode error: $e');
    }
  }

  void _setFallbackLocation(String reason) {
    latitude.value = -6.1754;
    longitude.value = 106.8272;
    locationStatus.value = 'Titik Lokasi Default (-6.1754, 106.8272)';
    isFetchingLocation.value = false;
    AppSnackbar.info(
      'Lokasi Terpasang ($reason)',
      'Titik koordinat dipasang ke lokasi default. Anda dapat mengetuk peta untuk menggeser lokasi.',
    );
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

    if (catalogController.cart.isEmpty) {
      AppSnackbar.warning(
        'Keranjang Kosong',
        'Silakan tambahkan produk ke keranjang terlebih dahulu sebelum melakukan pemesanan.',
      );
      return;
    }

    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error('Data Belum Lengkap', 'Mohon isi nama lengkap Anda.');
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      AppSnackbar.error(
        'Data Belum Lengkap',
        'Mohon isi nomor telepon / Whatsapp.',
      );
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
      final item = orderService.products.firstWhereOrNull(
        (p) => p.id == itemId,
      );
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
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B4513),
      ),
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
