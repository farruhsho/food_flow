// lib/screens/payment/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String userId;

  const PaymentHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История платежей'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(child: _buildPaymentsList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPaymentsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final summary = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Статистика платежей',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      'Всего',
                      '${summary['total']}',
                      Icons.receipt,
                      Colors.blue,
                    ),
                    _buildSummaryStat(
                      'Успешно',
                      '${summary['successful']}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildSummaryStat(
                      'Сумма',
                      '${summary['totalAmount'].toStringAsFixed(0)} сум',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPaymentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPaymentsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!.docs;

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Нет платежей',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final doc = payments[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPaymentItem(doc.id, data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getPaymentsStream() {
    var query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true);

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.limit(100).snapshots();
  }

  Widget _buildPaymentItem(String id, Map<String, dynamic> data) {
    final amount = data['amount'] ?? 0.0;
    final method = data['method'] ?? 'unknown';
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;

    final statusData = _getStatusData(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusData['color'].withValues(alpha: 0.2),
          child: Icon(statusData['icon'], color: statusData['color']),
        ),
        title: Text(
          '${amount.toStringAsFixed(0)} сум',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_getMethodName(method)),
            if (createdAt != null)
              Text(DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusData['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusData['text'],
            style: TextStyle(
              color: statusData['color'],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showPaymentDetails(id, data),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'completed':
      case 'success':
        return {
          'text': 'Успешно',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case 'pending':
        return {
          'text': 'В обработке',
          'icon': Icons.hourglass_empty,
          'color': Colors.orange,
        };
      case 'failed':
      case 'cancelled':
        return {
          'text': 'Отменен',
          'icon': Icons.cancel,
          'color': Colors.red,
        };
      default:
        return {
          'text': status,
          'icon': Icons.info,
          'color': Colors.grey,
        };
    }
  }

  String _getMethodName(String method) {
    switch (method) {
      case 'payme':
        return 'Payme';
      case 'click':
        return 'Click';
      case 'uzcard':
        return 'Uzcard';
      case 'cash':
        return 'Наличные';
      default:
        return method;
    }
  }

  Future<Map<String, dynamic>> _getPaymentsSummary() async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: widget.userId)
        .get();

    int total = snapshot.docs.length;
    int successful = 0;
    double totalAmount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      if (status == 'completed' || status == 'success') {
        successful++;
        totalAmount += (data['amount'] ?? 0.0);
      }
    }

    return {
      'total': total,
      'successful': successful,
      'totalAmount': totalAmount,
    };
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Все'),
              value: 'all',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Успешные'),
              value: 'completed',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('В обработке'),
              value: 'pending',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Отмененные'),
              value: 'failed',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали платежа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', id.substring(0, 8).toUpperCase()),
            _buildDetailRow('Сумма', '${data['amount']} сум'),
            _buildDetailRow('Метод', _getMethodName(data['method'])),
            _buildDetailRow('Статус', _getStatusData(data['status'])['text']),
            if (data['orderId'] != null)
              _buildDetailRow('Заказ', data['orderId'].substring(0, 8)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}