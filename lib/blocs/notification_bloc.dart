import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationLoading()) {
    on<LoadNotifications>((event, emit) async {
      emit(const NotificationLoading());
      try {
        final userId = auth.FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          emit(const NotificationError('Пользователь не авторизован'));
          return;
        }
        final query = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        final notifications = query.docs
            .map((doc) => Notification.fromFirestore(doc.data(), doc.id))
            .toList();
        emit(NotificationLoaded(notifications));
      } catch (e) {
        emit(NotificationError('Ошибка загрузки уведомлений: $e'));
      }
    });

    on<ReceiveNotification>((event, emit) async {
      try {
        final userId = auth.FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          emit(const NotificationError('Пользователь не авторизован'));
          return;
        }
        final notification = Notification(
          id: event.message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: event.message.notification?.title ?? '',
          body: event.message.notification?.body ?? '',
          orderId: event.message.data['orderId'],
          userId: userId,
        );
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toFirestore());
        add(const LoadNotifications());
      } catch (e) {
        emit(NotificationError('Ошибка обработки уведомления: $e'));
      }
    });
  }
}