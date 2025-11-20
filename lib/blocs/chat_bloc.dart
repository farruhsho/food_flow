import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  ChatBloc() : super(const ChatLoading()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<MessagesError>(_onMessagesError);
  }

  Future<void> _onLoadChatHistory(
      LoadChatHistory event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const ChatError('Foydalanuvchi tizimga kirmagan'));
        return;
      }

      // Cancel previous subscription if exists
      await _messagesSubscription?.cancel();

      // Listen to messages in real-time
      _messagesSubscription = FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen(
        (snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromFirestore(doc.data(), doc.id))
              .toList();
          add(MessagesUpdated(messages));
        },
        onError: (error) {
          add(MessagesError('Chat tarixini yuklashda xato: $error'));
        },
      );
    } catch (e) {
      emit(ChatError('Chat tarixini yuklashda xato: $e'));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages));
  }

  void _onMessagesError(MessagesError event, Emitter<ChatState> emit) {
    emit(ChatError(event.error));
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.message,
        isFromUser: true,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .doc(userMessage.id)
          .set(userMessage.toFirestore());

      await Future.delayed(const Duration(seconds: 1));

      final aiMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: _generateAIResponse(event.message),
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(userId)
          .collection('messages')
          .doc(aiMessage.id)
          .set(aiMessage.toFirestore());

      // No need to manually reload - real-time listener will update automatically
    } catch (e) {
      emit(ChatError('Xabar yuborishda xato: $e'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('salom') || message.contains('assalomu alaykum')) {
      return 'Assalomu alaykum! FoodFlow yordamchisiga xush kelibsiz. Sizga qanday yordam bera olaman?';
    } else if (message.contains('menu') || message.contains('taom')) {
      return 'Bizda turli xil mazali taomlar mavjud: pizza, burger, salat va boshqalar. Menyu bo\'limidan ko\'rib chiqishingiz mumkin.';
    } else if (message.contains('narx') || message.contains('price')) {
      return 'Bizning narxlarimiz juda qulay. Har bir taomning narxi mahsulot sahifasida ko\'rsatilgan.';
    } else if (message.contains('yetkazish') || message.contains('dostavka')) {
      return 'Biz tez yetkazib berish xizmatini taqdim etamiz. Yetkazib berish 30-40 daqiqa ichida amalga oshiriladi.';
    } else if (message.contains('to\'lov') || message.contains('payment')) {
      return 'Siz naqd pul yoki karta orqali to\'lashingiz mumkin.';
    } else if (message.contains('rahmat') || message.contains('raxmat')) {
      return 'Arzimaydi! Yana savollaringiz bo\'lsa, bemalol so\'rang.';
    } else {
      return 'Savolingizni tushunmadim. Iltimos, aniqroq so\'rang yoki quyidagi mavzulardan birini tanlang: menyu, narx, yetkazish, to\'lov.';
    }
  }
}