import 'package:equatable/equatable.dart';

class Dish extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl; // Nullable to handle missing images
  final List<String> allergens;
  final List<String> suitableFor;
  final String category;
  final int discount; // 0-100 percentage
  final bool isHot; // HOT dish badge
  final bool isAvailable; // Show/Hide

  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.allergens = const [],
    this.suitableFor = const [],
    this.category = 'Umumiy',
    this.discount = 0,
    this.isHot = false,
    this.isAvailable = true,
  });

  factory Dish.fromFirestore(Map<String, dynamic> data, String id) {
    return Dish(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'], // Properly handle null
      allergens: List<String>.from(data['allergens'] ?? []),
      suitableFor: List<String>.from(data['suitableFor'] ?? []),
      category: data['category'] ?? 'Umumiy',
      discount: data['discount'] ?? 0,
      isHot: data['isHot'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'allergens': allergens,
      'suitableFor': suitableFor,
      'category': category,
      'discount': discount,
      'isHot': isHot,
      'isAvailable': isAvailable,
    };
  }

  // Calculate discounted price
  double get discountedPrice {
    if (discount > 0) {
      return price * (1 - discount / 100);
    }
    return price;
  }

  Dish copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? allergens,
    List<String>? suitableFor,
    String? category,
    int? discount,
    bool? isHot,
    bool? isAvailable,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      allergens: allergens ?? this.allergens,
      suitableFor: suitableFor ?? this.suitableFor,
      category: category ?? this.category,
      discount: discount ?? this.discount,
      isHot: isHot ?? this.isHot,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageUrl,
    allergens,
    suitableFor,
    category,
    discount,
    isHot,
    isAvailable,
  ];
}