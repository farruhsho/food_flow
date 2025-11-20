import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';
import 'recommendation_event.dart';
import 'recommendation_state.dart';

class RecommendationBloc extends Bloc<RecommendationEvent, RecommendationState> {
  RecommendationBloc() : super(const RecommendationLoading()) {
    on<LoadRecommendations>(_onLoadRecommendations);
  }

  Future<void> _onLoadRecommendations(
      LoadRecommendations event,
      Emitter<RecommendationState> emit,
      ) async {
    emit(const RecommendationLoading());
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recommendations')
          .get();

      final recommendations = snapshot.docs
          .map((doc) => Recommendation.fromFirestore(doc.data(), doc.id))
          .toList();

      emit(RecommendationLoaded(recommendations));
    } catch (e) {
      emit(RecommendationError('Ошибка загрузки рекомендаций: $e'));
    }
  }
}