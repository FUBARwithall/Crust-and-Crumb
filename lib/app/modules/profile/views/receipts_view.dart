import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import 'widgets/receipt_card.dart';

class ReceiptsView extends StatelessWidget {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = Get.find<OrderService>();
    final authService = Get.find<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Riwayat & Struk Belanja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderService.refreshOrders(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => orderService.refreshOrders(),
        color: const Color(0xFF8B4513),
        child: Obx(() {
          final currentUser = authService.currentUser.value;

          // Filter orders so users ONLY see their own purchase receipts
          final userOrders = orderService.orders.where((order) {
            if (currentUser == null || currentUser.isGuest) return false;

            final bool nameMatch = currentUser.username.isNotEmpty &&
                order.customerName.trim().toLowerCase() == currentUser.username.trim().toLowerCase();
            final bool phoneMatch = currentUser.phone.isNotEmpty &&
                order.customerPhone.trim() == currentUser.phone.trim();

            return nameMatch || phoneMatch;
          }).toList();

          if (userOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Transaksi Pembelian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2C11),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lakukan pesanan dari katalog pastry untuk melihat dan mengunduh struk digital.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: userOrders.length,
          itemBuilder: (context, index) {
            final order = userOrders[index];
            return ReceiptCard(order: order);
          },
        );
      }),
    ),
    );
  }
}
