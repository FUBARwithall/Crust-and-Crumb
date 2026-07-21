import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/bakery_item.dart';
import '../models/order_model.dart';

class OrderService extends GetxService {
  final GetStorage _storage = GetStorage();

  // Laravel Backend Server URL
  // Use http://127.0.0.1:8000/api for Web/Desktop or http://10.0.2.2:8000/api for Android Emulator
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<BakeryItem> products = <BakeryItem>[].obs;
  final RxBool isLoadingProducts = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOrders();
    fetchOrdersFromAPI();
    fetchProductsFromAPI();
  }

  void _loadOrders() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>('orders');
    if (stored != null) {
      orders.assignAll(
        stored.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
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
              items: itemsList,
              totalPrice: (o['total_price'] as num?)?.toDouble() ?? 0.0,
              orderTime: o['created_at'] != null ? DateTime.parse(o['created_at']) : DateTime.now(),
            );
          }).toList();

          for (final serverOrder in loaded) {
            if (!orders.any((o) => o.id == serverOrder.id)) {
              orders.insert(0, serverOrder);
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
      // Fetch strictly from Laravel Server API / Supabase Database
      final laravelRes = await http
          .get(Uri.parse('$baseUrl/products'))
          .timeout(const Duration(seconds: 10));

      if (laravelRes.statusCode == 200) {
        final data = jsonDecode(laravelRes.body);
        final List<dynamic>? list = data['data'];

        if (list != null && list.isNotEmpty) {
          final List<BakeryItem> loaded = list.map((item) {
            return BakeryItem(
              id: item['id'].toString(),
              name: item['name'].toString(),
              category: item['category'] == 'kue' ? BakeryCategory.kue : BakeryCategory.roti,
              price: (item['price'] as num).toDouble(),
              description: item['description']?.toString() ?? '',
              imageUrl: item['image_url']?.toString() ?? '',
              rating: (item['rating'] as num?)?.toDouble() ?? 4.8,
              prepTime: item['prep_time']?.toString() ?? '15 mnt',
              origin: item['origin']?.toString() ?? 'Artisanal',
              isSpecial: item['is_special'] == true || item['is_special'] == 1,
            );
          }).toList();

          products.assignAll(loaded);
          debugPrint('[OrderService] Successfully loaded ${loaded.length} products strictly from API.');
        }
      }
    } catch (e) {
      debugPrint('[OrderService] Product fetch API error: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> addOrder(OrderModel order) async {
    // Save locally
    orders.add(order);
    final jsonList = orders.map((o) => o.toJson()).toList();
    await _storage.write('orders', jsonList);

    // Send order to Laravel Backend Server API
    try {
      final payload = {
        'id': order.id,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'address_notes': order.addressNotes,
        'latitude': order.latitude,
        'longitude': order.longitude,
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
        debugPrint('[OrderService] Order ${order.id} sent successfully to Laravel Server API.');
      } else {
        debugPrint('[OrderService] Laravel Server API status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OrderService] Note: Order saved locally. Could not connect to Laravel server at $baseUrl');
    }
  }
}
