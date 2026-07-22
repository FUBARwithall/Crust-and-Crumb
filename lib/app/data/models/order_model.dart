import 'bakery_item.dart';

class OrderCartItem {
  final BakeryItem item;
  final int quantity;

  OrderCartItem({required this.item, required this.quantity});

  double get subtotal => item.price * quantity;

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'quantity': quantity,
      };

  factory OrderCartItem.fromJson(Map<String, dynamic> json) => OrderCartItem(
        item: BakeryItem.fromJson(Map<String, dynamic>.from(json['item'])),
        quantity: json['quantity'] ?? 1,
      );
}

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String addressNotes;
  final double latitude;
  final double longitude;
  final String shippingMethod;
  final String paymentMethod;
  final List<OrderCartItem> items;
  final double totalPrice;
  final DateTime orderTime;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.addressNotes,
    required this.latitude,
    required this.longitude,
    this.shippingMethod = 'Kurir Crust & Crumb Express',
    this.paymentMethod = 'Bayar di Tempat (COD)',
    required this.items,
    required this.totalPrice,
    required this.orderTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'addressNotes': addressNotes,
        'latitude': latitude,
        'longitude': longitude,
        'shippingMethod': shippingMethod,
        'paymentMethod': paymentMethod,
        'items': items.map((e) => e.toJson()).toList(),
        'totalPrice': totalPrice,
        'orderTime': orderTime.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] ?? '',
        customerName: json['customerName'] ?? '',
        customerPhone: json['customerPhone'] ?? '',
        addressNotes: json['addressNotes'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        shippingMethod: json['shippingMethod'] ?? 'Kurir Crust & Crumb Express',
        paymentMethod: json['paymentMethod'] ?? 'Bayar di Tempat (COD)',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderCartItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
        orderTime: json['orderTime'] != null
            ? DateTime.parse(json['orderTime'])
            : DateTime.now(),
      );
}
