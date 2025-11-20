import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_event.dart';
import '../../blocs/order_bloc.dart';
import '../../blocs/order_event.dart';
import '../../blocs/order_state.dart';
import '../../blocs/menu_bloc.dart';
import '../../blocs/menu_event.dart';
import 'add_dish_screen.dart';
import 'analytics_screen.dart';
import 'menu_management_screen.dart';
import 'categories_promotions_screens.dart';
import 'tables_management_screen.dart';
import 'financial_reports_screen.dart' as financial;
import '../order/order_details_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load data when screen is built
    context.read<OrderBloc>().add(const LoadOrders());
    context.read<MenuBloc>().add(LoadMenu());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        bottom: _selectedIndex == 0
            ? TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Buyurtmalar'),
            Tab(text: 'Statistika'),
            Tab(text: 'Tezkor'),
          ],
        )
            : null,
      ),
      drawer: _buildDrawer(context),
      body: _selectedIndex == 0 ? _buildMainContent() : _buildMenuManagement(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDishScreen()),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Taom qo\'shish'),
      )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade400, Colors.orange.shade50],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.deepOrange.shade700],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.orange),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tizim boshqaruvi',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Bosh sahifa', 0),
            _buildDrawerItem(Icons.restaurant_menu, 'Menyu boshqaruvi', 1),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
              title: const Text('Menyu boshqaruvi'),
              subtitle: const Text('HOT, chegirmalar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.orange),
              title: const Text('Analitika'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: const Text('Kategoriyalar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.orange),
              title: const Text('Aksiyalar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromotionsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_restaurant, color: Colors.orange),
              title: const Text('Stollar boshqaruvi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TablesManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
              title: const Text('Moliyaviy hisobotlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const financial.FinancialReportsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.orange),
              title: const Text('Sozlamalar'),
              onTap: () {
                Navigator.pop(context);
                // Settings screen navigation removed as file doesn't exist
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sozlamalar sahifasi ishlab chiqilmoqda')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Chiqish', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      )
          : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.black87,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrdersTab(),
        _buildStatisticsTab(),
        _buildQuickActionsTab(),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderLoaded) {
          if (state.orders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.receipt_long,
              title: 'Buyurtmalar yo\'q',
              subtitle: 'Hozircha hech qanday buyurtma yo\'q',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<OrderBloc>().add(const LoadOrders());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _buildOrderCard(order);
              },
            ),
          );
        }

        if (state is OrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrderBloc>().add(const LoadOrders());
                  },
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatisticsTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoaded) {
          final totalOrders = state.orders.length;
          final pendingOrders = state.orders.where((o) => o.status == 'pending').length;
          final completedOrders = state.orders.where((o) => o.status == 'delivered').length;
          final totalRevenue = state.orders
              .where((o) => o.status == 'delivered')
              .fold<double>(0, (sum, order) => sum + order.totalAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Jami buyurtmalar',
                        totalOrders.toString(),
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Kutilmoqda',
                        pendingOrders.toString(),
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Bajarildi',
                        completedOrders.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Daromad',
                        '${totalRevenue.toStringAsFixed(0)} so\'m',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildQuickActionsTab() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildQuickActionCard(
          'Taom qo\'shish',
          Icons.add_circle,
          Colors.orange,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDishScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          'Analitika',
          Icons.analytics,
          Colors.blue,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          'Kategoriyalar',
          Icons.category,
          Colors.purple,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          'Aksiyalar',
          Icons.local_offer,
          Colors.green,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromotionsScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          'Hisobotlar',
          Icons.account_balance_wallet,
          Colors.teal,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const financial.FinancialReportsScreen()),
            );
          },
        ),
        _buildQuickActionCard(
          'Stollar',
          Icons.table_restaurant,
          Colors.indigo,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TablesManagementScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyurtma #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order.totalAmount.toStringAsFixed(0)} so\'m',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${order.items.length} ta taom',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'accepted'));
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Qabul qilish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (order.status == 'pending') const SizedBox(width: 8),
                  if (order.status == 'pending' || order.status == 'accepted')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelOrderDialog(context, order.id),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Bekor qilish'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  if (order.status == 'accepted')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAssignCourierDialog(context, order.id),
                        icon: const Icon(Icons.delivery_dining, size: 18),
                        label: const Text('Kuryer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (order.status == 'preparing' || order.status == 'delivering')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showChangeStatusDialog(context, order.id, order.status),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Keyingi bosqich'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuManagement() {
    return const MenuManagementScreen();
  }

  Widget _buildStatisticCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buyurtmani bekor qilish'),
        content: const Text('Ushbu buyurtmani bekor qilmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(UpdateOrderStatus(orderId, 'cancelled'));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(BuildContext context, String orderId, String currentStatus) {
    String nextStatus;
    if (currentStatus == 'preparing') {
      nextStatus = 'delivering';
    } else if (currentStatus == 'delivering') {
      nextStatus = 'delivered';
    } else {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Holatni o\'zgartirish'),
        content: Text('Buyurtma holatini "${_getStatusText(nextStatus)}" ga o\'zgartirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(UpdateOrderStatus(orderId, nextStatus));
              Navigator.pop(dialogContext);
            },
            child: const Text('O\'zgartirish'),
          ),
        ],
      ),
    );
  }

  void _showAssignCourierDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Colors.orange),
            SizedBox(width: 12),
            Text('Kuryer tayinlash'),
          ],
        ),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'courier')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final couriers = snapshot.data!.docs;

            if (couriers.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Faol kuryerlar yo\'q',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: couriers.length,
                itemBuilder: (context, index) {
                  final courierData = couriers[index].data() as Map<String, dynamic>;
                  final courierId = couriers[index].id;
                  final name = courierData['name'] ?? 'Noma\'lum';
                  final email = courierData['email'] ?? '';
                  final phone = courierData['phone'] ?? '';
                  final points = courierData['points'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.withValues(alpha: 0.2),
                        child: const Icon(Icons.delivery_dining, color: Colors.teal),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (phone.isNotEmpty) Text('📞 $phone'),
                          if (email.isNotEmpty) Text('📧 $email', style: const TextStyle(fontSize: 11)),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('$points ball', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
                      onTap: () {
                        context.read<OrderBloc>().add(AssignCourier(orderId, courierId));
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name kuryerga tayinlandi'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirishnomalar'),
        content: const Text('Yangi bildirishnomalar yo\'q'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Tizimdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(const SignOutRequested());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ha, chiqish'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'delivering': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.check_circle_outline;
      case 'preparing': return Icons.restaurant;
      case 'delivering': return Icons.delivery_dining;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Kutilmoqda';
      case 'accepted': return 'Qabul qilindi';
      case 'preparing': return 'Tayyorlanmoqda';
      case 'delivering': return 'Yetkazilmoqda';
      case 'delivered': return 'Yetkazildi';
      case 'cancelled': return 'Bekor qilindi';
      default: return 'Noma\'lum';
    }
  }
}