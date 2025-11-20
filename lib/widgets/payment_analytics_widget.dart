// lib/widgets/payment_analytics_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentAnalyticsWidget extends StatelessWidget {
  const PaymentAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPaymentAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(analytics),
              const SizedBox(height: 24),
              const Text(
                'Методы оплаты',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodsChart(analytics),
              const SizedBox(height: 24),
              const Text(
                'Динамика платежей',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentTrend(analytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Всего',
            '${analytics['totalAmount'].toStringAsFixed(0)} сум',
            Icons.attach_money,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Успешно',
            '${analytics['successRate'].toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Средний чек',
            '${analytics['averageAmount'].toStringAsFixed(0)} сум',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart(Map<String, dynamic> analytics) {
    final methodAmounts = analytics['methodAmounts'] as Map<String, double>;

    if (methodAmounts.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: methodAmounts.entries.map((entry) {
            final color = _getMethodColor(entry.key);
            return PieChartSectionData(
              value: entry.value,
              title: '${(entry.value / analytics['totalAmount'] * 100).toStringAsFixed(1)}%',
              color: color,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildPaymentTrend(Map<String, dynamic> analytics) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 1),
                const FlSpot(1, 1.5),
                const FlSpot(2, 1.4),
                const FlSpot(3, 2),
                const FlSpot(4, 2.2),
                const FlSpot(5, 1.8),
                const FlSpot(6, 2.5),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'payme':
        return Colors.blue;
      case 'click':
        return Colors.green;
      case 'uzcard':
        return Colors.purple;
      case 'cash':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> _getPaymentAnalytics() async {
    final firestore = FirebaseFirestore.instance;
    final startDate = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await firestore
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    double totalAmount = 0;
    int totalCount = snapshot.docs.length;
    int successfulCount = 0;
    Map<String, double> methodAmounts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0.0) as double;
      final status = data['status'] as String;
      final method = data['method'] as String;

      totalAmount += amount;

      if (status == 'completed' || status == 'success') {
        successfulCount++;
      }

      methodAmounts[method] = (methodAmounts[method] ?? 0) + amount;
    }

    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'successfulCount': successfulCount,
      'successRate': totalCount > 0 ? (successfulCount / totalCount * 100) : 0,
      'averageAmount': totalCount > 0 ? (totalAmount / totalCount) : 0,
      'methodAmounts': methodAmounts,
    };
  }
}