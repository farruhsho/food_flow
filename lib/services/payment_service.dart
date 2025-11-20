// lib/services/payment_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Сервис оплаты с поддержкой Payme, Click, Uzcard
/// Обновлено для стандартов 2025
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  // API конфигурация (замените на реальные ключи)
  static const String PAYME_MERCHANT_ID = 'YOUR_PAYME_MERCHANT_ID';
  static const String PAYME_SECRET_KEY = 'YOUR_PAYME_SECRET_KEY';
  static const String CLICK_MERCHANT_ID = 'YOUR_CLICK_MERCHANT_ID';
  static const String CLICK_SECRET_KEY = 'YOUR_CLICK_SECRET_KEY';
  static const String UZCARD_MERCHANT_ID = 'YOUR_UZCARD_MERCHANT_ID';

  // API URLs
  static const String PAYME_API_URL = 'https://checkout.paycom.uz/api';
  static const String CLICK_API_URL = 'https://api.click.uz/v2/merchant';
  static const String UZCARD_API_URL = 'https://api.uzcard.uz/v1';

  /// Обработка платежа через Payme
  Future<Map<String, dynamic>> processPaymePayment({
    required String orderId,
    required double amount,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      // Конвертируем сумму в тийины (1 сум = 100 тийин)
      final amountInTiyin = (amount * 100).toInt();

      // Создаем транзакцию в БД
      final transactionRef = await _firestore.collection('transactions').add({
        'orderId': orderId,
        'amount': amount,
        'amountInTiyin': amountInTiyin,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'method': 'payme',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final transactionId = transactionRef.id;

      // Генерируем URL для оплаты
      final params = base64Encode(utf8.encode(jsonEncode({
        'm': PAYME_MERCHANT_ID,
        'ac.order_id': orderId,
        'ac.transaction_id': transactionId,
        'a': amountInTiyin,
        'c': userPhone,
      })));

      final paymentUrl = 'https://checkout.paycom.uz/$params';

      // Логируем транзакцию
      await _logPaymentAttempt(
        transactionId: transactionId,
        method: 'payme',
        amount: amount,
        userId: userId,
      );

      return {
        'success': true,
        'transactionId': transactionId,
        'paymentUrl': paymentUrl,
        'method': 'payme',
        'amount': amount,
      };
    } catch (e) {
      debugPrint('Payme payment error: $e');
      return {
        'success': false,
        'error': 'Ошибка создания платежа через Payme: ${e.toString()}',
      };
    }
  }

  /// Обработка платежа через Click
  Future<Map<String, dynamic>> processClickPayment({
    required String orderId,
    required double amount,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      // Создаем транзакцию
      final transactionRef = await _firestore.collection('transactions').add({
        'orderId': orderId,
        'amount': amount,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'method': 'click',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final transactionId = transactionRef.id;

      // Генерируем URL для оплаты Click
      final merchantTransId = '${orderId}_$transactionId';
      final returnUrl = 'foodflow://payment/success';

      final paymentUrl = 'https://my.click.uz/services/pay'
          '?service_id=$CLICK_MERCHANT_ID'
          '&merchant_id=$CLICK_MERCHANT_ID'
          '&amount=$amount'
          '&transaction_param=$merchantTransId'
          '&return_url=$returnUrl';

      await _logPaymentAttempt(
        transactionId: transactionId,
        method: 'click',
        amount: amount,
        userId: userId,
      );

      return {
        'success': true,
        'transactionId': transactionId,
        'paymentUrl': paymentUrl,
        'method': 'click',
        'amount': amount,
      };
    } catch (e) {
      debugPrint('Click payment error: $e');
      return {
        'success': false,
        'error': 'Ошибка создания платежа через Click: ${e.toString()}',
      };
    }
  }

  /// Обработка платежа через Uzcard
  Future<Map<String, dynamic>> processUzcardPayment({
    required String orderId,
    required double amount,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      final transactionRef = await _firestore.collection('transactions').add({
        'orderId': orderId,
        'amount': amount,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'method': 'uzcard',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final transactionId = transactionRef.id;

      // Генерируем URL для Uzcard
      final paymentUrl = 'https://payment.uzcard.uz/index.html'
          '?merchant_id=$UZCARD_MERCHANT_ID'
          '&order_id=$orderId'
          '&transaction_id=$transactionId'
          '&amount=${amount.toInt()}'
          '&currency=860'; // UZS код

      await _logPaymentAttempt(
        transactionId: transactionId,
        method: 'uzcard',
        amount: amount,
        userId: userId,
      );

      return {
        'success': true,
        'transactionId': transactionId,
        'paymentUrl': paymentUrl,
        'method': 'uzcard',
        'amount': amount,
      };
    } catch (e) {
      debugPrint('Uzcard payment error: $e');
      return {
        'success': false,
        'error': 'Ошибка создания платежа через Uzcard: ${e.toString()}',
      };
    }
  }

  /// Проверка статуса платежа
  Future<String> checkPaymentStatus(String transactionId) async {
    try {
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!doc.exists) return 'not_found';

      return doc.data()?['status'] ?? 'unknown';
    } catch (e) {
      debugPrint('Check payment status error: $e');
      return 'error';
    }
  }

  /// Обновление статуса платежа (вызывается webhook'ами)
  Future<void> updatePaymentStatus({
    required String transactionId,
    required String status,
    String? paymentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (paymentId != null) {
        updateData['paymentId'] = paymentId;
      }

      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);

      // Если платеж успешен, обновляем статус заказа
      if (status == 'completed' || status == 'success') {
        final transaction = await _firestore
            .collection('transactions')
            .doc(transactionId)
            .get();

        final orderId = transaction.data()?['orderId'];
        if (orderId != null) {
          await _firestore.collection('orders').doc(orderId).update({
            'paymentStatus': 'paid',
            'paidAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Update payment status error: $e');
      rethrow;
    }
  }

  /// Возврат платежа
  Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required String reason,
    double? refundAmount,
  }) async {
    try {
      final transaction = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transaction.exists) {
        return {
          'success': false,
          'error': 'Транзакция не найдена',
        };
      }

      final data = transaction.data()!;
      final amount = refundAmount ?? data['amount'];
      final method = data['method'];

      // Создаем запись о возврате
      await _firestore.collection('refunds').add({
        'transactionId': transactionId,
        'orderId': data['orderId'],
        'amount': amount,
        'reason': reason,
        'method': method,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Обновляем статус транзакции
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'refunding',
        'refundReason': reason,
        'refundAmount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Возврат инициирован',
        'amount': amount,
      };
    } catch (e) {
      debugPrint('Refund error: $e');
      return {
        'success': false,
        'error': 'Ошибка возврата: ${e.toString()}',
      };
    }
  }

  /// История платежей пользователя
  Stream<List<Map<String, dynamic>>> getUserPaymentHistory(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  /// Аналитика платежей (для админов)
  Future<Map<String, dynamic>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      var query = _firestore
          .collection('transactions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();

      double totalAmount = 0;
      int totalCount = 0;
      int successfulCount = 0;
      int failedCount = 0;
      Map<String, int> methodCounts = {};
      Map<String, double> methodAmounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0) as double;
        final status = data['status'] as String;
        final method = data['method'] as String;

        totalCount++;
        totalAmount += amount;

        if (status == 'completed' || status == 'success') {
          successfulCount++;
        } else if (status == 'failed' || status == 'cancelled') {
          failedCount++;
        }

        methodCounts[method] = (methodCounts[method] ?? 0) + 1;
        methodAmounts[method] = (methodAmounts[method] ?? 0) + amount;
      }

      return {
        'totalAmount': totalAmount,
        'totalCount': totalCount,
        'successfulCount': successfulCount,
        'failedCount': failedCount,
        'successRate': totalCount > 0 ? (successfulCount / totalCount * 100) : 0,
        'averageAmount': totalCount > 0 ? (totalAmount / totalCount) : 0,
        'methodCounts': methodCounts,
        'methodAmounts': methodAmounts,
      };
    } catch (e) {
      debugPrint('Payment analytics error: $e');
      return {};
    }
  }

  /// Логирование попытки платежа
  Future<void> _logPaymentAttempt({
    required String transactionId,
    required String method,
    required double amount,
    required String userId,
  }) async {
    try {
      await _firestore.collection('payment_logs').add({
        'transactionId': transactionId,
        'method': method,
        'amount': amount,
        'userId': userId,
        'action': 'payment_initiated',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Payment log error: $e');
    }
  }

  /// Получить доступные методы оплаты
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'id': 'payme',
        'name': 'Payme',
        'icon': 'assets/icons/payme.png',
        'description': 'Оплата через Payme',
        'available': true,
      },
      {
        'id': 'click',
        'name': 'Click',
        'icon': 'assets/icons/click.png',
        'description': 'Оплата через Click',
        'available': true,
      },
      {
        'id': 'uzcard',
        'name': 'Uzcard',
        'icon': 'assets/icons/uzcard.png',
        'description': 'Оплата картой Uzcard',
        'available': true,
      },
      {
        'id': 'cash',
        'name': 'Наличные',
        'icon': 'assets/icons/cash.png',
        'description': 'Оплата при получении',
        'available': true,
      },
    ];
  }

  /// Разделить счет между пользователями (инновация 2025)
  Future<Map<String, dynamic>> splitPayment({
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> participants,
  }) async {
    try {
      // Создаем групповую транзакцию
      final splitRef = await _firestore.collection('split_payments').add({
        'orderId': orderId,
        'totalAmount': totalAmount,
        'participants': participants,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Создаем индивидуальные транзакции для каждого участника
      final transactions = <String>[];
      for (var participant in participants) {
        final userId = participant['userId'];
        final amount = participant['amount'];

        final transactionRef = await _firestore.collection('transactions').add({
          'orderId': orderId,
          'splitPaymentId': splitRef.id,
          'amount': amount,
          'userId': userId,
          'method': 'split',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transactions.add(transactionRef.id);
      }

      return {
        'success': true,
        'splitPaymentId': splitRef.id,
        'transactions': transactions,
      };
    } catch (e) {
      debugPrint('Split payment error: $e');
      return {
        'success': false,
        'error': 'Ошибка разделения счета: ${e.toString()}',
      };
    }
  }

  /// Оплата с использованием криптовалюты (инновация 2025)
  Future<Map<String, dynamic>> processCryptoPayment({
    required String orderId,
    required double amount,
    required String userId,
    required String cryptocurrency,
  }) async {
    try {
      // Здесь будет интеграция с криптовалютными платежными системами
      // Например: CoinPayments, NOWPayments, или блокчейн напрямую

      final transactionRef = await _firestore.collection('transactions').add({
        'orderId': orderId,
        'amount': amount,
        'userId': userId,
        'method': 'crypto',
        'cryptocurrency': cryptocurrency,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'transactionId': transactionRef.id,
        'cryptocurrency': cryptocurrency,
        'message': 'Криптоплатеж будет доступен в следующем обновлении',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка криптоплатежа: ${e.toString()}',
      };
    }
  }
}