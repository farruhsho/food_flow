import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_event.dart';
import '../../blocs/auth_state.dart';
import '../../blocs/order_bloc.dart';
import '../../blocs/order_event.dart';
import '../../blocs/order_state.dart';
import '../order/order_details_screen.dart';

class DeliverHome extends StatefulWidget {
  const DeliverHome({super.key});

  @override
  State<DeliverHome> createState() => _DeliverHomeState();
}

class _DeliverHomeState extends State<DeliverHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Tayyorlanmoqda', 'Yetkazilmoqda', 'Yakunlangan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => OrderBloc()..add(const LoadOrders())),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Kuryer Paneli',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Chiqish',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial || state is AuthUnauthenticated) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          },
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((status) => _buildOrderList(status)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderBloc>().add(const LoadOrders());
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (state is OrderLoaded) {
            final filteredOrders = state.orders
                .where((order) => _mapStatus(order.status) == statusFilter)
                .toList();

            if (filteredOrders.isEmpty) {
              return _buildEmptyState(statusFilter);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(order, statusFilter);
              },
            );
          }

          if (state is OrderError) {
            return _buildErrorState(state.message);
          }

          return const Center(child: Text('Buyurtmalar yuklanmoqda...'));
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, String status) {
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getStatusIcon(status), color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyurtma #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)} so\'m',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              if (status == 'Tayyorlanmoqda') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'delivering'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yetkazib berish boshlandi'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Boshlash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              if (status == 'Yetkazilmoqda') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteDialog(context, order.id),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Yetkazildi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              if (status == 'Yakunlangan') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Yetkazib berildi',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Yetkazildi'),
          ],
        ),
        content: const Text('Buyurtma muvaffaqiyatli yetkazib berildi deb tasdiqlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(UpdateOrderStatus(orderId, 'delivered'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buyurtma yakunlandi!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Buyurtmalar yo\'q',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '$status bo\'yicha yangi buyurtmalar paydo bo\'lganda bu yerda ko\'rinadi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Xatolik: $message', style: TextStyle(color: Colors.red[700])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<OrderBloc>().add(const LoadOrders()),
            icon: const Icon(Icons.refresh),
            label: const Text('Qayta yuklash'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  // === ВЫХОД ИЗ АККАУНТА ===
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chiqish'),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const SignOutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }

  String _mapStatus(String backendStatus) {
    switch (backendStatus) {
      case 'preparing':
        return 'Tayyorlanmoqda';
      case 'delivering':
        return 'Yetkazilmoqda';
      case 'delivered':
        return 'Yakunlangan';
      default:
        return 'Noma\'lum';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tayyorlanmoqda':
        return Colors.purple;
      case 'Yetkazilmoqda':
        return Colors.teal;
      case 'Yakunlangan':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Tayyorlanmoqda':
        return Icons.restaurant;
      case 'Yetkazilmoqda':
        return Icons.delivery_dining;
      case 'Yakunlangan':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}