import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;
  String _status = 'pending'; // pending, processing, success, failed

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _status = 'processing';
    });

    try {
      String? transactionId;

      switch (widget.paymentMethod.toLowerCase()) {
        case 'payme':
          transactionId = await _paymentService.processPaymePayment(
            widget.orderId,
            widget.amount,
          );
          break;
        case 'click':
          transactionId = await _paymentService.processClickPayment(
            widget.orderId,
            widget.amount,
          );
          break;
        case 'uzcard':
          transactionId = await _paymentService.processUzcardPayment(
            widget.orderId,
            widget.amount,
          );
          break;
        case 'card':
        case 'cash':
        default:
          // For cash/card, just mark as paid
          transactionId = 'CASH_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';
          await Future.delayed(const Duration(seconds: 1)); // Simulate processing
          break;
      }

      if (transactionId != null) {
        // Update order status
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'paymentStatus': 'paid',
          'transactionId': transactionId,
          'paidAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _status = 'success';
          _isProcessing = false;
        });

        // Navigate back after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('To\'lov amalga oshmadi');
      }
    } catch (e) {
      setState(() {
        _status = 'failed';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lov', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: _buildStatusIcon(),
            ),
            const SizedBox(height: 32),
            Text(
              _getStatusTitle(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildAmountCard(),
            const SizedBox(height: 32),
            if (_status == 'pending') _buildPaymentButton(),
            if (_status == 'failed') _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (_status) {
      case 'processing':
        return const SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        );
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.payment;
        color = const Color(0xFFFF6B35);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 60, color: color),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'processing':
        return 'To\'lov amalga oshirilmoqda...';
      case 'success':
        return 'To\'lov muvaffaqiyatli!';
      case 'failed':
        return 'To\'lov amalga oshmadi';
      default:
        return 'To\'lovni tasdiqlang';
    }
  }

  String _getStatusMessage() {
    switch (_status) {
      case 'processing':
        return 'Iltimos kuting...';
      case 'success':
        return 'Buyurtmangiz muvaffaqiyatli to\'landi';
      case 'failed':
        return 'Iltimos qayta urinib ko\'ring';
      default:
        return 'Quyidagi tugmani bosing';
    }
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'To\'lov usuli:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  _getPaymentMethodName(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Summa:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.amount.toStringAsFixed(0)} so\'m',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: const Text(
          'To\'lovni amalga oshirish',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Qayta urinish',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getPaymentMethodName() {
    switch (widget.paymentMethod.toLowerCase()) {
      case 'payme':
        return 'Payme';
      case 'click':
        return 'Click';
      case 'uzcard':
        return 'Uzcard';
      case 'card':
        return 'Plastik karta';
      case 'cash':
      default:
        return 'Naqd pul';
    }
  }
}
