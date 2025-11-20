import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CourierLiveTrackingScreen extends StatefulWidget {
  final String orderId;
  final String deliveryAddress;
  final double? destinationLat;
  final double? destinationLng;

  const CourierLiveTrackingScreen({
    super.key,
    required this.orderId,
    required this.deliveryAddress,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  State<CourierLiveTrackingScreen> createState() => _CourierLiveTrackingScreenState();
}

class _CourierLiveTrackingScreenState extends State<CourierLiveTrackingScreen> {
  String _status = 'picked_up';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetkazib berish'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>?;
          if (orderData == null) {
            return const Center(child: Text('Buyurtma topilmadi'));
          }

          final status = orderData['status'] ?? 'pending';

          return Column(
            children: [
              // Map placeholder
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey.shade200,
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 100,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.deliveryAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _openInMaps,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.navigation),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Order info
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status selector
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buyurtma holati',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatusButton(
                                'picked_up',
                                'Olib ketildi',
                                Icons.shopping_bag,
                                Colors.blue,
                                status,
                              ),
                              const SizedBox(height: 8),
                              _buildStatusButton(
                                'on_the_way',
                                'Yo\'lda',
                                Icons.delivery_dining,
                                Colors.orange,
                                status,
                              ),
                              const SizedBox(height: 8),
                              _buildStatusButton(
                                'delivered',
                                'Yetkazildi',
                                Icons.check_circle,
                                Colors.green,
                                status,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order details
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buyurtma tafsilotlari',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Buyurtma ID',
                                widget.orderId.substring(0, 8),
                              ),
                              _buildDetailRow(
                                'Manzil',
                                widget.deliveryAddress,
                              ),
                              _buildDetailRow(
                                'Summa',
                                '${orderData['totalPrice']?.toStringAsFixed(0) ?? '0'} so\'m',
                              ),
                              _buildDetailRow(
                                'To\'lov',
                                orderData['paymentMethod'] ?? 'Naqd',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _callCustomer(orderData['userPhone']),
                              icon: const Icon(Icons.phone),
                              label: const Text('Qo\'ng\'iroq qilish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openInMaps,
                              icon: const Icon(Icons.map),
                              label: const Text('Yo\'lni ko\'rish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (status == 'delivered') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.done_all),
                            label: const Text('Yakunlash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(
      String statusValue,
      String label,
      IconData icon,
      Color color,
      String currentStatus,
      ) {
    final isActive = currentStatus == statusValue;

    return InkWell(
      onTap: () => _updateStatus(statusValue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : Colors.grey.shade700,
                ),
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Holat yangilandi: ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'picked_up':
        return 'Olib ketildi';
      case 'on_the_way':
        return 'Yo\'lda';
      case 'delivered':
        return 'Yetkazildi';
      default:
        return status;
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon raqami topilmadi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon dasturini ochib bo\'lmadi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    // Tashkent coordinates as default
    final lat = widget.destinationLat ?? 41.2995;
    final lng = widget.destinationLng ?? 69.2401;

    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
    );

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xarita dasturini ochib bo\'lmadi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}