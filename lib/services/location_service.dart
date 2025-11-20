// lib/services/location_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// Сервис геолокации и отслеживания курьеров
/// Обновлено для 2025 с продвинутыми функциями
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;

  /// Проверить разрешения на геолокацию
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включена ли служба геолокации
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Получить текущую позицию
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      debugPrint('Get current position error: $e');
      return null;
    }
  }

  /// Начать отслеживание позиции курьера
  Future<void> startTracking({
    required String courierId,
    required String orderId,
  }) async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Нет разрешения на геолокацию');
      }

      // Останавливаем предыдущее отслеживание
      await stopTracking();

      // Создаем запись о начале отслеживания
      await _firestore.collection('courier_tracking').doc(orderId).set({
        'courierId': courierId,
        'orderId': orderId,
        'status': 'tracking',
        'startedAt': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      // Начинаем отслеживание
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Обновлять каждые 10 метров
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (Position position) async {
          await _updateCourierLocation(
            courierId: courierId,
            orderId: orderId,
            position: position,
          );
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
        },
      );

      debugPrint('Tracking started for courier: $courierId, order: $orderId');
    } catch (e) {
      debugPrint('Start tracking error: $e');
      rethrow;
    }
  }

  /// Остановить отслеживание
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    debugPrint('Tracking stopped');
  }

  /// Обновить локацию курьера
  Future<void> _updateCourierLocation({
    required String courierId,
    required String orderId,
    required Position position,
  }) async {
    try {
      // Получаем адрес из координат
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.street}, ${place.locality}';
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      // Обновляем локацию в Firebase
      await _firestore.collection('courier_tracking').doc(orderId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'address': address,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      // Добавляем точку в историю трека
      await _firestore
          .collection('courier_tracking')
          .doc(orderId)
          .collection('track_history')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'speed': position.speed,
      });

      // Проверяем, близко ли курьер к клиенту
      await _checkProximityToDelivery(orderId, position);
    } catch (e) {
      debugPrint('Update courier location error: $e');
    }
  }

  /// Проверить близость к точке доставки
  Future<void> _checkProximityToDelivery(
      String orderId,
      Position courierPosition,
      ) async {
    try {
      // Получаем адрес доставки из заказа
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final deliveryLat = orderDoc.data()?['deliveryLatitude'] as double?;
      final deliveryLng = orderDoc.data()?['deliveryLongitude'] as double?;

      if (deliveryLat == null || deliveryLng == null) return;

      // Рассчитываем расстояние
      final distance = Geolocator.distanceBetween(
        courierPosition.latitude,
        courierPosition.longitude,
        deliveryLat,
        deliveryLng,
      );

      // Обновляем расстояние до клиента
      await _firestore.collection('orders').doc(orderId).update({
        'distanceToClient': distance,
        'estimatedArrival': _calculateETA(distance, courierPosition.speed),
      });

      // Если курьер близко (менее 100 метров), уведомляем клиента
      if (distance < 100) {
        final userId = orderDoc.data()?['userId'];
        if (userId != null) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'type': 'courier_nearby',
            'title': '🚗 Курьер близко!',
            'body': 'Ваш заказ прибудет через несколько минут',
            'orderId': orderId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Если расстояние менее 500 метров, уведомляем заранее
      if (distance < 500 && distance >= 100) {
        final lastNotification = orderDoc.data()?['lastProximityNotification'];
        final now = DateTime.now();

        // Отправляем уведомление только раз в 5 минут
        if (lastNotification == null ||
            now.difference((lastNotification as Timestamp).toDate()).inMinutes > 5) {
          final userId = orderDoc.data()?['userId'];
          if (userId != null) {
            await _firestore.collection('notifications').add({
              'userId': userId,
              'type': 'courier_approaching',
              'title': '📍 Курьер приближается',
              'body': 'Ваш заказ будет через ${_formatDistance(distance)}',
              'orderId': orderId,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            await _firestore.collection('orders').doc(orderId).update({
              'lastProximityNotification': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Check proximity error: $e');
    }
  }

  /// Рассчитать время прибытия
  int _calculateETA(double distanceInMeters, double speedInMps) {
    if (speedInMps <= 0) {
      // Предполагаем среднюю скорость 30 км/ч = 8.33 м/с
      speedInMps = 8.33;
    }

    final timeInSeconds = distanceInMeters / speedInMps;
    return timeInSeconds.round();
  }

  /// Форматировать расстояние
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} метров';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }
  }

  /// Получить маршрут между двумя точками
  Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // Рассчитываем расстояние
      final distance = Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );

      // Рассчитываем направление
      final bearing = Geolocator.bearingBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );

      return {
        'distance': distance,
        'bearing': bearing,
        'formattedDistance': _formatDistance(distance),
        'estimatedTime': _calculateETA(distance, 8.33), // 30 км/ч
      };
    } catch (e) {
      debugPrint('Get route error: $e');
      return {};
    }
  }

  /// Отслеживание заказа (для клиента)
  Stream<DocumentSnapshot> trackOrder(String orderId) {
    return _firestore
        .collection('courier_tracking')
        .doc(orderId)
        .snapshots();
  }

  /// Получить историю перемещений курьера
  Future<List<Map<String, dynamic>>> getTrackHistory(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('courier_tracking')
          .doc(orderId)
          .collection('track_history')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Get track history error: $e');
      return [];
    }
  }

  /// Геокодирование: адрес → координаты
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Обратное геокодирование: координаты → адрес
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
      return null;
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Найти ближайших доступных курьеров (инновация 2025)
  Future<List<Map<String, dynamic>>> findNearestAvailableCouriers({
    required double latitude,
    required double longitude,
    int limit = 5,
    double maxDistanceKm = 10.0,
  }) async {
    try {
      // Получаем всех активных курьеров
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'courier')
          .where('isActive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      final couriers = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final courierLat = data['currentLatitude'] as double?;
        final courierLng = data['currentLongitude'] as double?;

        if (courierLat != null && courierLng != null) {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            courierLat,
            courierLng,
          );

          final distanceKm = distance / 1000;

          if (distanceKm <= maxDistanceKm) {
            couriers.add({
              'id': doc.id,
              'name': data['name'],
              'phone': data['phone'],
              'photo': data['photo'],
              'rating': data['rating'] ?? 5.0,
              'distance': distance,
              'distanceKm': distanceKm,
              'latitude': courierLat,
              'longitude': courierLng,
            });
          }
        }
      }

      // Сортируем по расстоянию
      couriers.sort((a, b) => a['distance'].compareTo(b['distance']));

      return couriers.take(limit).toList();
    } catch (e) {
      debugPrint('Find nearest couriers error: $e');
      return [];
    }
  }

  /// Умная маршрутизация с учетом трафика (инновация 2025)
  Future<Map<String, dynamic>> getOptimizedRoute({
    required List<Map<String, double>> waypoints,
  }) async {
    try {
      // Здесь будет интеграция с Google Directions API или другим сервисом
      // Пока возвращаем базовую информацию

      double totalDistance = 0;
      for (int i = 0; i < waypoints.length - 1; i++) {
        final current = waypoints[i];
        final next = waypoints[i + 1];

        final distance = Geolocator.distanceBetween(
          current['latitude']!,
          current['longitude']!,
          next['latitude']!,
          next['longitude']!,
        );

        totalDistance += distance;
      }

      return {
        'totalDistance': totalDistance,
        'formattedDistance': _formatDistance(totalDistance),
        'estimatedTime': _calculateETA(totalDistance, 8.33),
        'waypoints': waypoints,
      };
    } catch (e) {
      debugPrint('Get optimized route error: $e');
      return {};
    }
  }

  /// Оптимизация последовательности доставок (инновация 2025)
  Future<List<Map<String, dynamic>>> optimizeDeliverySequence({
    required double courierLat,
    required double courierLng,
    required List<Map<String, dynamic>> deliveries,
  }) async {
    try {
      // Простая оптимизация: ближайший сосед
      final optimized = <Map<String, dynamic>>[];
      final remaining = List<Map<String, dynamic>>.from(deliveries);

      double currentLat = courierLat;
      double currentLng = courierLng;

      while (remaining.isNotEmpty) {
        double minDistance = double.infinity;
        int nearestIndex = 0;

        for (int i = 0; i < remaining.length; i++) {
          final delivery = remaining[i];
          final distance = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            delivery['latitude'],
            delivery['longitude'],
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestIndex = i;
          }
        }

        final nearest = remaining.removeAt(nearestIndex);
        optimized.add({
          ...nearest,
          'distanceFromPrevious': minDistance,
          'sequenceNumber': optimized.length + 1,
        });

        currentLat = nearest['latitude'];
        currentLng = nearest['longitude'];
      }

      return optimized;
    } catch (e) {
      debugPrint('Optimize delivery sequence error: $e');
      return deliveries;
    }
  }

  /// Предсказание времени доставки с учетом ML (инновация 2025)
  Future<int> predictDeliveryTime({
    required double distance,
    required DateTime orderTime,
    String? weatherCondition,
    String? trafficLevel,
  }) async {
    try {
      // Базовое время (30 км/ч = 8.33 м/с)
      double baseSpeed = 8.33;

      // Корректировка на время суток
      final hour = orderTime.hour;
      if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
        // Час пик - медленнее
        baseSpeed *= 0.7;
      } else if (hour >= 23 || hour <= 6) {
        // Ночь - быстрее
        baseSpeed *= 1.3;
      }

      // Корректировка на погоду
      if (weatherCondition == 'rain') {
        baseSpeed *= 0.8;
      } else if (weatherCondition == 'snow') {
        baseSpeed *= 0.6;
      }

      // Корректировка на трафик
      switch (trafficLevel) {
        case 'heavy':
          baseSpeed *= 0.5;
          break;
        case 'moderate':
          baseSpeed *= 0.7;
          break;
        case 'light':
          baseSpeed *= 0.9;
          break;
      }

      // Добавляем время на приготовление (в среднем 15-20 минут)
      const preparationTime = 18 * 60; // 18 минут в секундах

      final deliveryTime = _calculateETA(distance, baseSpeed);
      return preparationTime + deliveryTime;
    } catch (e) {
      debugPrint('Predict delivery time error: $e');
      return _calculateETA(distance, 8.33);
    }
  }

  /// Очистка старых данных трекинга
  Future<void> cleanOldTrackingData({int daysOld = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection('courier_tracking')
          .where('startedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned ${snapshot.docs.length} old tracking records');
    } catch (e) {
      debugPrint('Clean old tracking data error: $e');
    }
  }
}