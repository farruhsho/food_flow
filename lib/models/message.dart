import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message extends Equatable {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      text: data['text'] ?? '',
      isFromUser: data['isFromUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isFromUser': isFromUser,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  List<Object> get props => [id, text, isFromUser, timestamp];
}