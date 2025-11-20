import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartLoading()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(const CartLoading());
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const CartLoaded([]));
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final items = query.docs
          .map((doc) => CartItem.fromFirestore(doc.data(), doc.id))
          .toList();

      emit(CartLoaded(items));
    } catch (e) {
      emit(CartError('Savatni yuklashda xato: $e'));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const CartError('Foydalanuvchi tizimga kirmagan'));
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items');

      // Check if item already exists
      final existingDocs = await cartRef
          .where('dishId', isEqualTo: event.item.dishId)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        // Update existing item
        final existingDoc = existingDocs.docs.first;
        final existingItem = CartItem.fromFirestore(
          existingDoc.data(),
          existingDoc.id,
        );

        await existingDoc.reference.update({
          'quantity': existingItem.quantity + event.item.quantity,
        });
      } else {
        // Add new item
        await cartRef.add(event.item.toFirestore());
      }

      // Reload cart
      add(LoadCart());
    } catch (e) {
      emit(CartError('Savatga qo\'shishda xato: $e'));
      // Reload cart even on error to show current state
      add(LoadCart());
    }
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCart event, Emitter<CartState> emit) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(event.itemId)
          .delete();

      add(LoadCart());
    } catch (e) {
      emit(CartError('Savatdan o\'chirishda xato: $e'));
      add(LoadCart());
    }
  }

  Future<void> _onUpdateQuantity(
      UpdateQuantity event, Emitter<CartState> emit) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (event.quantity <= 0) {
        // Remove item if quantity is 0 or less
        add(RemoveFromCart(event.itemId));
        return;
      }

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(event.itemId)
          .update({'quantity': event.quantity});

      add(LoadCart());
    } catch (e) {
      emit(CartError('Miqdorni yangilashda xato: $e'));
      add(LoadCart());
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      add(LoadCart());
    } catch (e) {
      emit(CartError('Savatni tozalashda xato: $e'));
      add(LoadCart());
    }
  }
}