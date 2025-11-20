import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../blocs/cart_bloc.dart';
import '../../blocs/cart_event.dart';
import '../../blocs/cart_state.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart' as order_model;
import 'order_success_screen.dart';
import 'map_address_picker_screen.dart';

class EnhancedCheckoutScreen extends StatefulWidget {
  const EnhancedCheckoutScreen({super.key});

  @override
  State<EnhancedCheckoutScreen> createState() => _EnhancedCheckoutScreenState();
}

class _EnhancedCheckoutScreenState extends State<EnhancedCheckoutScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoCodeController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  String _selectedOrderType = 'delivery'; // delivery, pickup, dine-in
  String _selectedPaymentMethod = 'cash';
  int _tableNumber = 1;
  double _promoDiscount = 0.0;
  bool _isProcessing = false;
  bool _isLoadingUserData = true;
  bool _isLoadingLocation = false;

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;

  // Restaurant coordinates (replace with actual)
  final double _restaurantLat = 41.2995;
  final double _restaurantLng = 69.2401;

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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Joylashuv ruxsati berilmadi', Colors.red);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}';
        setState(() {
          _selectedAddress = address;
          _addressController.text = address;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _showSnackBar('Joylashuvni aniqlab bo\'lmadi: $e', Colors.red);
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapAddressPicker screen(
          initialLat: _selectedLat ?? _restaurantLat,
          initialLng: _selectedLng ?? _restaurantLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLat = result['latitude'];
        _selectedLng = result['longitude'];
        _selectedAddress = result['address'];
        _addressController.text = result['address'];
      });
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

      _showSnackBar(
          'Promo kod qo\'llandi! ${_promoDiscount.toInt()}% chegirma',
          Colors.green);
    } catch (e) {
      _showSnackBar('Xatolik: $e', Colors.red);
    }
  }

  double _calculateDistance() {
    if (_selectedLat == null || _selectedLng == null) return 0;

    return Geolocator.distanceBetween(
          _restaurantLat,
          _restaurantLng,
          _selectedLat!,
          _selectedLng!,
        ) /
        1000; // Convert to km
  }

  double _calculateDeliveryFee() {
    if (_selectedOrderType != 'delivery') return 0;

    final distance = _calculateDistance();
    const baseF ee = 5000.0;
    const perKmFee = 2000.0;

    if (distance <= 2.0) return baseFee;
    return baseFee + ((distance - 2.0) * perKmFee);
  }

  String _getEstimatedTime() {
    switch (_selectedOrderType) {
      case 'delivery':
        final distance = _calculateDistance();
        final minutes = 30 + (distance * 5).round();
        return '$minutes-${minutes + 10} daqiqa';
      case 'pickup':
        return '20-25 daqiqa';
      case 'dine-in':
        return '15-20 daqiqa';
      default:
        return '30-40 daqiqa';
    }
  }

  Future<void> _placeOrder(List<CartItem> cartItems, double subtotal) async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedOrderType == 'delivery' &&
        _addressController.text.trim().isEmpty) {
      _showSnackBar('Iltimos manzilni kiriting', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final deliveryFee = _calculateDeliveryFee();
      final discountAmount = subtotal * (_promoDiscount / 100);
      final totalPrice = subtotal + deliveryFee - discountAmount;

      final orderId =
          FirebaseFirestore.instance.collection('orders').doc().id;

      // Convert CartItems to Map format
      final itemsMap = cartItems
          .map((item) => {
                'dishId': item.dishId,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'imageUrl': item.imageUrl,
              })
          .toList();

      String address;
      if (_selectedOrderType == 'delivery') {
        address = _addressController.text.trim();
      } else if (_selectedOrderType == 'pickup') {
        address = 'Olib ketish (Pickup)';
      } else {
        address = 'Restoranda';
      }

      final order = order_model.Order(
        id: orderId,
        clientId: user.uid,
        items: itemsMap,
        totalPrice: totalPrice,
        status: 'pending',
        address: address,
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
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'promoCode': _promoCodeController.text.trim().isNotEmpty
            ? _promoCodeController.text.trim().toUpperCase()
            : null,
        'discount': discountAmount,
        'deliveryFee': deliveryFee,
        'customerName': user.displayName ?? 'Unknown',
        if (_selectedLat != null) 'deliveryLatitude': _selectedLat,
        if (_selectedLng != null) 'deliveryLongitude': _selectedLng,
        'estimatedTime': _getEstimatedTime(),
        'distance': _calculateDistance(),
      });

      // Clear cart
      if (mounted) {
        context.read<CartBloc>().add(ClearCart());
      }

      setState(() => _isProcessing = false);

      // Navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              orderId: orderId,
              totalAmount: totalPrice,
              estimatedTime: _getEstimatedTime(),
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtmani rasmiylashtirish',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Savat bo\'sh',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final cartItems = state.items;
          final subtotal = cartItems.fold(
              0.0, (sum, item) => sum + (item.price * item.quantity));

          if (_isLoadingUserData) {
            return const Center(child: CircularProgressIndicator());
          }

          final deliveryFee = _calculateDeliveryFee();
          final discountAmount = subtotal * (_promoDiscount / 100);
          final total = subtotal + deliveryFee - discountAmount;

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
                          _buildOrderTypeSelector(),
                          const SizedBox(height: 20),
                          if (_selectedOrderType == 'delivery')
                            _buildDeliverySection(),
                          if (_selectedOrderType == 'dine-in')
                            _buildTableSelector(),
                          const SizedBox(height: 20),
                          _buildContactInfo(),
                          const SizedBox(height: 20),
                          _buildOrderItems(cartItems),
                          const SizedBox(height: 20),
                          _buildPromoCode(),
                          const SizedBox(height: 20),
                          _buildPaymentMethodSelector(),
                          const SizedBox(height: 20),
                          _buildNotes(),
                        ],
                      ),
                    ),
                  ),
                  _buildOrderSummary(subtotal, deliveryFee, discountAmount,
                      total, cartItems),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buyurtma turi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
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
                    'pickup',
                    Icons.shopping_bag,
                    'Olib ketish',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOrderTypeOption(
                    'dine-in',
                    Icons.restaurant,
                    'Joyida',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(String type, IconData icon, String label) {
    final isSelected = _selectedOrderType == type;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedOrderType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? theme.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primaryColor : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yetkazish manzili',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Manzil *',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Iltimos manzilni kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 20),
                    label: const Text('Joriy joylashuv'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickLocationFromMap,
                    icon: const Icon(Icons.map, size: 20),
                    label: const Text('Xaritadan tanlash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedLat != null && _selectedLng != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manzil tanlandi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masofa: ${_calculateDistance().toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.table_restaurant),
            const SizedBox(width: 16),
            const Text('Stol raqami:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aloqa ma\'lumotlari',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon raqami *',
                prefixIcon: Icon(Icons.phone),
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

  Widget _buildOrderItems(List<CartItem> items) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Buyurtma tarkibi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.restaurant, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.restaurant, color: Colors.grey),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promo kod',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _promoCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Promo kodni kiriting',
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromoCode,
                  child: const Text('Qo\'llash'),
                ),
              ],
            ),
            if (_promoDiscount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      '${_promoDiscount.toInt()}% chegirma qo\'llandi!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'To\'lov usuli',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
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
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.primaryColor : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : null,
      onTap: () => setState(() => _selectedPaymentMethod = method),
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Buyurtmaga izoh (ixtiyoriy)',
            prefixIcon: Icon(Icons.note),
            border: InputBorder.none,
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double deliveryFee,
      double discount, double total, List<CartItem> cartItems) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mahsulotlar:'),
                  Text('${subtotal.toStringAsFixed(0)} so\'m'),
                ],
              ),
              if (deliveryFee > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yetkazish:'),
                    Text('${deliveryFee.toStringAsFixed(0)} so\'m'),
                  ],
                ),
              ],
              if (discount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chegirma:'),
                    Text(
                      '-${discount.toStringAsFixed(0)} so\'m',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jami:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} so\'m',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing ? null : () => _placeOrder(cartItems, subtotal),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 12),
                            Text(
                              'Buyurtma berish (${_getEstimatedTime()})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
