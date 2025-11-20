// lib/screens/order/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Экран отслеживания заказа с картой в реальном времени
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _trackingSubscription;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  LatLng? _courierLocation;
  LatLng? _deliveryLocation;
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _trackingData;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _orderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      // Слушаем изменения заказа
      _orderSubscription = _firestore
          .collection('orders')
          .doc(widget.orderId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _orderData = snapshot.data();
            final lat = _orderData?['deliveryLatitude'] as double?;
            final lng = _orderData?['deliveryLongitude'] as double?;

            if (lat != null && lng != null) {
              _deliveryLocation = LatLng(lat, lng);
              _updateMarkers();
            }
          });
        }
      });

      // Слушаем изменения местоположения курьера
      _trackingSubscription = _firestore
          .collection('courier_tracking')
          .doc(widget.orderId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _trackingData = snapshot.data();
            final lat = _trackingData?['latitude'] as double?;
            final lng = _trackingData?['longitude'] as double?;

            if (lat != null && lng != null) {
              _courierLocation = LatLng(lat, lng);
              _updateMarkers();
              _updatePolyline();
              _animateCamera();
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      debugPrint('Initialize tracking error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Маркер курьера
    if (_courierLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('courier'),
          position: _courierLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '🚗 Курьер',
            snippet: _trackingData?['address'] ?? 'В пути',
          ),
          rotation: _trackingData?['heading'] ?? 0,
        ),
      );
    }

    // Маркер точки доставки
    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '📍 Адрес доставки',
            snippet: _orderData?['deliveryAddress'] ?? '',
          ),
        ),
      );
    }
  }

  void _updatePolyline() {
    if (_courierLocation != null && _deliveryLocation != null) {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_courierLocation!, _deliveryLocation!],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
  }

  void _animateCamera() {
    if (_courierLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_courierLocation!),
      );
    }
  }

  void _fitBounds() {
    if (_courierLocation != null &&
        _deliveryLocation != null &&
        _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _courierLocation!.latitude < _deliveryLocation!.latitude
              ? _courierLocation!.latitude
              : _deliveryLocation!.latitude,
          _courierLocation!.longitude < _deliveryLocation!.longitude
              ? _courierLocation!.longitude
              : _deliveryLocation!.longitude,
        ),
        northeast: LatLng(
          _courierLocation!.latitude > _deliveryLocation!.latitude
              ? _courierLocation!.latitude
              : _deliveryLocation!.latitude,
          _courierLocation!.longitude > _deliveryLocation!.longitude
              ? _courierLocation!.longitude
              : _deliveryLocation!.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null) return 'Рассчитывается...';
    if (meters < 1000) {
      return '${meters.round()} м';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }
  }

  String _formatETA(int? seconds) {
    if (seconds == null) return 'Рассчитывается...';
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours ч $remainingMinutes мин';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание заказа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitBounds,
            tooltip: 'Показать весь маршрут',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Информационная панель
          _buildInfoPanel(),

          // Карта
          Expanded(
            child: _buildMap(),
          ),

          // Детали заказа
          _buildOrderDetails(),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    final distanceToClient = _orderData?['distanceToClient'] as double?;
    final estimatedArrival = _orderData?['estimatedArrival'] as int?;
    final orderStatus = _orderData?['status'] ?? 'processing';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.delivery_dining,
                label: 'Расстояние',
                value: _formatDistance(distanceToClient),
                color: Colors.blue,
              ),
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'Прибытие через',
                value: _formatETA(estimatedArrival),
                color: Colors.orange,
              ),
              _buildInfoItem(
                icon: Icons.speed,
                label: 'Скорость',
                value: '${(_trackingData?['speed'] ?? 0).toStringAsFixed(0)} м/с',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusChip(orderStatus),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final statusData = _getStatusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusData['color']),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusData['icon'], size: 18, color: statusData['color']),
          const SizedBox(width: 8),
          Text(
            statusData['text'],
            style: TextStyle(
              color: statusData['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'pending':
        return {
          'text': 'Ожидание',
          'icon': Icons.hourglass_empty,
          'color': Colors.orange,
        };
      case 'confirmed':
        return {
          'text': 'Подтвержден',
          'icon': Icons.check_circle_outline,
          'color': Colors.blue,
        };
      case 'preparing':
        return {
          'text': 'Готовится',
          'icon': Icons.restaurant,
          'color': Colors.purple,
        };
      case 'ready':
        return {
          'text': 'Готов',
          'icon': Icons.done_all,
          'color': Colors.green,
        };
      case 'delivering':
        return {
          'text': 'В пути',
          'icon': Icons.delivery_dining,
          'color': Colors.blue,
        };
      case 'delivered':
        return {
          'text': 'Доставлен',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      default:
        return {
          'text': 'Обработка',
          'icon': Icons.sync,
          'color': Colors.grey,
        };
    }
  }

  Widget _buildMap() {
    final initialPosition = _courierLocation ?? _deliveryLocation;

    if (initialPosition == null) {
      return const Center(
        child: Text('Ожидание данных о местоположении...'),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        Future.delayed(const Duration(milliseconds: 500), _fitBounds);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Заказ #${widget.orderId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Адрес доставки',
            value: _orderData?['deliveryAddress'] ?? 'Не указан',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.person,
            label: 'Курьер',
            value: _trackingData?['courierName'] ?? 'Назначается...',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Телефон курьера',
            value: _trackingData?['courierPhone'] ?? 'Не указан',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Позвонить курьеру
              },
              icon: const Icon(Icons.phone),
              label: const Text('Позвонить курьеру'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}