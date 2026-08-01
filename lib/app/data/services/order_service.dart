import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../helpers/database_helper.dart';
import '../models/bakery_item.dart';
import '../models/order_model.dart';
import '../utils/app_config.dart';

class OrderService extends GetxService {

  // Laravel Backend Server URL
  static const String baseUrl = AppConfig.baseUrl;

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<BakeryItem> products = <BakeryItem>[].obs;
  final RxBool isLoadingProducts = false.obs;

  final List<_PendingOrder> _pendingSync = [];

  @override
  void onInit() {
    super.onInit();
    refreshOrders();
  }

  Future<void> refreshOrders() async {
    await _loadOrders();
    await fetchOrdersFromAPI();
    _retryPendingOrders();
  }

  void _retryPendingOrders() {
    if (_pendingSync.isEmpty) return;
    debugPrint('[OrderService] Retrying ${_pendingSync.length} pending orders...');
    final retrying = List<_PendingOrder>.from(_pendingSync);
    _pendingSync.clear();
    for (final pending in retrying) {
      _syncOrderToServer(pending.order, pending.retries);
    }
  }

  Future<void> _loadOrders() async {
    // Load orders from SQLite Database (single source of truth)
    try {
      final sqliteOrders = await DatabaseHelper.instance.getOrders();
      if (sqliteOrders.isNotEmpty) {
        orders.assignAll(sqliteOrders);
        debugPrint('[OrderService] Loaded ${sqliteOrders.length} orders from SQLite.');
      }
    } catch (e) {
      debugPrint('[OrderService] SQLite load orders error: $e');
    }
  }

  Future<void> fetchOrdersFromAPI() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? list = data['data'];
        if (list != null && list.isNotEmpty) {
          final loaded = list.map((o) {
            final itemsList = (o['items'] as List<dynamic>?)?.map((i) {
              return OrderCartItem(
                item: BakeryItem(
                  id: i['product_id']?.toString() ?? 'p1',
                  name: i['product_name']?.toString() ?? 'Bakery Item',
                  category: BakeryCategory.roti,
                  price: (i['price'] as num?)?.toDouble() ?? 0.0,
                  description: '',
                  imageUrl: '',
                ),
                quantity: (i['quantity'] as num?)?.toInt() ?? 1,
              );
            }).toList() ?? [];

            return OrderModel(
              id: o['id']?.toString() ?? '',
              customerName: o['customer_name']?.toString() ?? '',
              customerPhone: o['customer_phone']?.toString() ?? '',
              addressNotes: o['address_notes']?.toString() ?? '',
              latitude: (o['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (o['longitude'] as num?)?.toDouble() ?? 0.0,
              shippingMethod: o['shipping_method']?.toString() ?? 'Kurir Express',
              paymentMethod: o['payment_method']?.toString() ?? 'COD',
              items: itemsList,
              totalPrice: (o['total_price'] as num?)?.toDouble() ?? 0.0,
              orderTime: o['created_at'] != null ? DateTime.parse(o['created_at']) : DateTime.now(),
            );
          }).toList();

          for (final serverOrder in loaded) {
            if (!orders.any((o) => o.id == serverOrder.id)) {
              orders.insert(0, serverOrder);
              DatabaseHelper.instance.saveOrder(serverOrder);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[OrderService] Could not fetch orders from API: $e');
    }
  }

  Future<void> fetchProductsFromAPI() async {
    isLoadingProducts.value = true;
    try {
      final laravelRes = await http
          .get(Uri.parse('$baseUrl/products'))
          .timeout(const Duration(seconds: 10));

      if (laravelRes.statusCode == 200) {
        final data = jsonDecode(laravelRes.body);
        final List<dynamic>? list = data['data'];

        if (list != null && list.isNotEmpty) {
          final List<BakeryItem> loaded = list.map((item) {
            final catStr = item['category']?.toString() ?? 'roti';
            return BakeryItem(
              id: item['id'].toString(),
              name: item['name'].toString(),
              category: catStr == 'kue' ? BakeryCategory.kue : BakeryCategory.roti,
              price: (item['price'] as num).toDouble(),
              description: item['description']?.toString() ?? '',
              imageUrl: item['image_url']?.toString() ?? item['image']?.toString() ?? '',
              rating: (item['rating'] as num?)?.toDouble() ?? 4.8,
              prepTime: item['prep_time']?.toString() ?? '15 mnt',
              origin: item['origin']?.toString() ?? 'Artisanal',
              isSpecial: item['is_special'] == true || item['is_special'] == 1,
            );
          }).toList();

          products.assignAll(loaded);
          await DatabaseHelper.instance.saveProducts(loaded);
          debugPrint('[OrderService] Successfully loaded ${loaded.length} products from API.');
          return;
        }
      }
    } catch (e) {
      debugPrint('[OrderService] Product API error: $e. Falling back to SQLite cache...');
    } finally {
      isLoadingProducts.value = false;
    }

    // Offline fallback: Load products from SQLite database
    try {
      final cachedProducts = await DatabaseHelper.instance.getProducts();
      if (cachedProducts.isNotEmpty) {
        products.assignAll(cachedProducts);
        debugPrint('[OrderService] Offline mode: Loaded ${cachedProducts.length} products from SQLite database.');
      }
    } catch (e) {
      debugPrint('[OrderService] SQLite fallback load error: $e');
    }
  }

  Future<void> addOrder(OrderModel order) async {
    // 1. Add to reactive list
    orders.add(order);

    // 2. Persist to SQLite database (single source of truth)
    await DatabaseHelper.instance.saveOrder(order);

    // 3. Send order to Laravel Backend Server API (with retry)
    await _syncOrderToServer(order, 0);
  }

  Future<void> _syncOrderToServer(OrderModel order, int retryCount) async {
    try {
      final payload = {
        'id': order.id,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'address_notes': order.addressNotes,
        'latitude': order.latitude,
        'longitude': order.longitude,
        'shipping_method': order.shippingMethod,
        'payment_method': order.paymentMethod,
        'total_price': order.totalPrice,
        'items': order.items.map((item) {
          return {
            'product_id': item.item.id,
            'product_name': item.item.name,
            'price': item.item.price,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[OrderService] Order ${order.id} synced to server (retry $retryCount).');
        return;
      }
    } catch (e) {
      debugPrint('[OrderService] Server sync failed for order ${order.id} (retry $retryCount): $e');
    }

    if (retryCount < 3) {
      _pendingSync.add(_PendingOrder(order, retryCount + 1));
      debugPrint('[OrderService] Order ${order.id} queued for retry (${retryCount + 1}/3).');
    } else {
      debugPrint('[OrderService] Order ${order.id} sync failed after 3 retries. Kept in SQLite.');
    }
  }
}

class _PendingOrder {
  final OrderModel order;
  final int retries;
  _PendingOrder(this.order, this.retries);
}
