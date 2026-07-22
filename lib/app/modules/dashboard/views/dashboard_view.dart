import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../catalog/controllers/catalog_controller.dart';
import '../../catalog/views/catalog_view.dart';
import '../../checkout/views/checkout_view.dart';
import '../../profile/views/profile_view.dart';
import '../../profile/views/receipts_view.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogController = Get.find<CatalogController>();

    final List<Widget> pages = [
      const CatalogView(),
      const CheckoutView(),
      const ReceiptsView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: Obx(() {
        final totalCartItems = catalogController.totalCartCount;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF8B4513),
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront),
                label: 'Katalog',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: totalCartItems > 0,
                  label: Text(
                    '$totalCartItems',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFD2691E),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: totalCartItems > 0,
                  label: Text(
                    '$totalCartItems',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFD2691E),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'Keranjang',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Struk',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      }),
    );
  }
}
