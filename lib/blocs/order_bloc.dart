import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc() : super(const OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<AssignCourier>(_onAssignCourier);
    on<AddOrder>(_onAddOrder);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const OrderError('Пользователь не авторизован'));
        return;
      }
      final userDoc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final role = userDoc['role'] as String;
      firestore.Query<Map<String, dynamic>> query;
      if (role == 'client') {
        query = firestore.FirebaseFirestore.instance
            .collection('orders')
            .where('clientId', isEqualTo: userId);
      } else if (role == 'courier') {
        query = firestore.FirebaseFirestore.instance
            .collection('orders')
            .where('courierId', isEqualTo: userId);
      } else {
        query = firestore.FirebaseFirestore.instance.collection('orders');
      }
      final snapshot = await query.get();
      final orders = snapshot.docs
          .map((doc) => Order.fromFirestore(doc.data(), doc.id))
          .toList();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка загрузки заказов: $e'));
    }
  }

  Future<void> _onUpdateOrderStatus(
      UpdateOrderStatus event, Emitter<OrderState> emit) async {
    try {
      await firestore.FirebaseFirestore.instance
          .collection('orders')
          .doc(event.orderId)
          .update({
        'status': event.newStatus,
      });
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError('Ошибка обновления статуса: $e'));
    }
  }

  Future<void> _onAssignCourier(
      AssignCourier event, Emitter<OrderState> emit) async {
    try {
      await firestore.FirebaseFirestore.instance
          .collection('orders')
          .doc(event.orderId)
          .update({
        'courierId': event.courierId,
        'status': 'accepted',
      });
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError('Ошибка назначения курьера: $e'));
    }
  }

  Future<void> _onAddOrder(AddOrder event, Emitter<OrderState> emit) async {
    try {
      await firestore.FirebaseFirestore.instance
          .collection('orders')
          .doc(event.order.id)
          .set(event.order.toFirestore());
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError('Ошибка добавления заказа: $e'));
    }
  }
}