import 'package:equatable/equatable.dart';
import '../models/dish.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object> get props => [];
}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Dish> dishes;
  const MenuLoaded(this.dishes);
  @override
  List<Object> get props => [dishes];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);
  @override
  List<Object> get props => [message];
}