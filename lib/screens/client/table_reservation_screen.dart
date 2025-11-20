import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TableReservationScreen extends StatefulWidget {
  const TableReservationScreen({super.key});

  @override
  State<TableReservationScreen> createState() =>
      _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestsController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedTableNumber;
  List<int> _availableTables = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadAvailableTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _guestsController.dispose();
    _notesController.dispose();
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
            _nameController.text = userData?['name'] ?? '';
            _phoneController.text = userData?['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadAvailableTables() async {
    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Get all tables (assume 20 tables)
      final allTables = List.generate(20, (index) => index + 1);

      // Get reservations for selected time slot (±2 hours)
      final startTime = Timestamp.fromDate(
          selectedDateTime.subtract(const Duration(hours: 2)));
      final endTime = Timestamp.fromDate(
          selectedDateTime.add(const Duration(hours: 2)));

      final reservations = await FirebaseFirestore.instance
          .collection('table_reservations')
          .where('reservationTime', isGreaterThanOrEqualTo: startTime)
          .where('reservationTime', isLessThanOrEqualTo: endTime)
          .where('status', whereIn: ['confirmed', 'pending']).get();

      final reservedTables =
          reservations.docs.map((doc) => doc.data()['tableNumber'] as int).toSet();

      setState(() {
        _availableTables =
            allTables.where((table) => !reservedTables.contains(table)).toList();
      });
    } catch (e) {
      debugPrint('Error loading available tables: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAvailableTables();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
      _loadAvailableTables();
    }
  }

  Future<void> _makeReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTableNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, stol tanlang')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reservationTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reservationId =
          FirebaseFirestore.instance.collection('table_reservations').doc().id;

      await FirebaseFirestore.instance
          .collection('table_reservations')
          .doc(reservationId)
          .set({
        'id': reservationId,
        'clientId': user.uid,
        'clientName': _nameController.text.trim(),
        'clientPhone': _phoneController.text.trim(),
        'tableNumber': _selectedTableNumber,
        'guestsCount': int.parse(_guestsController.text),
        'reservationTime': Timestamp.fromDate(reservationTime),
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'status': 'pending', // pending, confirmed, cancelled, completed
        'createdAt': Timestamp.now(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bron muvaffaqiyatli yaratildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('table_reservations')
          .doc(reservationId)
          .update({'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bron bekor qilindi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stol broni'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yangi bron', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Mening bronlarim', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewReservation(),
          _buildMyReservations(),
        ],
      ),
    );
  }

  Widget _buildNewReservation() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shaxsiy ma\'lumotlar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ism *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ismni kiriting' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Telefon raqamini kiriting'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _guestsController,
                      decoration: const InputDecoration(
                        labelText: 'Mehmonlar soni *',
                        prefixIcon: Icon(Icons.group),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Mehmonlar sonini kiriting'
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sana va vaqt',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: theme.primaryColor),
                      title: const Text('Sana'),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy, EEEE').format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectDate,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.access_time, color: theme.primaryColor),
                      title: const Text('Vaqt'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectTime,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Table Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stol tanlash',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _loadAvailableTables,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Yangilash'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_availableTables.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Ushbu vaqt uchun mavjud stollar yo\'q',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTables.map((tableNumber) {
                          final isSelected = _selectedTableNumber == tableNumber;
                          return InkWell(
                            onTap: () => setState(
                                () => _selectedTableNumber = tableNumber),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.cardColor,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$tableNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Qo\'shimcha izoh (ixtiyoriy)',
                    prefixIcon: Icon(Icons.note),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _makeReservation,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 12),
                          Text(
                            'Bronni tasdiqlash',
                            style: TextStyle(
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
    );
  }

  Widget _buildMyReservations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Tizimga kirish kerak'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('table_reservations')
          .where('clientId', isEqualTo: user.uid)
          .orderBy('reservationTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Xatolik: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservations = snapshot.data?.docs ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Bronlar yo\'q',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final doc = reservations[index];
            final data = doc.data() as Map<String, dynamic>;
            final reservationTime =
                (data['reservationTime'] as Timestamp).toDate();
            final status = data['status'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.table_restaurant,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Stol ${data['tableNumber']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd MMM yyyy')
                            .format(reservationTime)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('HH:mm').format(reservationTime)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16),
                        const SizedBox(width: 8),
                        Text('${data['guestsCount']} mehmon'),
                      ],
                    ),
                    if (data['notes'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['notes'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status == 'pending' || status == 'confirmed') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelReservation(doc.id),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Bekor qilish'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Kutilmoqda';
        icon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        color = Colors.green;
        label = 'Tasdiqlangan';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Bekor qilingan';
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Bajarilgan';
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        label = 'Noma\'lum';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
