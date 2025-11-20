import 'package:equatable/equatable.dart';
import '../models/dish.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();
  @override
  List<Object> get props => [];
}

class LoadMenu extends MenuEvent {}

class AddDish extends MenuEvent {
  final Dish dish;
  const AddDish(this.dish);
  @override
  List<Object> get props => [dish];
}

class UpdateDish extends MenuEvent {
  final Dish dish;
  const UpdateDish(this.dish);
  @override
  List<Object> get props => [dish];
}

class DeleteDish extends MenuEvent {
  final String dishId;
  const DeleteDish(this.dishId);
  @override
  List<Object> get props => [dishId];
}

class SearchDishes extends MenuEvent {
  final String query;
  const SearchDishes(this.query);
  @override
  List<Object> get props => [query];
}

class FilterByCategory extends MenuEvent {
  final String category;
  const FilterByCategory(this.category);
  @override
  List<Object> get props => [category];
}