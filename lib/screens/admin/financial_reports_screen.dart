import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moliyaviy hisobotlar'),
        backgroundColor: Colors.orange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'today', child: Text('Bugun')),
              const PopupMenuItem(value: 'week', child: Text('Hafta')),
              const PopupMenuItem(value: 'month', child: Text('Oy')),
              const PopupMenuItem(value: 'year', child: Text('Yil')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Ma\'lumotlar mavjud emas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;
          final stats = _calculateStatistics(orders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildSummaryCards(stats),
                const SizedBox(height: 20),
                _buildRevenueChart(stats),
                const SizedBox(height: 20),
                _buildOrdersList(orders),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPeriodButton('Bugun', 'today'),
            _buildPeriodButton('Hafta', 'week'),
            _buildPeriodButton('Oy', 'month'),
            _buildPeriodButton('Yil', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPeriod = period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Umumiy sotildi',
                '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(stats['totalRevenue'])} so\'m',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Buyurtmalar',
                stats['totalOrders'].toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'O\'rtacha chek',
                '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(stats['averageOrder'])} so\'m',
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bajarilgan',
                stats['completedOrders'].toString(),
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daromad grafigi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text(
                'Grafik uchun ma\'lumotlar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> orders) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'So\'nggi buyurtmalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${orders.length} ta',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length > 10 ? 10 : orders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order['status']),
                  child: const Icon(Icons.receipt, color: Colors.white),
                ),
                title: Text('Buyurtma #${order['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                subtitle: Text(
                  _formatTimestamp(order['createdAt']),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(order['totalAmount'] ?? 0)} so\'m',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case 'week':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case 'year':
        startDate = DateTime(endDate.year, 1, 1);
        break;
      default:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
    }

    return _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Map<String, dynamic> _calculateStatistics(List<QueryDocumentSnapshot> orders) {
    double totalRevenue = 0;
    int completedOrders = 0;

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final amount = (data['totalAmount'] ?? 0).toDouble();
      totalRevenue += amount;

      if (data['status'] == 'completed') {
        completedOrders++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': orders.length,
      'completedOrders': completedOrders,
      'averageOrder': orders.isEmpty ? 0 : totalRevenue / orders.length,
    };
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}