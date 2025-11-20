// lib/services/loyalty_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Инновационная система лояльности 2025
/// Включает: баллы, кэшбэк, уровни, достижения, NFT-карты
class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Константы системы лояльности
  static const double POINTS_PER_1000_SUM = 1.0; // 1000 сум = 1 балл
  static const double CASHBACK_PERCENTAGE = 0.05; // 5% кэшбэк
  static const int POINTS_TO_SUM_RATE = 100; // 1 балл = 100 сум

  // Уровни лояльности
  static const Map<String, Map<String, dynamic>> LOYALTY_LEVELS = {
    'bronze': {
      'name': 'Бронзовый',
      'minPoints': 0,
      'maxPoints': 99,
      'discount': 0.0,
      'cashback': 0.05,
      'color': 0xFFCD7F32,
      'icon': '🥉',
    },
    'silver': {
      'name': 'Серебряный',
      'minPoints': 100,
      'maxPoints': 499,
      'discount': 0.05,
      'cashback': 0.07,
      'color': 0xFFC0C0C0,
      'icon': '🥈',
    },
    'gold': {
      'name': 'Золотой',
      'minPoints': 500,
      'maxPoints': 999,
      'discount': 0.10,
      'cashback': 0.10,
      'color': 0xFFFFD700,
      'icon': '🥇',
    },
    'platinum': {
      'name': 'Платиновый',
      'minPoints': 1000,
      'maxPoints': 2499,
      'discount': 0.15,
      'cashback': 0.12,
      'color': 0xFFE5E4E2,
      'icon': '💎',
    },
    'diamond': {
      'name': 'Бриллиантовый',
      'minPoints': 2500,
      'maxPoints': 999999,
      'discount': 0.20,
      'cashback': 0.15,
      'color': 0xFFB9F2FF,
      'icon': '💠',
    },
  };

  /// Начислить баллы за заказ
  Future<Map<String, dynamic>> awardPointsForOrder({
    required String userId,
    required double orderAmount,
    required String orderId,
  }) async {
    try {
      // Получаем текущие данные пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentPoints = userDoc.data()?['points'] ?? 0;
      final currentLevel = getLoyaltyLevel(currentPoints);

      // Рассчитываем бонусы с учетом уровня
      final basePoints = (orderAmount / 1000) * POINTS_PER_1000_SUM;
      final levelMultiplier = _getLevelMultiplier(currentLevel);
      final totalPoints = (basePoints * levelMultiplier).round();

      final baseCashback = orderAmount * CASHBACK_PERCENTAGE;
      final levelCashback = orderAmount * LOYALTY_LEVELS[currentLevel]!['cashback'];
      final totalCashback = levelCashback;

      // Обновляем баллы пользователя
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(totalPoints),
        'totalSpent': FieldValue.increment(orderAmount),
        'totalCashback': FieldValue.increment(totalCashback),
        'ordersCount': FieldValue.increment(1),
        'lastOrderDate': FieldValue.serverTimestamp(),
      });

      // Записываем транзакцию баллов
      final transactionRef = await _firestore.collection('loyalty_transactions').add({
        'userId': userId,
        'orderId': orderId,
        'points': totalPoints,
        'cashback': totalCashback,
        'orderAmount': orderAmount,
        'type': 'earned',
        'level': currentLevel,
        'multiplier': levelMultiplier,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Проверяем повышение уровня
      final newPoints = currentPoints + totalPoints;
      final newLevel = getLoyaltyLevel(newPoints);

      if (newLevel != currentLevel) {
        await _handleLevelUp(userId, currentLevel, newLevel, newPoints);
      }

      // Проверяем достижения
      await _checkAchievements(userId, orderAmount, newPoints);

      return {
        'success': true,
        'pointsAwarded': totalPoints,
        'cashbackAwarded': totalCashback,
        'newTotalPoints': newPoints,
        'currentLevel': newLevel,
        'leveledUp': newLevel != currentLevel,
        'transactionId': transactionRef.id,
      };
    } catch (e) {
      debugPrint('Award points error: $e');
      return {
        'success': false,
        'error': 'Ошибка начисления баллов: ${e.toString()}',
      };
    }
  }

  /// Использовать баллы для оплаты
  Future<Map<String, dynamic>> redeemPoints({
    required String userId,
    required int pointsToRedeem,
    required String orderId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentPoints = userDoc.data()?['points'] ?? 0;

      if (currentPoints < pointsToRedeem) {
        return {
          'success': false,
          'error': 'Недостаточно баллов',
          'required': pointsToRedeem,
          'available': currentPoints,
        };
      }

      // Конвертируем баллы в сумы
      final discountAmount = pointsToRedeem * POINTS_TO_SUM_RATE;

      // Списываем баллы
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(-pointsToRedeem),
        'totalRedeemed': FieldValue.increment(pointsToRedeem),
      });

      // Записываем транзакцию
      await _firestore.collection('loyalty_transactions').add({
        'userId': userId,
        'orderId': orderId,
        'points': pointsToRedeem,
        'discountAmount': discountAmount,
        'type': 'redeemed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'pointsRedeemed': pointsToRedeem,
        'discountAmount': discountAmount,
        'remainingPoints': currentPoints - pointsToRedeem,
      };
    } catch (e) {
      debugPrint('Redeem points error: $e');
      return {
        'success': false,
        'error': 'Ошибка списания баллов: ${e.toString()}',
      };
    }
  }

  /// Получить уровень лояльности по баллам
  String getLoyaltyLevel(int points) {
    for (var entry in LOYALTY_LEVELS.entries) {
      final level = entry.value;
      if (points >= level['minPoints'] && points <= level['maxPoints']) {
        return entry.key;
      }
    }
    return 'bronze';
  }

  /// Получить данные уровня
  Map<String, dynamic> getLevelData(String level) {
    return LOYALTY_LEVELS[level] ?? LOYALTY_LEVELS['bronze']!;
  }

  /// Получить процент скидки по уровню
  double getDiscountPercentage(int points) {
    final level = getLoyaltyLevel(points);
    return LOYALTY_LEVELS[level]!['discount'];
  }

  /// Получить процент кэшбэка по уровню
  double getCashbackPercentage(int points) {
    final level = getLoyaltyLevel(points);
    return LOYALTY_LEVELS[level]!['cashback'];
  }

  /// Множитель начисления баллов по уровню
  double _getLevelMultiplier(String level) {
    switch (level) {
      case 'silver':
        return 1.2;
      case 'gold':
        return 1.5;
      case 'platinum':
        return 2.0;
      case 'diamond':
        return 2.5;
      default:
        return 1.0;
    }
  }

  /// Обработка повышения уровня
  Future<void> _handleLevelUp(
      String userId,
      String oldLevel,
      String newLevel,
      int points,
      ) async {
    try {
      // Создаем уведомление о повышении
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'level_up',
        'title': '🎉 Поздравляем с повышением!',
        'body': 'Вы достигли ${LOYALTY_LEVELS[newLevel]!['name']} уровня!',
        'data': {
          'oldLevel': oldLevel,
          'newLevel': newLevel,
          'points': points,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Даем бонус за повышение уровня
      final bonusPoints = _getLevelUpBonus(newLevel);
      if (bonusPoints > 0) {
        await _firestore.collection('users').doc(userId).update({
          'points': FieldValue.increment(bonusPoints),
        });

        await _firestore.collection('loyalty_transactions').add({
          'userId': userId,
          'points': bonusPoints,
          'type': 'level_up_bonus',
          'newLevel': newLevel,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Записываем достижение
      await _firestore.collection('achievements').add({
        'userId': userId,
        'type': 'level_up',
        'level': newLevel,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Handle level up error: $e');
    }
  }

  /// Бонус за повышение уровня
  int _getLevelUpBonus(String level) {
    switch (level) {
      case 'silver':
        return 50;
      case 'gold':
        return 100;
      case 'platinum':
        return 250;
      case 'diamond':
        return 500;
      default:
        return 0;
    }
  }

  /// Проверка достижений
  Future<void> _checkAchievements(
      String userId,
      double orderAmount,
      int totalPoints,
      ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final ordersCount = userDoc.data()?['ordersCount'] ?? 0;
      final totalSpent = userDoc.data()?['totalSpent'] ?? 0.0;

      final achievements = <Map<String, dynamic>>[];

      // Достижение: Первый заказ
      if (ordersCount == 1) {
        achievements.add({
          'type': 'first_order',
          'title': '🎊 Первый заказ',
          'description': 'Вы сделали свой первый заказ!',
          'reward': 20,
        });
      }

      // Достижение: 10 заказов
      if (ordersCount == 10) {
        achievements.add({
          'type': '10_orders',
          'title': '⭐ 10 заказов',
          'description': 'Поздравляем с 10-м заказом!',
          'reward': 50,
        });
      }

      // Достижение: 50 заказов
      if (ordersCount == 50) {
        achievements.add({
          'type': '50_orders',
          'title': '🌟 50 заказов',
          'description': 'Вы верный клиент!',
          'reward': 200,
        });
      }

      // Достижение: 100 заказов
      if (ordersCount == 100) {
        achievements.add({
          'type': '100_orders',
          'title': '💫 100 заказов',
          'description': 'Легендарный клиент!',
          'reward': 500,
        });
      }

      // Достижение: Большой заказ
      if (orderAmount >= 500000) {
        achievements.add({
          'type': 'big_spender',
          'title': '💰 Щедрый заказ',
          'description': 'Заказ на сумму более 500,000 сум!',
          'reward': 100,
        });
      }

      // Сохраняем достижения и начисляем награды
      for (var achievement in achievements) {
        await _firestore.collection('achievements').add({
          'userId': userId,
          ...achievement,
          'achievedAt': FieldValue.serverTimestamp(),
        });

        // Начисляем награду
        await _firestore.collection('users').doc(userId).update({
          'points': FieldValue.increment(achievement['reward']),
        });

        // Создаем уведомление
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'achievement',
          'title': achievement['title'],
          'body': '${achievement['description']} +${achievement['reward']} баллов',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Check achievements error: $e');
    }
  }

  /// История транзакций лояльности
  Stream<List<Map<String, dynamic>>> getLoyaltyHistory(String userId) {
    return _firestore
        .collection('loyalty_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  /// Получить все достижения пользователя
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .orderBy('achievedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Get achievements error: $e');
      return [];
    }
  }

  /// Передать баллы другому пользователю (инновация 2025)
  Future<Map<String, dynamic>> transferPoints({
    required String fromUserId,
    required String toUserId,
    required int points,
  }) async {
    try {
      final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
      final currentPoints = fromUserDoc.data()?['points'] ?? 0;

      if (currentPoints < points) {
        return {
          'success': false,
          'error': 'Недостаточно баллов для перевода',
        };
      }

      // Минимум для перевода - 10 баллов
      if (points < 10) {
        return {
          'success': false,
          'error': 'Минимум для перевода: 10 баллов',
        };
      }

      // Списываем у отправителя
      await _firestore.collection('users').doc(fromUserId).update({
        'points': FieldValue.increment(-points),
      });

      // Начисляем получателю
      await _firestore.collection('users').doc(toUserId).update({
        'points': FieldValue.increment(points),
      });

      // Записываем транзакции
      final batch = _firestore.batch();

      batch.set(_firestore.collection('loyalty_transactions').doc(), {
        'userId': fromUserId,
        'points': points,
        'type': 'transferred_out',
        'recipientId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_firestore.collection('loyalty_transactions').doc(), {
        'userId': toUserId,
        'points': points,
        'type': 'transferred_in',
        'senderId': fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return {
        'success': true,
        'pointsTransferred': points,
        'message': 'Баллы успешно переведены',
      };
    } catch (e) {
      debugPrint('Transfer points error: $e');
      return {
        'success': false,
        'error': 'Ошибка перевода баллов: ${e.toString()}',
      };
    }
  }

  /// Создать NFT-карту лояльности (инновация 2025)
  Future<Map<String, dynamic>> createNFTLoyaltyCard(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final level = getLoyaltyLevel(userDoc.data()?['points'] ?? 0);
      final levelData = getLevelData(level);

      // Генерируем уникальный NFT ID
      final nftId = 'NFT_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('nft_loyalty_cards').add({
        'userId': userId,
        'nftId': nftId,
        'level': level,
        'levelName': levelData['name'],
        'color': levelData['color'],
        'icon': levelData['icon'],
        'createdAt': FieldValue.serverTimestamp(),
        'blockchain': 'polygon', // Или другой блокчейн
        'status': 'minting',
      });

      return {
        'success': true,
        'nftId': nftId,
        'message': 'NFT-карта создается...',
      };
    } catch (e) {
      debugPrint('Create NFT card error: $e');
      return {
        'success': false,
        'error': 'Ошибка создания NFT: ${e.toString()}',
      };
    }
  }

  /// Получить рейтинг пользователей (таблица лидеров)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final data = entry.value.data();
        return {
          'rank': rank,
          'userId': entry.value.id,
          'name': data['name'] ?? 'Пользователь',
          'points': data['points'] ?? 0,
          'level': getLoyaltyLevel(data['points'] ?? 0),
          'photo': data['photo'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return [];
    }
  }

  /// Применить промокод
  Future<Map<String, dynamic>> applyPromoCode({
    required String userId,
    required String promoCode,
    required String orderId,
  }) async {
    try {
      final promoSnapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: promoCode.toUpperCase())
          .where('active', isEqualTo: true)
          .get();

      if (promoSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Промокод не найден или неактивен',
        };
      }

      final promoDoc = promoSnapshot.docs.first;
      final promoData = promoDoc.data();

      // Проверяем срок действия
      final expiresAt = promoData['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return {
          'success': false,
          'error': 'Промокод истек',
        };
      }

      // Проверяем лимит использований
      final usageLimit = promoData['usageLimit'] as int?;
      final usageCount = promoData['usageCount'] as int? ?? 0;
      if (usageLimit != null && usageCount >= usageLimit) {
        return {
          'success': false,
          'error': 'Промокод исчерпан',
        };
      }

      // Применяем промокод
      final bonusPoints = promoData['bonusPoints'] as int? ?? 0;
      final discountPercent = promoData['discountPercent'] as double? ?? 0.0;

      if (bonusPoints > 0) {
        await _firestore.collection('users').doc(userId).update({
          'points': FieldValue.increment(bonusPoints),
        });
      }

      // Обновляем счетчик использований
      await _firestore.collection('promo_codes').doc(promoDoc.id).update({
        'usageCount': FieldValue.increment(1),
      });

      // Записываем использование
      await _firestore.collection('promo_code_usage').add({
        'userId': userId,
        'orderId': orderId,
        'promoCode': promoCode,
        'bonusPoints': bonusPoints,
        'discountPercent': discountPercent,
        'usedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'bonusPoints': bonusPoints,
        'discountPercent': discountPercent,
        'message': 'Промокод успешно применен!',
      };
    } catch (e) {
      debugPrint('Apply promo code error: $e');
      return {
        'success': false,
        'error': 'Ошибка применения промокода: ${e.toString()}',
      };
    }
  }
}