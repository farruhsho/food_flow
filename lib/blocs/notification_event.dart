import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class ReceiveNotification extends NotificationEvent {
  final RemoteMessage message;
  const ReceiveNotification(this.message);
  @override
  List<Object> get props => [message];
}