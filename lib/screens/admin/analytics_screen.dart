import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitika va Statistika'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportReport(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildPeriodButton('Bugun', 'today')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Bu hafta', 'week')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Bu oy', 'month')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPeriodButton('3 oy', 'quarter')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Bu yil', 'year')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Maxsus', 'custom')),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('timestamp', isGreaterThanOrEqualTo: _getStartDate())
                  .where('timestamp', isLessThanOrEqualTo: _getEndDate())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('Ma\'lumot yo\'q'));
                }

                final orders = snapshot.data!.docs;
                return _buildAnalyticsContent(orders);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = value;
          _updateDateRange(value);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.orange,
        elevation: isSelected ? 4 : 1,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildAnalyticsContent(List<QueryDocumentSnapshot> orders) {
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(
      0,
          (total, doc) => total + ((doc.data() as Map)['totalPrice'] ?? 0.0),
    );
    final completedOrders = orders.where((doc) =>
    (doc.data() as Map)['status'] == 'delivered'
    ).length;
    final cancelledOrders = orders.where((doc) =>
    (doc.data() as Map)['status'] == 'cancelled'
    ).length;
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    final dishFrequency = <String, int>{};
    for (var order in orders) {
      final items = (order.data() as Map)['items'] as List?;
      if (items != null) {
        for (var item in items) {
          final dishName = item['name'] ?? 'Noma\'lum';
          dishFrequency[dishName] = (dishFrequency[dishName] ?? 0) + 1;
        }
      }
    }
    final popularDishes = dishFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Umumiy ko\'rsatkichlar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami buyurtmalar',
                '$totalOrders',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Jami daromad',
                '${totalRevenue.toStringAsFixed(0)} so\'m',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'O\'rtacha buyurtma',
                '${averageOrderValue.toStringAsFixed(0)} so\'m',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Muvaffaqiyat %',
                totalOrders > 0 ? '${((completedOrders / totalOrders) * 100).toStringAsFixed(1)}%' : '0%',
                Icons.check_circle,
                Colors.teal,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Buyurtmalar holati',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusRow('Bajarilgan', completedOrders, Colors.green),
                const Divider(),
                _buildStatusRow('Bekor qilingan', cancelledOrders, Colors.red),
                const Divider(),
                _buildStatusRow('Jarayonda', totalOrders - completedOrders - cancelledOrders, Colors.orange),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Top 10 mashhur taomlar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: popularDishes.take(10).map((entry) {
                final index = popularDishes.indexOf(entry) + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index <= 3 ? Colors.orange : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index <= 3 ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value} ta',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Kunlik daromad',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRevenueByTimeRow('00:00 - 06:00', _calculateRevenueByTime(orders, 0, 6), Colors.blue),
                _buildRevenueByTimeRow('06:00 - 12:00', _calculateRevenueByTime(orders, 6, 12), Colors.green),
                _buildRevenueByTimeRow('12:00 - 18:00', _calculateRevenueByTime(orders, 12, 18), Colors.orange),
                _buildRevenueByTimeRow('18:00 - 24:00', _calculateRevenueByTime(orders, 18, 24), Colors.purple),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByTimeRow(String timeRange, double revenue, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeRange, style: const TextStyle(fontSize: 14)),
              Text(
                '${revenue.toStringAsFixed(0)} so\'m',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: revenue / 10000000,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  double _calculateRevenueByTime(List<QueryDocumentSnapshot> orders, int startHour, int endHour) {
    return orders.where((doc) {
      final timestamp = (doc.data() as Map)['timestamp'] as Timestamp?;
      if (timestamp == null) return false;
      final hour = timestamp.toDate().hour;
      return hour >= startHour && hour < endHour;
    }).fold<double>(
      0,
          (total, doc) => total + ((doc.data() as Map)['totalPrice'] ?? 0.0),
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'quarter':
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'custom':
        _showDateRangePicker();
        break;
    }
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Timestamp _getStartDate() {
    return Timestamp.fromDate(_startDate);
  }

  Timestamp _getEndDate() {
    return Timestamp.fromDate(_endDate.add(const Duration(days: 1)));
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hisobot eksport qilindi'),
        backgroundColor: Colors.green,
      ),
    );
  }
}