import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/notification_bloc.dart';
import '../../blocs/notification_event.dart';
import '../../blocs/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc()..add(const LoadNotifications()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Bildirishnomalar')),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationLoaded) {
              return ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.body),
                    onTap: notification.orderId != null
                        ? () {
                      Navigator.pushNamed(
                        context,
                        '/order_tracking',
                        arguments: notification.orderId,
                      );
                    }
                        : null,
                  );
                },
              );
            }
            if (state is NotificationError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('Bildirishnomalar topilmadi'));
          },
        ),
      ),
    );
  }
}