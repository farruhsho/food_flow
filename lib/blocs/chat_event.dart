import 'package:equatable/equatable.dart';

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