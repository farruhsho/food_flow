import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cart_bloc.dart';
import '../../blocs/cart_event.dart';
import '../../blocs/cart_state.dart';
import '../../blocs/order_bloc.dart';
import '../../blocs/order_event.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cart_item.dart';
import 'package:food_flow/widgets/custom_widgets.dart' as custom;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _addressController = TextEditingController();
  String _deliveryType = 'delivery';
  int? _tableNumber;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myCart),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.primaryColor,
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearCartDialog(context, l10n),
                  tooltip: 'Clear Cart',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const custom.CustomLoadingIndicator();
          }

          if (state is CartError) {
            return Center(
              child: custom.ErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<CartBloc>().add(LoadCart());
                },
              ),
            );
          }

          if (state is CartLoaded) {
            if (state.items.isEmpty) {
              return custom.EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: l10n.emptyCart,
                message: 'Add some delicious items to your cart!',
                buttonText: 'Browse Menu',
                onButtonPressed: () {
                  Navigator.pop(context);
                },
              );
            }

            return FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(
                          state.items[index],
                          l10n,
                          theme,
                        );
                      },
                    ),
                  ),
                  _buildBottomSummary(state, l10n, theme),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCartItem(
      CartItem item,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        context.read<CartBloc>().add(RemoveFromCart(item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    image: item.imageUrl != null
                        ? DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                    gradient: item.imageUrl == null
                        ? LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.3),
                        theme.colorScheme.secondary.withValues(alpha: 0.3),
                      ],
                    )
                        : null,
                  ),
                  child: item.imageUrl == null
                      ? Icon(
                    Icons.restaurant,
                    color: theme.primaryColor,
                    size: 40,
                  )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(0)} so\'m',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: item.quantity > 1
                              ? () {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                item.id,
                                item.quantity - 1,
                              ),
                            );
                          }
                              : null,
                          theme: theme,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                item.id,
                                item.quantity + 1,
                              ),
                            );
                          },
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'so\'m',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: onPressed != null ? theme.primaryColor : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  Widget _buildBottomSummary(
      CartLoaded state,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    final subtotal = state.items.fold<double>(
      0,
          (sum, item) => sum + (item.price * item.quantity),
    );

    final deliveryFee = _deliveryType == 'delivery' ? 10000.0 : 0.0;
    final total = subtotal + deliveryFee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                'Subtotal',
                '${subtotal.toStringAsFixed(0)} so\'m',
                theme,
              ),
              const SizedBox(height: 8),

              _buildSummaryRow(
                'Delivery Fee',
                _deliveryType == 'delivery'
                    ? '${deliveryFee.toStringAsFixed(0)} so\'m'
                    : 'Free',
                theme,
              ),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.total,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} so\'m',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              custom.CustomButton(
                text: l10n.checkout,
                onPressed: () => _showCheckoutBottomSheet(context, l10n, theme),
                icon: Icons.shopping_bag,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  void _showCheckoutBottomSheet(
      BuildContext context,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.checkout,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Delivery Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDeliveryTypeCard(
                      icon: Icons.delivery_dining,
                      title: 'Delivery',
                      isSelected: _deliveryType == 'delivery',
                      onTap: () {
                        setState(() {
                          _deliveryType = 'delivery';
                        });
                        Navigator.pop(context);
                        _showCheckoutBottomSheet(context, l10n, theme);
                      },
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDeliveryTypeCard(
                      icon: Icons.restaurant,
                      title: 'Dine-in',
                      isSelected: _deliveryType == 'dine-in',
                      onTap: () {
                        setState(() {
                          _deliveryType = 'dine-in';
                        });
                        Navigator.pop(context);
                        _showCheckoutBottomSheet(context, l10n, theme);
                      },
                      theme: theme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_deliveryType == 'delivery') ...[
                custom.CustomTextField(
                  controller: _addressController,
                  label: 'Delivery Address',
                  hint: 'Enter your address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
              ] else ...[
                custom.CustomTextField(
                  controller: TextEditingController(
                    text: _tableNumber?.toString() ?? '',
                  ),
                  label: 'Table Number',
                  hint: 'Enter table number',
                  icon: Icons.table_restaurant,
                  keyboardType: TextInputType.number,
                ),
              ],

              const SizedBox(height: 24),

              custom.CustomButton(
                text: 'Place Order',
                onPressed: () {
                  _placeOrder(context);
                },
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    final cartBloc = context.read<CartBloc>();
    final cartState = cartBloc.state;

    if (cartState is! CartLoaded) return;

    if (_deliveryType == 'delivery' && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(
      CreateOrder(
        items: cartState.items.map((item) {
          return {
            'dishId': item.dishId,
            'dishName': item.name,
            'quantity': item.quantity,
            'price': item.price,
          };
        }).toList(),
        totalPrice: cartState.items.fold<double>(
          0,
              (sum, item) => sum + (item.price * item.quantity),
        ),
        address: _deliveryType == 'delivery'
            ? _addressController.text
            : 'Table $_tableNumber',
        orderType: _deliveryType,
        tableNumber: _deliveryType == 'dine-in' ? _tableNumber : null,
      ),
    );

    context.read<CartBloc>().add(ClearCart());
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Order placed successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Clear Cart'),
            ],
          ),
          content: const Text('Are you sure you want to remove all items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CartBloc>().add(ClearCart());
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

}