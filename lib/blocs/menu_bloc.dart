import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuLoading()) {
    on<LoadMenu>(_onLoadMenu);
    on<AddDish>(_onAddDish);
    on<DeleteDish>(_onDeleteDish);
    on<UpdateDish>(_onUpdateDish);
    on<SearchDishes>(_onSearchDishes);
    on<FilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final query = await FirebaseFirestore.instance
          .collection('dishes')
          .where('isAvailable', isEqualTo: true)
          .get();
      final dishes = query.docs
          .map((doc) => Dish.fromFirestore(doc.data(), doc.id))
          .toList();
      emit(MenuLoaded(dishes));
    } catch (e) {
      emit(MenuError('Menyuni yuklashda xato: $e'));
    }
  }

  Future<void> _onAddDish(AddDish event, Emitter<MenuState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('dishes')
          .doc(event.dish.id)
          .set(event.dish.toFirestore());
      add(LoadMenu());
    } catch (e) {
      emit(MenuError('Taom qo\'shishda xato: $e'));
    }
  }

  Future<void> _onDeleteDish(DeleteDish event, Emitter<MenuState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('dishes')
          .doc(event.dishId)
          .delete();
      add(LoadMenu());
    } catch (e) {
      emit(MenuError('Taomni o\'chirishda xato: $e'));
    }
  }

  Future<void> _onUpdateDish(UpdateDish event, Emitter<MenuState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('dishes')
          .doc(event.dish.id)
          .update(event.dish.toFirestore());
      add(LoadMenu());
    } catch (e) {
      emit(MenuError('Taomni yangilashda xato: $e'));
    }
  }

  Future<void> _onSearchDishes(SearchDishes event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final query = await FirebaseFirestore.instance
          .collection('dishes')
          .where('isAvailable', isEqualTo: true)
          .get();
      final dishes = query.docs
          .map((doc) => Dish.fromFirestore(doc.data(), doc.id))
          .where((dish) =>
      dish.name.toLowerCase().contains(event.query.toLowerCase()) ||
          dish.description.toLowerCase().contains(event.query.toLowerCase()) ||
          dish.category.toLowerCase().contains(event.query.toLowerCase())
      )
          .toList();
      emit(MenuLoaded(dishes));
    } catch (e) {
      emit(MenuError('Qidirishda xato: $e'));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final query = await FirebaseFirestore.instance
          .collection('dishes')
          .where('category', isEqualTo: event.category)
          .where('isAvailable', isEqualTo: true)
          .get();
      final dishes = query.docs
          .map((doc) => Dish.fromFirestore(doc.data(), doc.id))
          .toList();
      emit(MenuLoaded(dishes));
    } catch (e) {
      emit(MenuError('Filtrlashda xato: $e'));
    }
  }
}