import 'package:equatable/equatable.dart';
import '../models/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class LoadChatHistory extends ChatEvent {
  const LoadChatHistory();
}

class SendMessage extends ChatEvent {
  final String message;
  const SendMessage(this.message);
  @override
  List<Object> get props => [message];
}

// Real-time update events
class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object> get props => [messages];
}

class MessagesError extends ChatEvent {
  final String error;
  const MessagesError(this.error);
  @override
  List<Object> get props => [error];
}