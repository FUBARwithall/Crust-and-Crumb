import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/bakery_item.dart';
import '../models/order_model.dart';
import '../utils/app_snackbar.dart';

class OrderService extends GetxService {
  final GetStorage _storage = GetStorage();
  final RxList<OrderModel> orders = <OrderModel>[].obs;

  final RxList<BakeryItem> products = <BakeryItem>[].obs;
  final RxBool isLoadingProducts = false.obs;

  // Fallback Local Bakery Products
  final List<BakeryItem> sampleProducts = [
    BakeryItem(
      id: 'r1',
      name: 'Roti Tawar Gandum Artisanal',
      category: BakeryCategory.roti,
      price: 24000,
      description: 'Dibuat dengan ragi organik pilihan dan gandum utuh bernutrisi tinggi. Tekstur empuk bercita rasa gurih alami.',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
      rating: 4.9,
      prepTime: '10 mnt',
      origin: 'Resep Klasik',
      isSpecial: true,
    ),
    BakeryItem(
      id: 'r2',
      name: 'Roti Sobek Cokelat Keju Melted',
      category: BakeryCategory.roti,
      price: 32000,
      description: 'Isian cokelat belgian premium dan keju chedar melted berlapis emas. Tekstur sobek lembut melumer di mulut.',
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=500',
      rating: 4.8,
      prepTime: '15 mnt',
      origin: 'Favorit Spesial',
    ),
    BakeryItem(
      id: 'r3',
      name: 'Croissant French Butter Flaky',
      category: BakeryCategory.roti,
      price: 28000,
      description: 'Lapis garing berkulit renyah khas Prancis menggunakan mentega lezat import. Sangat pas dinikmati dengan kopi hangat.',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500',
      rating: 4.9,
      prepTime: '12 mnt',
      origin: 'Prancis',
      isSpecial: true,
    ),
    BakeryItem(
      id: 'k1',
      name: 'Black Forest Royale Slice',
      category: BakeryCategory.kue,
      price: 45000,
      description: 'Kue cokelat spons kaya rasa berlapis krim vanilla lembut dan ceri segar perasan kayu manis.',
      imageUrl: 'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=500',
      rating: 4.9,
      prepTime: '20 mnt',
      origin: 'Jerman',
      isSpecial: true,
    ),
    BakeryItem(
      id: 'k2',
      name: 'Red Velvet Velvetine Slice',
      category: BakeryCategory.kue,
      price: 42000,
      description: 'Lapisan red velvet lembut dengan cream cheese asam manis seimbang yang menggugah selera.',
      imageUrl: 'https://images.unsplash.com/photo-1586788680434-30d324b2d46f?w=500',
      rating: 4.7,
      prepTime: '18 mnt',
      origin: 'Amerika',
    ),
    BakeryItem(
      id: 'k3',
      name: 'Japanese Souffle Cheesecake',
      category: BakeryCategory.kue,
      price: 48000,
      description: 'Keju berkualitas tinggi olahan khas Hokkaido Jepang yang fluffy dan lumer lembut di setiap gigitan.',
      imageUrl: 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=500',
      rating: 5.0,
      prepTime: '25 mnt',
      origin: 'Jepang',
      isSpecial: true,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadOrders();
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

  Future<void> fetchProductsFromAPI() async {
    isLoadingProducts.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=Dessert'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? meals = data['meals'];

        if (meals != null && meals.isNotEmpty) {
          final List<BakeryItem> loaded = meals.map((m) {
            final String name = m['strMeal'] ?? 'Pastry Item';
            final String id = m['idMeal'] ?? '';
            final String imageUrl = m['strMealThumb'] ?? '';
            final String area = m['strArea'] ?? 'Artisanal';

            final lowerName = name.toLowerCase();
            final isCake = lowerName.contains('cake') ||
                lowerName.contains('tart') ||
                lowerName.contains('pie') ||
                lowerName.contains('pudding') ||
                lowerName.contains('mousse') ||
                lowerName.contains('brownie') ||
                lowerName.contains('cheesecake') ||
                lowerName.contains('crumble') ||
                lowerName.contains('flan');

            final category = isCake ? BakeryCategory.kue : BakeryCategory.roti;

            final idNum = int.tryParse(id) ?? 50000;
            final double price = 22000 + ((idNum % 26) * 1000).toDouble();
            final double rating = 4.5 + ((idNum % 5) * 0.1);
            final int mins = 10 + (idNum % 20);

            return BakeryItem(
              id: id,
              name: name,
              category: category,
              price: price,
              description:
                  'Olahan pastry & kue artisanal segar buatan tangan master baker dengan bahan baku kualitas unggulan.',
              imageUrl: imageUrl,
              rating: double.parse(rating.toStringAsFixed(1)),
              prepTime: '$mins mnt',
              origin: area.isNotEmpty ? area : 'Artisanal',
              isSpecial: (idNum % 3 == 0),
            );
          }).toList();

          products.assignAll(loaded);
          return;
        }
      }

      products.assignAll(sampleProducts);
    } catch (e) {
      products.assignAll(sampleProducts);
      AppSnackbar.warning(
        'Mode Offline',
        'Tidak dapat menghubungi REST API. Menampilkan produk unggulan lokal.',
      );
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> addOrder(OrderModel order) async {
    orders.add(order);
    final jsonList = orders.map((o) => o.toJson()).toList();
    await _storage.write('orders', jsonList);
  }
}
