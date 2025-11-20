import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/cart_bloc.dart';
import '../../blocs/cart_event.dart';
import '../../blocs/cart_state.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart' as order_model;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoCodeController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedOrderType = 'delivery'; // delivery or dine-in
  String _selectedPaymentMethod = 'cash'; // cash, card, payme, click, uzcard
  int _tableNumber = 1;
  double _promoDiscount = 0.0;
  bool _isProcessing = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          setState(() {
            _addressController.text = userData?['address'] ?? '';
            _phoneController.text = userData?['phone'] ?? '';
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Iltimos promo kod kiriting', Colors.orange);
      return;
    }

    try {
      final promoDoc = await FirebaseFirestore.instance
          .collection('promo_codes')
          .doc(code.toUpperCase())
          .get();

      if (!promoDoc.exists) {
        _showSnackBar('Promo kod topilmadi', Colors.red);
        return;
      }

      final promoData = promoDoc.data();
      if (promoData?['isActive'] != true) {
        _showSnackBar('Promo kod faol emas', Colors.red);
        return;
      }

      final expiryDate = (promoData?['expiryDate'] as Timestamp?)?.toDate();
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        _showSnackBar('Promo kod muddati tugagan', Colors.red);
        return;
      }

      setState(() {
        _promoDiscount = (promoData?['discount'] ?? 0).toDouble();
      });

      _showSnackBar('Promo kod qo\'llandi! ${_promoDiscount.toInt()}% chegirma', Colors.green);
    } catch (e) {
      _showSnackBar('Xatolik: $e', Colors.red);
    }
  }

  Future<void> _placeOrder(List<CartItem> cartItems, double subtotal) async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedOrderType == 'delivery' && _addressController.text.trim().isEmpty) {
      _showSnackBar('Iltimos manzilni kiriting', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final deliveryFee = _selectedOrderType == 'delivery' ? 10000.0 : 0.0;
      final discountAmount = subtotal * (_promoDiscount / 100);
      final totalPrice = subtotal + deliveryFee - discountAmount;

      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

      // Convert CartItems to Map format
      final itemsMap = cartItems.map((item) => {
        'dishId': item.dishId,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrl': item.imageUrl,
      }).toList();

      final order = order_model.Order(
        id: orderId,
        clientId: user.uid,
        items: itemsMap,
        totalPrice: totalPrice,
        status: 'pending',
        address: _selectedOrderType == 'delivery' ? _addressController.text.trim() : 'Restoranda',
        orderType: _selectedOrderType,
        tableNumber: _selectedOrderType == 'dine-in' ? _tableNumber : null,
        timestamp: Timestamp.now(),
      );

      // Save order to Firestore with additional fields
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set({
        ...order.toFirestore(),
        'paymentMethod': _selectedPaymentMethod,
        'userPhone': _phoneController.text.trim(),
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'promoCode': _promoCodeController.text.trim().isNotEmpty ? _promoCodeController.text.trim().toUpperCase() : null,
        'discount': discountAmount,
        'deliveryFee': deliveryFee,
        'customerName': user.displayName ?? 'Unknown',
      });

      // Clear cart
      if (mounted) {
        context.read<CartBloc>().add(ClearCart());
      }

      setState(() => _isProcessing = false);

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(orderId);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Xatolik: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Buyurtma qabul qilindi!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Buyurtma #${orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buyurtmangiz qabul qilindi va tez orada tayyorlanadi',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lovni tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Savat bo\'sh', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = state.items;
          final subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

          if (_isLoadingUserData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Type Selection
                          _buildSectionTitle('Buyurtma turi'),
                          _buildOrderTypeSelector(),
                          const SizedBox(height: 24),

                          // Delivery Details (if delivery)
                          if (_selectedOrderType == 'delivery') ...[
                            _buildSectionTitle('Yetkazib berish ma\'lumotlari'),
                            _buildDeliveryDetails(),
                            const SizedBox(height: 24),
                          ],

                          // Table Selection (if dine-in)
                          if (_selectedOrderType == 'dine-in') ...[
                            _buildSectionTitle('Stol tanlash'),
                            _buildTableSelector(),
                            const SizedBox(height: 24),
                          ],

                          // Order Items
                          _buildSectionTitle('Buyurtma tarkibi'),
                          _buildOrderItems(cartItems),
                          const SizedBox(height: 24),

                          // Payment Method
                          _buildSectionTitle('To\'lov usuli'),
                          _buildPaymentMethodSelector(),
                          const SizedBox(height: 24),

                          // Promo Code
                          _buildSectionTitle('Promo kod'),
                          _buildPromoCodeInput(),
                          const SizedBox(height: 24),

                          // Additional Notes
                          _buildSectionTitle('Qo\'shimcha izoh (ixtiyoriy)'),
                          _buildNotesField(),
                          const SizedBox(height: 24),

                          // Price Summary
                          _buildPriceSummary(subtotal),
                        ],
                      ),
                    ),
                  ),

                  // Place Order Button
                  _buildPlaceOrderButton(cartItems, subtotal),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B35),
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _buildOrderTypeOption(
                'delivery',
                Icons.delivery_dining,
                'Yetkazib berish',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderTypeOption(
                'dine-in',
                Icons.restaurant,
                'Restoranda',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(String type, IconData icon, String label) {
    final isSelected = _selectedOrderType == type;
    return InkWell(
      onTap: () => setState(() => _selectedOrderType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35).withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Manzil *',
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF6B35)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
              validator: (value) {
                if (_selectedOrderType == 'delivery' && (value == null || value.isEmpty)) {
                  return 'Iltimos manzilni kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon raqami *',
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF6B35)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Iltimos telefon raqamini kiriting';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.table_restaurant, color: Color(0xFFFF6B35)),
            const SizedBox(width: 16),
            const Text('Stol raqami:', style: TextStyle(fontSize: 16)),
            const Spacer(),
            DropdownButton<int>(
              value: _tableNumber,
              items: List.generate(20, (index) => index + 1)
                  .map((num) => DropdownMenuItem(
                        value: num,
                        child: Text('Stol $num'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _tableNumber = value ?? 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(List<CartItem> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${item.quantity} x ${item.price.toStringAsFixed(0)} so\'m',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${(item.price * item.quantity).toStringAsFixed(0)} so\'m',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildPaymentOption('cash', Icons.money, 'Naqd pul'),
          const Divider(height: 1),
          _buildPaymentOption('card', Icons.credit_card, 'Plastik karta'),
          const Divider(height: 1),
          _buildPaymentOption('payme', Icons.payment, 'Payme'),
          const Divider(height: 1),
          _buildPaymentOption('click', Icons.payment, 'Click'),
          const Divider(height: 1),
          _buildPaymentOption('uzcard', Icons.payment, 'Uzcard'),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == method;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFFF6B35) : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFFFF6B35) : Colors.black,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFFFF6B35))
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () => setState(() => _selectedPaymentMethod = method),
    );
  }

  Widget _buildPromoCodeInput() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCodeController,
                decoration: InputDecoration(
                  hintText: 'Promo kodni kiriting',
                  prefixIcon: const Icon(Icons.discount, color: Color(0xFFFF6B35)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _applyPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Qo\'llash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Buyurtma haqida izoh...',
            prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B35)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildPriceSummary(double subtotal) {
    final deliveryFee = _selectedOrderType == 'delivery' ? 10000.0 : 0.0;
    final discountAmount = subtotal * (_promoDiscount / 100);
    final total = subtotal + deliveryFee - discountAmount;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Oraliq summa', subtotal),
            const SizedBox(height: 8),
            if (_selectedOrderType == 'delivery')
              _buildPriceRow('Yetkazib berish', deliveryFee),
            if (_promoDiscount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Chegirma (${_promoDiscount.toInt()}%)', -discountAmount, color: Colors.green),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jami:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${total.toStringAsFixed(0)} so\'m',
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

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: color ?? Colors.grey[700])),
        Text(
          '${amount.toStringAsFixed(0)} so\'m',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? Colors.black),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(List<CartItem> cartItems, double subtotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _placeOrder(cartItems, subtotal),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Buyurtmani tasdiqlash',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
