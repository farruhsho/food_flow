import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  Map<String, dynamic>? _orderData;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _orderSteps = [
    {
      'status': 'pending',
      'title': 'Buyurtma qabul qilindi',
      'subtitle': 'Tizimga kiritilmoqda',
      'icon': Icons.receipt_long,
    },
    {
      'status': 'confirmed',
      'title': 'Tasdiqlandi',
      'subtitle': 'Restoran tomonidan qabul qilindi',
      'icon': Icons.check_circle,
    },
    {
      'status': 'preparing',
      'title': 'Tayyorlanmoqda',
      'subtitle': 'Oshpazlar tayyorlayapti',
      'icon': Icons.restaurant_menu,
    },
    {
      'status': 'ready',
      'title': 'Tayyor',
      'subtitle': 'Yetkazib berish uchun tayyor',
      'icon': Icons.done_all,
    },
    {
      'status': 'delivering',
      'title': 'Yo\'lda',
      'subtitle': 'Kuryer yetkazib bermoqda',
      'icon': Icons.delivery_dining,
    },
    {
      'status': 'delivered',
      'title': 'Yetkazildi',
      'subtitle': 'Buyurtma yetkazib berildi',
      'icon': Icons.check_circle_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _orderSubscription = _firestore
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          setState(() {
            _orderData = snapshot.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Order tracking error: $error');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  int _getCurrentStepIndex() {
    final currentStatus = _orderData?['status'] ?? 'pending';
    return _orderSteps.indexWhere((step) => step['status'] == currentStatus);
  }

  bool _isStepCompleted(int stepIndex) {
    final currentIndex = _getCurrentStepIndex();
    return stepIndex <= currentIndex;
  }

  bool _isStepActive(int stepIndex) {
    return stepIndex == _getCurrentStepIndex();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'delivering':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyurtmani kuzatish',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderData == null
              ? _buildErrorView()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOrderHeader(),
                      _buildTrackingTimeline(),
                      _buildOrderDetails(),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Buyurtma topilmadi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Orqaga qaytish'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final status = _orderData?['status'] ?? 'pending';
    final totalPrice = (_orderData?['totalPrice'] ?? 0).toDouble();
    final timestamp = _orderData?['timestamp'] as Timestamp?;
    final orderDate = timestamp?.toDate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35),
            const Color(0xFFFF6B35).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Buyurtma #${widget.orderId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            orderDate != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(orderDate)
                : '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${totalPrice.toStringAsFixed(0)} so\'m',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buyurtma holati',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(_orderSteps.length, (index) {
            return _buildTimelineStep(index);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(int index) {
    final step = _orderSteps[index];
    final isCompleted = _isStepCompleted(index);
    final isActive = _isStepActive(index);
    final isLast = index == _orderSteps.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFFF6B35)
                    : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                step['icon'],
                color: isCompleted ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 50,
                color: isCompleted ? const Color(0xFFFF6B35) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isCompleted ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['subtitle'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.grey[700] : Colors.grey[500],
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(_orderData?['status'] ?? ''),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Jarayonda...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(_orderData?['status'] ?? ''),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    final items = _orderData?['items'] as List<dynamic>? ?? [];
    final address = _orderData?['address'] ?? 'Manzil ko\'rsatilmagan';
    final phone = _orderData?['userPhone'] ?? '';
    final notes = _orderData?['notes'];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Buyurtma tafsilotlari',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  icon: Icons.location_on,
                  label: 'Yetkazish manzili',
                  value: address,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.phone,
                    label: 'Telefon',
                    value: phone,
                  ),
                ],
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.note,
                    label: 'Izoh',
                    value: notes.toString(),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Buyurtma tarkibi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) => _buildOrderItem(item)).toList(),
              ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
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

  Widget _buildOrderItem(dynamic item) {
    final name = item['name'] ?? '';
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name x$quantity',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${(price * quantity).toStringAsFixed(0)} so\'m',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _orderData?['status'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (status != 'delivered' && status != 'cancelled')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Call support or restaurant
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.phone),
                label: const Text(
                  'Restoran bilan bog\'lanish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.home),
              label: const Text(
                'Bosh sahifaga qaytish',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
