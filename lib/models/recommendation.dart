import 'package:equatable/equatable.dart';

class Recommendation extends Equatable {
  final String id;
  final String dishId;
  final String title;
  final String description;
  final String imageUrl;

  const Recommendation({
    required this.id,
    required this.dishId,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  factory Recommendation.fromFirestore(Map<String, dynamic> data, String id) {
    return Recommendation(
      id: id,
      dishId: data['dishId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'dishId': dishId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object> get props => [id, dishId, title, description, imageUrl];
}