enum BakeryCategory { roti, kue }

class BakeryItem {
  final String id;
  final String name;
  final BakeryCategory category;
  final double price;
  final String description;
  final String imageUrl;
  final double rating;
  final String prepTime;
  final String origin;
  final bool isSpecial;

  BakeryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.rating = 4.8,
    this.prepTime = '15 mnt',
    this.origin = 'Artisanal',
    this.isSpecial = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'rating': rating,
        'prepTime': prepTime,
        'origin': origin,
        'isSpecial': isSpecial,
      };

  factory BakeryItem.fromJson(Map<String, dynamic> json) => BakeryItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] == 'kue'
            ? BakeryCategory.kue
            : BakeryCategory.roti,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        prepTime: json['prepTime'] ?? '15 mnt',
        origin: json['origin'] ?? 'Artisanal',
        isSpecial: json['isSpecial'] ?? false,
      );
}
