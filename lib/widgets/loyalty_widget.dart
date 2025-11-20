// lib/widgets/loyalty_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

/// Виджет отображения программы лояльности
class LoyaltyWidget extends StatelessWidget {
  final String userId;

  const LoyaltyWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final points = data?['points'] ?? 0;
        final totalSpent = data?['totalSpent'] ?? 0.0;
        final totalCashback = data?['totalCashback'] ?? 0.0;

        final level = _getLoyaltyLevel(points);
        final levelData = _getLevelData(level);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Color(levelData['color']),
                  Color(levelData['color']).withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${levelData['icon']} ${levelData['name']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () => _showLoyaltyInfo(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat('Баллы', '$points', Icons.stars),
                    _buildStat('Кэшбэк', '${totalCashback.toStringAsFixed(0)} сум', Icons.account_balance_wallet),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressBar(points, levelData),
                const SizedBox(height: 8),
                Text(
                  'До следующего уровня: ${_pointsToNextLevel(points)} баллов',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int points, Map<String, dynamic> levelData) {
    final maxPoints = levelData['maxPoints'];
    final minPoints = levelData['minPoints'];
    final progress = maxPoints == 999999
        ? 1.0
        : (points - minPoints) / (maxPoints - minPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }

  String _getLoyaltyLevel(int points) {
    if (points < 100) return 'bronze';
    if (points < 500) return 'silver';
    if (points < 1000) return 'gold';
    if (points < 2500) return 'platinum';
    return 'diamond';
  }

  Map<String, dynamic> _getLevelData(String level) {
    const levels = {
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

    return levels[level] ?? levels['bronze']!;
  }

  int _pointsToNextLevel(int points) {
    if (points < 100) return 100 - points;
    if (points < 500) return 500 - points;
    if (points < 1000) return 1000 - points;
    if (points < 2500) return 2500 - points;
    return 0;
  }

  void _showLoyaltyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Программа лояльности'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Уровни:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildLevelInfo('🥉 Бронзовый', '0-99 баллов', '0% скидка, 5% кэшбэк'),
              _buildLevelInfo('🥈 Серебряный', '100-499 баллов', '5% скидка, 7% кэшбэк'),
              _buildLevelInfo('🥇 Золотой', '500-999 баллов', '10% скидка, 10% кэшбэк'),
              _buildLevelInfo('💎 Платиновый', '1000-2499 баллов', '15% скидка, 12% кэшбэк'),
              _buildLevelInfo('💠 Бриллиантовый', '2500+ баллов', '20% скидка, 15% кэшбэк'),
              const SizedBox(height: 16),
              const Text(
                'Как получить баллы:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• 1000 сум = 1 балл'),
              const Text('• Кэшбэк от каждого заказа'),
              const Text('• Бонусы за повышение уровня'),
              const Text('• Достижения и челленджи'),
            ],
          ),
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

  Widget _buildLevelInfo(String name, String points, String benefits) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(points, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(benefits, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
          const Divider(),
        ],
      ),
    );
  }
}