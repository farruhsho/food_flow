import 'package:equatable/equatable.dart';
import '../models/recommendation.dart';

abstract class RecommendationState extends Equatable {
  const RecommendationState();
  @override
  List<Object> get props => [];
}

class RecommendationLoading extends RecommendationState {
  const RecommendationLoading();
}

class RecommendationLoaded extends RecommendationState {
  final List<Recommendation> recommendations;
  const RecommendationLoaded(this.recommendations);
  @override
  List<Object> get props => [recommendations];
}

class RecommendationError extends RecommendationState {
  final String message;
  const RecommendationError(this.message);
  @override
  List<Object> get props => [message];
}