import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// CATEGORIES SCREEN
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriyalar'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Kategoriyalar yo\'q', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Kategoriya qo\'shish'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index].data() as Map<String, dynamic>;
              final categoryId = categories[index].id;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(category['icon'] ?? 'restaurant'),
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(category['name'] ?? ''),
                  subtitle: Text('${category['dishCount'] ?? 0} ta taom'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Tahrirlash'),
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
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCategory(context, categoryId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedIcon = 'restaurant';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yangi kategoriya'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nomi',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedIcon,
                decoration: const InputDecoration(labelText: 'Ikonka'),
                items: const [
                  DropdownMenuItem(value: 'restaurant', child: Text('🍴 Umumiy')),
                  DropdownMenuItem(value: 'local_pizza', child: Text('🍕 Pitsa')),
                  DropdownMenuItem(value: 'lunch_dining', child: Text('🍔 Burger')),
                  DropdownMenuItem(value: 'local_drink', child: Text('🥤 Ichimlik')),
                  DropdownMenuItem(value: 'cake', child: Text('🍰 Desert')),
                  DropdownMenuItem(value: 'ramen_dining', child: Text('🍜 Sho\'rva')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedIcon = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('categories').add({
                    'name': nameController.text,
                    'icon': selectedIcon,
                    'dishCount': 0,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  static void _deleteCategory(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirish'),
        content: const Text('Kategoriyani o\'chirishga ishonchingiz komilmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yo\'q'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
  }

  static IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'local_pizza': return Icons.local_pizza;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'local_drink': return Icons.local_drink;
      case 'cake': return Icons.cake;
      case 'ramen_dining': return Icons.ramen_dining;
      default: return Icons.restaurant;
    }
  }
}

// PROMOTIONS SCREEN
class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aksiyalar va Chegirmalar'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final promotions = snapshot.data!.docs;

          if (promotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aksiyalar yo\'q', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPromotionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Aksiya qo\'shish'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index].data() as Map<String, dynamic>;
              final promoId = promotions[index].id;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_offer, color: Colors.red),
                  ),
                  title: Text(promo['title'] ?? ''),
                  subtitle: Text('${promo['discount'] ?? 0}% chegirma'),
                  trailing: Switch(
                    value: promo['isActive'] ?? false,
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('promotions')
                          .doc(promoId)
                          .update({'isActive': value});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromotionDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showAddPromotionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi aksiya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Sarlavha',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'Chegirma (%)',
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && discountController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('promotions').add({
                  'title': titleController.text,
                  'discount': int.parse(discountController.text),
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }
}

// TABLES MANAGEMENT SCREEN
class TablesManagementScreen extends StatelessWidget {
  const TablesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stollar boshqaruvi'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                  const Text('Stollar yo\'q', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _createDefaultTables(context),
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
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index].data() as Map<String, dynamic>;
              final tableId = tables[index].id;
              final status = table['status'] ?? 'free';
              final number = table['number'] ?? index + 1;

              Color statusColor = status == 'occupied'
                  ? Colors.red
                  : (status == 'reserved' ? Colors.orange : Colors.green);

              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _showTableDetails(context, tableId, table),
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant, size: 32, color: statusColor),
                        const SizedBox(height: 8),
                        Text(
                          'Stol $number',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          status == 'occupied' ? 'Band' : (status == 'reserved' ? 'Bron' : 'Bo\'sh'),
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static void _createDefaultTables(BuildContext context) async {
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

  static void _showTableDetails(BuildContext context, String tableId, Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stol ${table['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O\'rindiqlar: ${table['seats']}'),
            Text('Holat: ${table['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tables').doc(tableId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}

// FINANCIAL REPORTS SCREEN
class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moliyaviy hisobotlar'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard('Kunlik hisobot', Icons.today, Colors.blue),
          _buildReportCard('Haftalik hisobot', Icons.date_range, Colors.green),
          _buildReportCard('Oylik hisobot', Icons.calendar_month, Colors.orange),
          _buildReportCard('Yillik hisobot', Icons.calendar_today, Colors.purple),
        ],
      ),
    );
  }

  static Widget _buildReportCard(String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}

// SETTINGS SCREEN
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Restoran nomi'),
            subtitle: const Text('FoodFlow Restaurant'),
            trailing: const Icon(Icons.edit),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Manzil'),
            subtitle: const Text('Toshkent, O\'zbekiston'),
            trailing: const Icon(Icons.edit),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Telefon'),
            subtitle: const Text('+998 90 123 45 67'),
            trailing: const Icon(Icons.edit),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Bildirishnomalar'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Til'),
            subtitle: const Text('O\'zbekcha'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}