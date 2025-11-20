import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dish.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menyu boshqaruvi'),
        backgroundColor: Colors.orange,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Barcha'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'HOT'),
            Tab(icon: Icon(Icons.local_offer), text: 'Chegirmalar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Taom qidirish...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllDishesTab(),
                _buildHotDishesTab(),
                _buildDiscountedDishesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDishDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Yangi taom'),
      ),
    );
  }

  // ALL DISHES TAB
  Widget _buildAllDishesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('dishes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.restaurant_menu,
            title: 'Taomlar yo\'q',
            subtitle: 'Yangi taom qo\'shing',
          );
        }

        var dishes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty || name.contains(_searchQuery);
        }).toList();

        if (dishes.isEmpty && _searchQuery.isNotEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'Topilmadi',
            subtitle: 'Boshqa nom bilan qidiring',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dishes.length,
          itemBuilder: (context, index) {
            final dishData = dishes[index].data() as Map<String, dynamic>;
            final dishId = dishes[index].id;
            return _buildDishCard(dishData, dishId);
          },
        );
      },
    );
  }

  // HOT DISHES TAB
  Widget _buildHotDishesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dishes')
          .where('isHot', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_fire_department,
            title: 'HOT taomlar yo\'q',
            subtitle: 'Taomni HOT qilib belgilang',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final dishData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final dishId = snapshot.data!.docs[index].id;
            return _buildDishCard(dishData, dishId, showHotBadge: true);
          },
        );
      },
    );
  }

  // DISCOUNTED DISHES TAB
  Widget _buildDiscountedDishesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dishes')
          .where('discount', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_offer,
            title: 'Chegirmali taomlar yo\'q',
            subtitle: 'Taomga chegirma qo\'shing',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final dishData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final dishId = snapshot.data!.docs[index].id;
            return _buildDishCard(dishData, dishId, showDiscountBadge: true);
          },
        );
      },
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dishData, String dishId, {bool showHotBadge = false, bool showDiscountBadge = false}) {
    final name = dishData['name'] ?? 'Noma\'lum';
    final description = dishData['description'] ?? '';
    final price = (dishData['price'] ?? 0.0).toDouble();
    final imageUrl = dishData['imageUrl'] ?? '';
    final isHot = dishData['isHot'] ?? false;
    final discount = (dishData['discount'] ?? 0).toInt();
    final isAvailable = dishData['isAvailable'] ?? true;
    final category = dishData['category'] ?? 'Umumiy';

    final discountedPrice = discount > 0 ? price * (1 - discount / 100) : price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditDishDialog(dishData, dishId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.restaurant, size: 40, color: Colors.grey)
                        : null,
                  ),
                  // HOT Badge
                  if (isHot)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_fire_department, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'HOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Discount Badge
                  if (discount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Unavailable overlay
                  if (!isAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Mavjud emas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Tahrirlash'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hot',
                              child: Row(
                                children: [
                                  Icon(
                                    isHot ? Icons.remove_circle : Icons.local_fire_department,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isHot ? 'HOT dan chiqarish' : 'HOT qilish'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'discount',
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, size: 20, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text('Chegirma'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isAvailable ? Icons.visibility_off : Icons.visibility,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isAvailable ? 'Yashirish' : 'Ko\'rsatish'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('O\'chirish', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) => _handleMenuAction(value, dishId, dishData),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (discount > 0) ...[
                          Text(
                            '${price.toStringAsFixed(0)} so\'m',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${discountedPrice.toStringAsFixed(0)} so\'m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: discount > 0 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(dynamic value, String dishId, Map<String, dynamic> dishData) {
    switch (value) {
      case 'edit':
        _showEditDishDialog(dishData, dishId);
        break;
      case 'hot':
        _toggleHot(dishId, dishData['isHot'] ?? false);
        break;
      case 'discount':
        _showDiscountDialog(dishId, dishData['discount'] ?? 0);
        break;
      case 'toggle':
        _toggleAvailability(dishId, dishData['isAvailable'] ?? true);
        break;
      case 'delete':
        _showDeleteDialog(dishId, dishData['name'] ?? 'Taom');
        break;
    }
  }

  void _toggleHot(String dishId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('dishes').doc(dishId).update({
      'isHot': !currentValue,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentValue ? 'HOT taom qo\'shildi 🔥' : 'HOT dan olib tashlandi'),
          backgroundColor: !currentValue ? Colors.red : Colors.grey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleAvailability(String dishId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('dishes').doc(dishId).update({
      'isAvailable': !currentValue,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentValue ? 'Taom ko\'rsatildi' : 'Taom yashirildi'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDiscountDialog(String dishId, int currentDiscount) {
    final discountController = TextEditingController(
      text: currentDiscount > 0 ? currentDiscount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.green),
            SizedBox(width: 12),
            Text('Chegirma'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'Chegirma (%)',
                hintText: '0-100',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              '0 = Chegirma yo\'q\n10 = 10% chegirma\n50 = 50% chegirma',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final discount = int.tryParse(discountController.text) ?? 0;
              if (discount >= 0 && discount <= 100) {
                await FirebaseFirestore.instance.collection('dishes').doc(dishId).update({
                  'discount': discount,
                });
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(discount > 0 ? 'Chegirma $discount% qo\'shildi' : 'Chegirma olib tashlandi'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String dishId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('O\'chirish'),
          ],
        ),
        content: Text('$name ni o\'chirishga ishonchingiz komilmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('dishes').doc(dishId).delete();
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Taom o\'chirildi'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ha, o\'chirish'),
          ),
        ],
      ),
    );
  }

  void _showAddDishDialog() {
    // Navigate to Add Dish Screen
    Navigator.pushNamed(context, '/add_dish');
  }

  void _showEditDishDialog(Map<String, dynamic> dishData, String dishId) {
    // Navigate to Edit Dish Screen
    Navigator.pushNamed(context, '/edit_dish', arguments: {'dishId': dishId, 'data': dishData});
  }
}