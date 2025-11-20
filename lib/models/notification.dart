import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? orderId;
  final String userId;

  const Notification({
    required this.id,
    required this.title,
    required this.body,
    this.orderId,
    required this.userId,
  });

  factory Notification.fromFirestore(Map<String, dynamic> data, String id) {
    return Notification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      orderId: data['orderId'],
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'orderId': orderId,
      'userId': userId,
    };
  }

  @override
  List<Object?> get props => [id, title, body, orderId, userId];
}