import 'package:equatable/equatable.dart';

abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();
  @override
  List<Object> get props => [];
}

class LoadRecommendations extends RecommendationEvent {
  const LoadRecommendations();
}