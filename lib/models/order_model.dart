import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order extends Equatable {
  final String id;
  final String clientId;
  final String? courierId;
  final String status;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String address;
  final String? deliveryPhoto;
  final String orderType; // 'delivery' or 'dine-in'
  final int? tableNumber;
  final Timestamp? timestamp;

  const Order({
    required this.id,
    required this.clientId,
    this.courierId,
    required this.status,
    required this.items,
    required this.totalPrice,
    required this.address,
    this.deliveryPhoto,
    this.orderType = 'delivery',
    this.tableNumber,
    this.timestamp,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      clientId: data['clientId'] ?? '',
      courierId: data['courierId'],
      status: data['status'] ?? 'pending',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      deliveryPhoto: data['deliveryPhoto'],
      orderType: data['orderType'] ?? 'delivery',
      tableNumber: data['tableNumber'],
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'clientId': clientId,
      'courierId': courierId,
      'status': status,
      'items': items,
      'totalPrice': totalPrice,
      'address': address,
      'deliveryPhoto': deliveryPhoto,
      'orderType': orderType,
      'tableNumber': tableNumber,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  Order copyWith({
    String? id,
    String? clientId,
    String? courierId,
    String? status,
    List<Map<String, dynamic>>? items,
    double? totalPrice,
    String? address,
    String? deliveryPhoto,
    String? orderType,
    int? tableNumber,
    Timestamp? timestamp,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      courierId: courierId ?? this.courierId,
      status: status ?? this.status,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      address: address ?? this.address,
      deliveryPhoto: deliveryPhoto ?? this.deliveryPhoto,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    courierId,
    status,
    items,
    totalPrice,
    address,
    deliveryPhoto,
    orderType,
    tableNumber,
    timestamp,
  ];
}