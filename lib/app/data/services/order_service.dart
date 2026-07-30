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

  @override
  void onInit() {
    super.onInit();
    _loadOrders();
    fetchOrdersFromAPI();
    fetchProductsFromAPI();
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
      // 1. Try to fetch from Laravel REST API Server
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
          // Save to SQLite for offline access (mobile/desktop)
          await DatabaseHelper.instance.saveProducts(loaded);
          debugPrint('[OrderService] Successfully loaded ${loaded.length} products from API.');
          return;
        }
      }
    } catch (e) {
      debugPrint('[OrderService] Product API error: $e. Falling back to cache/default products...');
    } finally {
      isLoadingProducts.value = false;
    }

    // 2. Offline Fallback: Load products from SQLite database
    try {
      final cachedProducts = await DatabaseHelper.instance.getProducts();
      if (cachedProducts.isNotEmpty) {
        products.assignAll(cachedProducts);
        debugPrint('[OrderService] Offline mode: Loaded ${cachedProducts.length} products from SQLite database.');
        return;
      }
    } catch (e) {
      debugPrint('[OrderService] SQLite fallback load error: $e');
    }

    // 3. Web / First-load Fallback: Default products if API fails & SQLite is unavailable
    if (products.isEmpty) {
      products.assignAll(_defaultProducts);
      debugPrint('[OrderService] Fallback: Loaded ${_defaultProducts.length} default products.');
    }
  }

  static final List<BakeryItem> _defaultProducts = [
    BakeryItem(
      id: '52855',
      name: 'Banana Pancakes',
      category: BakeryCategory.roti,
      price: 25000,
      description: 'Pastry fresh buatan master baker dengan bahan pilihan unggulan.',
      imageUrl: 'https://www.themealdb.com/images/media/meals/sywswr1511383814.jpg',
      rating: 4.8,
      prepTime: '15 mnt',
      origin: 'Artisanal',
      isSpecial: true,
    ),
    BakeryItem(
      id: '52891',
      name: 'Blackberry Apple Crumble',
      category: BakeryCategory.kue,
      price: 32000,
      description: 'Pastry fresh buatan master baker dengan bahan pilihan unggulan.',
      imageUrl: 'https://www.themealdb.com/images/media/meals/xvsurr1511719182.jpg',
      rating: 4.9,
      prepTime: '20 mnt',
      origin: 'Artisanal',
      isSpecial: true,
    ),
    BakeryItem(
      id: '52892',
      name: 'Carrot Cake',
      category: BakeryCategory.kue,
      price: 28000,
      description: 'Pastry fresh buatan master baker dengan bahan pilihan unggulan.',
      imageUrl: 'https://www.themealdb.com/images/media/meals/vrxpuq1511192946.jpg',
      rating: 4.7,
      prepTime: '25 mnt',
      origin: 'Artisanal',
      isSpecial: false,
    ),
    BakeryItem(
      id: '52893',
      name: 'Chocolate Souffle',
      category: BakeryCategory.kue,
      price: 35000,
      description: 'Pastry fresh buatan master baker dengan bahan pilihan unggulan.',
      imageUrl: 'https://www.themealdb.com/images/media/meals/twxvxv1511793182.jpg',
      rating: 4.9,
      prepTime: '30 mnt',
      origin: 'Artisanal',
      isSpecial: true,
    ),
  ];

  Future<void> addOrder(OrderModel order) async {
    // 1. Add to reactive list
    orders.add(order);

    // 2. Persist to SQLite database (single source of truth)
    await DatabaseHelper.instance.saveOrder(order);

    // 3. Send order to Laravel Backend Server API
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
        debugPrint('[OrderService] Order ${order.id} sent successfully to Laravel Server API.');
      } else {
        debugPrint('[OrderService] Laravel Server API status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OrderService] Note: Order saved to SQLite. Could not connect to Laravel server at $baseUrl');
    }
  }
}
