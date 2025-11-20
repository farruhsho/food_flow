import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDishScreen extends StatefulWidget {
  const AddDishScreen({super.key});

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _allergensController = TextEditingController();
  final _suitableForController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  // Категория и флаги
  String _selectedCategory = 'Umumiy';
  bool _isHot = false;
  bool _isAvailable = true;

  // Список категорий
  final List<String> _categories = [
    'Umumiy',
    'Birinchi taomlar',
    'Ikkinchi taomlar',
    'Salatlar',
    'Gazaklar',
    'Shirinliklar',
    'Ichimliklar',
    'Fast Food',
    'Milliy taomlar',
    'Vegetarian',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _allergensController.dispose();
    _suitableForController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Rasmni tanlashda xatolik: $e');
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final String fileName = 'dishes/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(_imageFile!);

      // Показываем прогресс
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _imageUrl = downloadUrl;
      });

      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      print('Upload error: $e');
      if (mounted) {
        _showErrorSnackbar('Rasmni yuklashda xatolik: $e');
      }
      return null;
    }
  }

  Future<void> _saveDishToFirestore(String imageUrl) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final dishId = DateTime.now().millisecondsSinceEpoch.toString();

      final dishData = {
        'id': dishId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'discount': int.parse(_discountController.text.isEmpty ? '0' : _discountController.text),
        'isHot': _isHot,
        'isAvailable': _isAvailable,
        'allergens': _allergensController.text.isNotEmpty
            ? _allergensController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        'suitableFor': _suitableForController.text.isNotEmpty
            ? _suitableForController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Saving dish to Firestore: $dishData');

      // Сохраняем в Firestore
      await FirebaseFirestore.instance
          .collection('dishes')
          .doc(dishId)
          .set(dishData);

      print('Dish saved successfully with ID: $dishId');

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        // Показываем успешное уведомление
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      print('Firestore error: $e');
      if (mounted) {
        _showErrorSnackbar('Firestore ga saqlashda xatolik: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_nameController.text}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'muvaffaqiyatli qo\'shildi!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрыть диалог
                      Navigator.pop(context); // Вернуться назад
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tayyor',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрыть диалог
                      _resetForm(); // Очистить форму
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Yana qo\'shish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _discountController.text = '0';
    _allergensController.clear();
    _suitableForController.clear();
    setState(() {
      _imageFile = null;
      _imageUrl = null;
      _selectedCategory = 'Umumiy';
      _isHot = false;
      _isAvailable = true;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = _isUploading || _isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taom qo\'shish'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Загрузка изображения
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rasm tanlanmagan',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: isProcessing ? null : _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _imageFile != null ? 'Boshqa rasmni tanlash' : 'Galereyadan tanlash',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Название
                  TextFormField(
                    controller: _nameController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Nomi *',
                      prefixIcon: const Icon(Icons.restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Iltimos, nomni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Категория
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategoriya *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: isProcessing ? null : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Tavsif *',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Iltimos, tavsifni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Цена и Скидка
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          enabled: !isProcessing,
                          decoration: InputDecoration(
                            labelText: 'Narxi (so\'m) *',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Narxni kiriting';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Noto\'g\'ri format';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          enabled: !isProcessing,
                          decoration: InputDecoration(
                            labelText: 'Chegirma %',
                            prefixIcon: const Icon(Icons.discount),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final discount = int.tryParse(value);
                              if (discount == null || discount < 0 || discount > 100) {
                                return '0-100';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Аллергены
                  TextFormField(
                    controller: _allergensController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Allergenlar (vergul bilan)',
                      prefixIcon: const Icon(Icons.warning_amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: 'yong\'oq, sut, tuxum',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Подходит для
                  TextFormField(
                    controller: _suitableForController,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      labelText: 'Mos keladi (vergul bilan)',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: 'vegetarian, halal',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Чекбоксы
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('HOT taom'),
                            subtitle: const Text('Ommabop taom belgisi'),
                            secondary: Icon(
                              Icons.local_fire_department,
                              color: _isHot ? Colors.red : Colors.grey,
                            ),
                            value: _isHot,
                            activeColor: Colors.red,
                            onChanged: isProcessing ? null : (bool value) {
                              setState(() {
                                _isHot = value;
                              });
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Mavjud'),
                            subtitle: const Text('Menuda ko\'rsatish'),
                            secondary: Icon(
                              Icons.visibility,
                              color: _isAvailable ? Colors.green : Colors.grey,
                            ),
                            value: _isAvailable,
                            activeColor: Colors.green,
                            onChanged: isProcessing ? null : (bool value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Кнопка добавления
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : _handleSubmit,
                      icon: isProcessing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.add_circle),
                      label: Text(
                        isProcessing
                            ? (_isUploading ? 'Rasm yuklanmoqda...' : 'Saqlanmoqda...')
                            : 'Taom qo\'shish',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Progress overlay
          if (isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _isUploading
                              ? 'Rasm yuklanmoqda...'
                              : 'Firestore ga saqlanmoqda...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        _showErrorSnackbar('Iltimos, rasm tanlang');
        return;
      }

      // Шаг 1: Загружаем изображение в Storage
      final imageUrl = await _uploadImage();

      if (imageUrl == null) {
        _showErrorSnackbar('Rasm yuklanmadi. Qayta urinib ko\'ring');
        return;
      }

      // Шаг 2: Сохраняем блюдо в Firestore
      await _saveDishToFirestore(imageUrl);
    }
  }
}