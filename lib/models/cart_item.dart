import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String dishId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.id,
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  // Добавляем метод copyWith
  CartItem copyWith({
    String? id,
    String? dishId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      dishId: dishId ?? this.dishId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      dishId: data['dishId'] ?? id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dishId': dishId,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [id, dishId, name, price, quantity, imageUrl];
}