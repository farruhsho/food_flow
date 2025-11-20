// lib/blocs/order_event.dart

import 'package:equatable/equatable.dart';
import '../models/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  const LoadOrders();
}

class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final String newStatus;
  const UpdateOrderStatus(this.orderId, this.newStatus);
  @override
  List<Object?> get props => [orderId, newStatus];
}

class AssignCourier extends OrderEvent {
  final String orderId;
  final String courierId;
  const AssignCourier(this.orderId, this.courierId);
  @override
  List<Object?> get props => [orderId, courierId];
}

class AddOrder extends OrderEvent {
  final Order order;
  const AddOrder(this.order);
  @override
  List<Object?> get props => [order];
}

// YANGI: CreateOrder (CartScreen uchun)
class CreateOrder extends OrderEvent {
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String address;
  final String orderType; // 'delivery' yoki 'dine-in'
  final int? tableNumber;

  const CreateOrder({
    required this.items,
    required this.totalPrice,
    required this.address,
    required this.orderType,
    this.tableNumber,
  });

  @override
  List<Object?> get props => [items, totalPrice, address, orderType, tableNumber];
}