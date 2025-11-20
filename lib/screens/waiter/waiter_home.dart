import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_event.dart';
import '../../blocs/order_bloc.dart';
import '../../blocs/order_event.dart';
import '../../blocs/order_state.dart';
import '../../models/table_booking.dart';
import '../order/order_details_screen.dart';

class WaiterHome extends StatefulWidget {
  const WaiterHome({super.key});

  @override
  State<WaiterHome> createState() => _WaiterHomeState();
}

class _WaiterHomeState extends State<WaiterHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc()..add(const LoadOrders()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ofitsant Panel'),
          backgroundColor: Colors.green,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _showQRScanner(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.table_restaurant), text: 'Stollar'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Buyurtmalar'),
              Tab(icon: Icon(Icons.event_seat), text: 'Bron'),
              Tab(icon: Icon(Icons.analytics), text: 'Statistika'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTablesTab(),
            _buildOrdersTab(),
            _buildBookingsTab(),
            _buildStatisticsTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
          onPressed: () => _showAddOrderDialog(),
          backgroundColor: Colors.green,
          icon: const Icon(Icons.add),
          label: const Text('Yangi buyurtma'),
        )
            : null,
      ),
    );
  }

  // TABLES TAB - Visual table management
  Widget _buildTablesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tables').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tables = snapshot.data!.docs;

        if (tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Stollar mavjud emas', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _createDefaultTables(),
                  icon: const Icon(Icons.add),
                  label: const Text('Stollarni yaratish'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final tableData = tables[index].data() as Map<String, dynamic>;
            final tableId = tables[index].id;
            return _buildTableCard(tableData, tableId);
          },
        );
      },
    );
  }

  Widget _buildTableCard(Map<String, dynamic> tableData, String tableId) {
    final tableNumber = tableData['number'] ?? '?';
    final status = tableData['status'] ?? 'free'; // free, occupied, reserved
    final seats = tableData['seats'] ?? 4;
    final currentOrder = tableData['currentOrder'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'occupied':
        statusColor = Colors.red;
        statusIcon = Icons.restaurant;
        statusText = 'Band';
        break;
      case 'reserved':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Bron';
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Bo\'sh';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTableOptions(tableId, tableNumber, status, currentOrder),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.table_restaurant, size: 32, color: statusColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Stol $tableNumber',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$seats kishi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ORDERS TAB
  Widget _buildOrdersTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderLoaded) {
          final dineInOrders = state.orders.where((order) =>
          order.orderType == 'dine-in' && order.status != 'delivered' && order.status != 'cancelled'
          ).toList();

          if (dineInOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Hozircha buyurtmalar yo\'q', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<OrderBloc>().add(const LoadOrders());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dineInOrders.length,
              itemBuilder: (context, index) {
                final order = dineInOrders[index];
                return _buildOrderCard(order);
              },
            ),
          );
        }

        return const Center(child: Text('Buyurtmalar topilmadi'));
      },
    );
  }

  Widget _buildOrderCard(order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stol ${order.tableNumber ?? "?"}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)} so\'m',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${order.items.length} ta mahsulot'),
                ],
              ),
              if (order.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'cancelled'));
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Bekor qilish'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'confirmed'));
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Tasdiqlash'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
              if (order.status == 'preparing') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'ready'));
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tayyor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
              if (order.status == 'ready') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<OrderBloc>().add(UpdateOrderStatus(order.id, 'delivered'));
                    _showPaymentDialog(order);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Yetkazildi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // BOOKINGS TAB
  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('bookingDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_seat, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Bron qilishlar yo\'q', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddBookingDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Bron qo\'shish'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final bookingData = bookings[index].data() as Map<String, dynamic>;
            final bookingId = bookings[index].id;
            return _buildBookingCard(bookingData, bookingId);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> bookingData, String bookingId) {
    final tableNumber = bookingData['tableNumber'] ?? '?';
    final clientName = bookingData['clientName'] ?? 'Noma\'lum';
    final numberOfGuests = bookingData['numberOfGuests'] ?? 0;
    final bookingTime = bookingData['bookingTime'] ?? '';
    final status = bookingData['status'] ?? 'pending';
    final date = (bookingData['bookingDate'] as Timestamp?)?.toDate();

    final isToday = date != null &&
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_seat,
                    color: isToday ? Colors.orange : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stol $tableNumber',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        clientName,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBookingStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getBookingStatusText(status),
                    style: TextStyle(
                      color: _getBookingStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('$numberOfGuests kishi'),
                const SizedBox(width: 24),
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(bookingTime),
                const SizedBox(width: 24),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(date != null ? '${date.day}/${date.month}' : ''),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                      child: const Text('Bekor qilish'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateBookingStatus(bookingId, 'confirmed'),
                      child: const Text('Tasdiqlash'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // STATISTICS TAB
  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        final dineInOrders = orders.where((doc) =>
        (doc.data() as Map)['orderType'] == 'dine-in'
        ).toList();

        final today = DateTime.now();
        final todayOrders = dineInOrders.where((doc) {
          final timestamp = (doc.data() as Map)['timestamp'] as Timestamp?;
          if (timestamp == null) return false;
          final date = timestamp.toDate();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        final todayRevenue = dineInOrders.where((doc) {
          final timestamp = (doc.data() as Map)['timestamp'] as Timestamp?;
          if (timestamp == null) return false;
          final date = timestamp.toDate();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).fold<double>(
          0,
              (sum, doc) => sum + ((doc.data() as Map)['totalPrice'] ?? 0.0),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Bugungi buyurtmalar',
              '$todayOrders',
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildStatCard(
              'Bugungi daromad',
              '${todayRevenue.toStringAsFixed(0)} so\'m',
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              'Jami dine-in',
              '${dineInOrders.length}',
              Icons.restaurant,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  void _showTableOptions(String tableId, dynamic tableNumber, String status, dynamic currentOrder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stol $tableNumber',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('QR kodni ko\'rsatish'),
              onTap: () {
                Navigator.pop(context);
                _showQRCode(tableId, tableNumber);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('Buyurtma qo\'shish'),
              onTap: () {
                Navigator.pop(context);
                _showAddOrderDialog(tableId: tableId, tableNumber: tableNumber);
              },
            ),
            if (status == 'occupied' && currentOrder != null) ...[
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.orange),
                title: const Text('Hisob chiqarish'),
                onTap: () {
                  Navigator.pop(context);
                  // Show bill
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.red),
              title: const Text('Stolni tozalash'),
              onTap: () async {
                await FirebaseFirestore.instance.collection('tables').doc(tableId).update({
                  'status': 'free',
                  'currentOrder': null,
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(String tableId, dynamic tableNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Kod - Stol $tableNumber'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: 'table_$tableId',
            version: QrVersions.auto,
            size: 250,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  void _showAddOrderDialog({String? tableId, dynamic tableNumber}) {
    // Show order creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buyurtma qo\'shish oynasi ochilmoqda...')),
    );
  }

  void _showAddBookingDialog() {
    // Show booking creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bron qo\'shish oynasi ochilmoqda...')),
    );
  }

  void _showPaymentDialog(order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('To\'lov'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jami: ${order.totalPrice.toStringAsFixed(0)} so\'m',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('To\'lov turi:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Naqd'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Karta'),
          ),
        ],
      ),
    );
  }

  void _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': newStatus,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Holat yangilandi: ${_getBookingStatusText(newStatus)}')),
    );
  }

  void _createDefaultTables() async {
    for (int i = 1; i <= 20; i++) {
      await FirebaseFirestore.instance.collection('tables').add({
        'number': i,
        'seats': i <= 10 ? 4 : (i <= 15 ? 6 : 8),
        'status': 'free',
        'currentOrder': null,
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('20 ta stol yaratildi'), backgroundColor: Colors.green),
    );
  }

  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR skaner ochilmoqda...')),
    );
  }

  void _showLogoutDialog() {
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
            child: const Text('Ha'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.done_all;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
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
      default: return 'Noma\'lum';
    }
  }

  Color _getBookingStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getBookingStatusText(String status) {
    switch (status) {
      case 'pending': return 'Kutilmoqda';
      case 'confirmed': return 'Tasdiqlandi';
      case 'cancelled': return 'Bekor qilindi';
      case 'completed': return 'Yakunlandi';
      default: return 'Noma\'lum';
    }
  }
}