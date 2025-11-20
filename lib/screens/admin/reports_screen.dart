import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _reportType = 'sales';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
            tooltip: 'Eksport qilish',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'Boshlanish',
                    _startDate,
                        () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateButton(
                    'Tugash',
                    _endDate,
                        () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTypeChip('Sotuvlar', 'sales', Icons.attach_money),
                _buildTypeChip('Buyurtmalar', 'orders', Icons.shopping_cart),
                _buildTypeChip('Taomlar', 'dishes', Icons.restaurant),
                _buildTypeChip('Mijozlar', 'users', Icons.people),
              ],
            ),
          ),

          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type, IconData icon) {
    final isSelected = _reportType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _reportType = type;
            });
          }
        },
        selectedColor: Colors.orange.shade100,
        checkmarkColor: Colors.orange,
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_reportType) {
      case 'sales':
        return _buildSalesReport();
      case 'orders':
        return _buildOrdersReport();
      case 'dishes':
        return _buildDishesReport();
      case 'users':
        return _buildUsersReport();
      default:
        return const Center(child: Text('Hisobot topilmadi'));
    }
  }

  Widget _buildSalesReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .where('status', isEqualTo: 'delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        double totalSales = 0;
        int totalOrders = orders.length;

        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          totalSales += (data['totalPrice'] ?? 0.0);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(
              'Jami sotuv',
              '${totalSales.toStringAsFixed(0)} so\'m',
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Buyurtmalar soni',
              '$totalOrders ta',
              Icons.shopping_cart,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'O\'rtacha buyurtma',
              '${(totalOrders > 0 ? totalSales / totalOrders : 0).toStringAsFixed(0)} so\'m',
              Icons.trending_up,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sotuv grafigi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _buildSalesChart(orders),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        Map<String, int> statusCounts = {};

        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buyurtmalar holati',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...statusCounts.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_getStatusText(entry.key)),
                            Text(
                              '${entry.value} ta',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDishesReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        Map<String, int> dishCounts = {};

        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];

          for (var item in items) {
            final name = item['name'] ?? 'Unknown';
            final quantity = (item['quantity'] ?? 1) as int; // FIX: явное приведение к int
            dishCounts[name] = (dishCounts[name] ?? 0) + quantity;
          }
        }

        final sortedDishes = dishCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Eng ko\'p sotilgan taomlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedDishes.take(10).map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      '${sortedDishes.indexOf(entry) + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    '${entry.value} ta',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildUsersReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        Map<String, int> roleCounts = {};

        for (var user in users) {
          final data = user.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'client';
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(
              'Jami foydalanuvchilar',
              '${users.length} ta',
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Rollar bo\'yicha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...roleCounts.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_getRoleIcon(entry.key), color: Colors.orange),
                  title: Text(_getRoleText(entry.key)),
                  trailing: Text(
                    '${entry.value} ta',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<QueryDocumentSnapshot> orders) {
    Map<DateTime, double> dailySales = {};

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = DateTime(
          timestamp.toDate().year,
          timestamp.toDate().month,
          timestamp.toDate().day,
        );
        dailySales[date] = (dailySales[date] ?? 0) + (data['totalPrice'] ?? 0.0);
      }
    }

    if (dailySales.isEmpty) {
      return const Center(child: Text('Ma\'lumot yo\'q'));
    }

    final spots = dailySales.entries
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportReport() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eksport funksiyasi tez orada qo\'shiladi'),
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Kutilmoqda';
      case 'confirmed': return 'Tasdiqlandi';
      case 'preparing': return 'Tayyorlanmoqda';
      case 'ready': return 'Tayyor';
      case 'delivered': return 'Yetkazildi';
      case 'cancelled': return 'Bekor qilindi';
      default: return status;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'client': return 'Mijozlar';
      case 'admin': return 'Adminlar';
      case 'waiter': return 'Ofitsiantlar';
      case 'courier': return 'Kuryerlar';
      case 'director': return 'Direktorlar';
      default: return role;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'client': return Icons.person;
      case 'admin': return Icons.admin_panel_settings;
      case 'waiter': return Icons.restaurant;
      case 'courier': return Icons.delivery_dining;
      case 'director': return Icons.business;
      default: return Icons.help;
    }
  }
}