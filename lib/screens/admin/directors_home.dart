import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_event.dart';
import '../../blocs/auth_state.dart';
import '../../blocs/order_bloc.dart';
import '../../blocs/order_event.dart';
import '../../blocs/order_state.dart';
import '../order/order_details_screen.dart';

class DirectorHome extends StatefulWidget {
  const DirectorHome({super.key});

  @override
  State<DirectorHome> createState() => _DirectorHomeState();
}

class _DirectorHomeState extends State<DirectorHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Yangi', 'Tasdiqlangan', 'Yetkazilmoqda', 'Yakunlangan'];

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
            'Direktor Paneli',
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
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs.map((status) => Tab(text: status)).toList(),
          ),
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial || state is AuthUnauthenticated) {
              // После выхода — переходим на логин
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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderLoaded) {
            final filteredOrders = state.orders
                .where((order) => _mapStatus(order.status) == statusFilter)
                .toList();

            if (filteredOrders.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(order);
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

  Widget _buildOrderCard(dynamic order) {
    final status = _mapStatus(order.status);
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          'Buyurtma #${order.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Mijoz: ${order.customerName ?? 'Noma\'lum'}'),
            Text('Summa: ${order.totalPrice} so\'m'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: _buildActionButton(order, status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(dynamic order, String status) {
    if (status == 'Yangi') {
      return ElevatedButton(
        onPressed: () {
          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'confirmed'));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Tasdiqlash'),
      );
    }
    if (status == 'Tasdiqlangan') {
      return ElevatedButton(
        onPressed: () {
          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'delivering'));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Yetkazish'),
      );
    }
    if (status == 'Yetkazilmoqda') {
      return ElevatedButton(
        onPressed: () {
          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'completed'));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Yakunlash'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Hech qanday buyurtma topilmadi',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Xatolik: $message',
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(const LoadOrders());
            },
            child: const Text('Qayta yuklash'),
          ),
        ],
      ),
    );
  }

  // === ВЫХОД ИЗ АККАУНТА (как в AdminHome) ===
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chiqish'),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ВАЖНО: Используем тот же event, что и в AdminHome
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
      case 'pending':
        return 'Yangi';
      case 'confirmed':
        return 'Tasdiqlangan';
      case 'delivering':
        return 'Yetkazilmoqda';
      case 'completed':
        return 'Yakunlangan';
      default:
        return 'Noma\'lum';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Yangi':
        return Colors.orange;
      case 'Tasdiqlangan':
        return Colors.green;
      case 'Yetkazilmoqda':
        return Colors.blue;
      case 'Yakunlangan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}