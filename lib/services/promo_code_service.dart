import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCode {
  final String code;
  final double discount; // Percentage
  final DateTime? expiryDate;
  final bool isActive;
  final int? maxUses;
  final int currentUses;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final List<String>? applicableCategories;

  PromoCode({
    required this.code,
    required this.discount,
    this.expiryDate,
    required this.isActive,
    this.maxUses,
    required this.currentUses,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.applicableCategories,
  });

  factory PromoCode.fromFirestore(Map<String, dynamic> data) {
    return PromoCode(
      code: data['code'] ?? '',
      discount: (data['discount'] ?? 0).toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      maxUses: data['maxUses'],
      currentUses: data['currentUses'] ?? 0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble(),
      maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
      applicableCategories: (data['applicableCategories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discount': discount,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isActive': isActive,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'applicableCategories': applicableCategories,
    };
  }
}

class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate promo code
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
    List<String>? orderCategories,
  ) async {
    try {
      final doc = await _firestore
          .collection('promo_codes')
          .doc(code.toUpperCase())
          .get();

      if (!doc.exists) {
        return {'valid': false, 'message': 'Promo kod topilmadi'};
      }

      final promoCode = PromoCode.fromFirestore(doc.data()!);

      // Check if active
      if (!promoCode.isActive) {
        return {'valid': false, 'message': 'Promo kod faol emas'};
      }

      // Check expiry date
      if (promoCode.expiryDate != null &&
          promoCode.expiryDate!.isBefore(DateTime.now())) {
        return {'valid': false, 'message': 'Promo kod muddati tugagan'};
      }

      // Check max uses
      if (promoCode.maxUses != null &&
          promoCode.currentUses >= promoCode.maxUses!) {
        return {'valid': false, 'message': 'Promo kod limiti tugagan'};
      }

      // Check minimum order amount
      if (promoCode.minOrderAmount != null &&
          orderAmount < promoCode.minOrderAmount!) {
        return {
          'valid': false,
          'message':
              'Minimal buyurtma summasi: ${promoCode.minOrderAmount!.toStringAsFixed(0)} so\'m',
        };
      }

      // Check applicable categories
      if (promoCode.applicableCategories != null &&
          promoCode.applicableCategories!.isNotEmpty &&
          orderCategories != null) {
        final hasApplicableCategory = orderCategories.any(
          (cat) => promoCode.applicableCategories!.contains(cat),
        );
        if (!hasApplicableCategory) {
          return {
            'valid': false,
            'message': 'Promo kod ushbu kategoriya uchun mos emas'
          };
        }
      }

      // Calculate discount
      double discountAmount = orderAmount * (promoCode.discount / 100);
      if (promoCode.maxDiscountAmount != null &&
          discountAmount > promoCode.maxDiscountAmount!) {
        discountAmount = promoCode.maxDiscountAmount!;
      }

      return {
        'valid': true,
        'discount': promoCode.discount,
        'discountAmount': discountAmount,
        'message': '${promoCode.discount.toInt()}% chegirma qo\'llandi!',
      };
    } catch (e) {
      return {'valid': false, 'message': 'Xatolik: $e'};
    }
  }

  // Apply promo code (increment usage)
  Future<bool> applyPromoCode(String code, String userId, String orderId) async {
    try {
      final docRef = _firestore.collection('promo_codes').doc(code.toUpperCase());

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Promo kod topilmadi');

        final currentUses = snapshot.data()?['currentUses'] ?? 0;
        transaction.update(docRef, {'currentUses': currentUses + 1});

        // Log usage
        await _firestore.collection('promo_code_usage').add({
          'code': code.toUpperCase(),
          'userId': userId,
          'orderId': orderId,
          'usedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Error applying promo code: $e');
      return false;
    }
  }

  // Create promo code (admin function)
  Future<bool> createPromoCode(PromoCode promoCode) async {
    try {
      await _firestore
          .collection('promo_codes')
          .doc(promoCode.code.toUpperCase())
          .set(promoCode.toFirestore());
      return true;
    } catch (e) {
      print('Error creating promo code: $e');
      return false;
    }
  }

  // Get all active promo codes
  Future<List<PromoCode>> getActivePromoCodes() async {
    try {
      final snapshot = await _firestore
          .collection('promo_codes')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => PromoCode.fromFirestore(doc.data()))
          .where((promo) =>
              promo.expiryDate == null ||
              promo.expiryDate!.isAfter(DateTime.now()))
          .toList();
    } catch (e) {
      print('Error getting promo codes: $e');
      return [];
    }
  }

  // Delete promo code
  Future<bool> deletePromoCode(String code) async {
    try {
      await _firestore.collection('promo_codes').doc(code.toUpperCase()).delete();
      return true;
    } catch (e) {
      print('Error deleting promo code: $e');
      return false;
    }
  }

  // Update promo code status
  Future<bool> updatePromoCodeStatus(String code, bool isActive) async {
    try {
      await _firestore
          .collection('promo_codes')
          .doc(code.toUpperCase())
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Error updating promo code: $e');
      return false;
    }
  }

  // Get promo code usage stats
  Future<int> getPromoCodeUsageCount(String code) async {
    try {
      final snapshot = await _firestore
          .collection('promo_code_usage')
          .where('code', isEqualTo: code.toUpperCase())
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting usage count: $e');
      return 0;
    }
  }

  // Check if user has used promo code
  Future<bool> hasUserUsedPromoCode(String code, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('promo_code_usage')
          .where('code', isEqualTo: code.toUpperCase())
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user usage: $e');
      return false;
    }
  }
}
