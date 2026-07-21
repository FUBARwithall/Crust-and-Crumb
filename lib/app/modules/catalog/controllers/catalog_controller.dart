import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/bakery_item.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../../routes/app_pages.dart';

class CatalogController extends GetxController {
  final OrderService orderService = Get.find<OrderService>();

  final RxString selectedCategory = 'all'.obs; // 'all', 'roti', 'kue'
  final RxString searchQuery = ''.obs;
  final RxString debouncedSearch = ''.obs;

  // Cart mapping: Item ID -> Quantity
  final RxMap<String, int> cart = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Debounce search query by 250ms for smooth 60fps typing & rendering
    debounce<String>(
      searchQuery,
      (val) => debouncedSearch.value = val,
      time: const Duration(milliseconds: 250),
    );
  }

  List<BakeryItem> get allProducts => orderService.products;

  List<BakeryItem> get filteredItems {
    final search = debouncedSearch.value.trim().toLowerCase();
    final category = selectedCategory.value;

    return allProducts.where((item) {
      final matchesCategory = category == 'all' ||
          (category == 'roti' && item.category == BakeryCategory.roti) ||
          (category == 'kue' && item.category == BakeryCategory.kue);

      if (!matchesCategory) return false;
      if (search.isEmpty) return true;

      return item.name.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search);
    }).toList();
  }

  Future<void> refreshProducts() async {
    await orderService.fetchProductsFromAPI();
  }

  void addToCart(BakeryItem item) {
    final authService = Get.find<AuthService>();
    if (authService.isGuest) {
      Get.defaultDialog(
        title: 'Perlu Akun Terdaftar',
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
        middleText:
            'Anda sedang menggunakan mode Tamu. Silakan Login atau Daftar Akun terlebih dahulu untuk menambahkan produk ke keranjang.',
        textConfirm: 'Daftar Akun Baru',
        textCancel: 'Login',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF8B4513),
        cancelTextColor: const Color(0xFF8B4513),
        onConfirm: () {
          Get.back();
          Get.toNamed(Routes.REGISTER);
        },
        onCancel: () {
          Get.back();
          Get.toNamed(Routes.LOGIN);
        },
      );
      return;
    }
    cart[item.id] = (cart[item.id] ?? 0) + 1;
  }

  void removeFromCart(BakeryItem item) {
    if (cart.containsKey(item.id)) {
      if (cart[item.id]! > 1) {
        cart[item.id] = cart[item.id]! - 1;
      } else {
        cart.remove(item.id);
      }
    }
  }

  int getQuantity(BakeryItem item) {
    return cart[item.id] ?? 0;
  }

  int get totalCartCount {
    return cart.values.fold(0, (sum, qty) => sum + qty);
  }

  double get totalCartPrice {
    double total = 0;
    cart.forEach((itemId, qty) {
      final item = allProducts.firstWhereOrNull((p) => p.id == itemId);
      if (item != null) {
        total += item.price * qty;
      }
    });
    return total;
  }

  void clearCart() {
    cart.clear();
  }
}
