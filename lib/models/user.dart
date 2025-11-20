import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String role; // admin, director, courier, waiter, client
  final String name;
  final int points;
  final int discounts;
  final String? phone;
  final String? photo;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.points = 0,
    this.discounts = 0,
    this.phone,
    this.photo,
    this.isActive = true,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      name: data['name'] ?? '',
      points: (data['points'] ?? 0) as int,
      discounts: (data['discounts'] ?? 0) as int,
      phone: data['phone'],
      photo: data['photo'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'points': points,
      'discounts': discounts,
      'phone': phone,
      'photo': photo,
      'isActive': isActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    int? points,
    int? discounts,
    String? phone,
    String? photo,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      points: points ?? this.points,
      discounts: discounts ?? this.discounts,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, email, role, name, points, discounts, phone, photo, isActive];
}