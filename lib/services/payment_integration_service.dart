import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PaymentIntegrationService {
  final Dio _dio = Dio();

  // Payme configuration
  static const String _paymeBaseUrl = 'https://checkout.paycom.uz';
  static const String _paymeMerchantId = 'YOUR_PAYME_MERCHANT_ID'; // Replace with real ID
  static const String _paymeSecretKey = 'YOUR_PAYME_SECRET_KEY'; // Replace with real key

  // Click configuration
  static const String _clickBaseUrl = 'https://my.click.uz/services/pay';
  static const String _clickMerchantId = 'YOUR_CLICK_MERCHANT_ID'; // Replace with real ID
  static const String _clickServiceId = 'YOUR_CLICK_SERVICE_ID'; // Replace with real ID
  static const String _clickSecretKey = 'YOUR_CLICK_SECRET_KEY'; // Replace with real key

  // Uzcard configuration
  static const String _uzcardBaseUrl = 'https://api.uzcard.uz';
  static const String _uzcardMerchantId = 'YOUR_UZCARD_MERCHANT_ID'; // Replace with real ID
  static const String _uzcardApiKey = 'YOUR_UZCARD_API_KEY'; // Replace with real key

  // Payme Integration
  Future<Map<String, dynamic>> initiatePaymePayment({
    required String orderId,
    required double amount,
    required String returnUrl,
  }) async {
    try {
      final amountInTiyin = (amount * 100).toInt(); // Convert to tiyin (smallest unit)

      final params = base64Encode(
        utf8.encode(jsonEncode({
          'm': _paymeMerchantId,
          'ac': {'order_id': orderId},
          'a': amountInTiyin,
          'c': returnUrl,
        })),
      );

      final paymentUrl = '$_paymeBaseUrl?$params';

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'orderId': orderId,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyPaymePayment(String transactionId) async {
    try {
      final response = await _dio.post(
        _paymeBaseUrl,
        data: {
          'method': 'CheckTransaction',
          'params': {'id': transactionId},
        },
        options: Options(
          headers: {
            'X-Auth': _generatePaymeAuth(),
          },
        ),
      );

      final result = response.data['result'];
      return {
        'success': true,
        'status': result['state'],
        'amount': result['amount'],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Click Integration
  Future<Map<String, dynamic>> initiateClickPayment({
    required String orderId,
    required double amount,
    required String returnUrl,
  }) async {
    try {
      final amountInTiyin = (amount * 100).toInt();

      final paymentUrl = Uri.parse(_clickBaseUrl).replace(queryParameters: {
        'service_id': _clickServiceId,
        'merchant_id': _clickMerchantId,
        'amount': amountInTiyin.toString(),
        'transaction_param': orderId,
        'return_url': returnUrl,
      }).toString();

      return {
        'success': true,
        'paymentUrl': paymentUrl,
        'orderId': orderId,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyClickPayment(
    String clickTransId,
    String serviceId,
    String merchantTransId,
  ) async {
    try {
      final signTime = DateTime.now().toIso8601String();
      final signString = '$clickTransId$serviceId$_clickSecretKey$merchantTransId$signTime';
      final md5Sign = md5.convert(utf8.encode(signString)).toString();

      final response = await _dio.post(
        '$_clickBaseUrl/check',
        data: {
          'click_trans_id': clickTransId,
          'service_id': serviceId,
          'merchant_trans_id': merchantTransId,
          'sign_time': signTime,
          'sign_string': md5Sign,
        },
      );

      return {
        'success': true,
        'status': response.data['error'] == 0 ? 'success' : 'failed',
        'data': response.data,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Uzcard Integration
  Future<Map<String, dynamic>> initiateUzcardPayment({
    required String orderId,
    required double amount,
    required String returnUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$_uzcardBaseUrl/api/v1/payment/init',
        data: {
          'merchant_id': _uzcardMerchantId,
          'order_id': orderId,
          'amount': amount.toInt(),
          'return_url': returnUrl,
          'description': 'Payment for order $orderId',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_uzcardApiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': true,
        'paymentUrl': response.data['payment_url'],
        'transactionId': response.data['transaction_id'],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyUzcardPayment(String transactionId) async {
    try {
      final response = await _dio.get(
        '$_uzcardBaseUrl/api/v1/payment/status/$transactionId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_uzcardApiKey',
          },
        ),
      );

      return {
        'success': true,
        'status': response.data['status'],
        'amount': response.data['amount'],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper Methods
  String _generatePaymeAuth() {
    final credentials = '$_paymeMerchantId:$_paymeSecretKey';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  // Webhook handlers
  Future<Map<String, dynamic>> handlePaymeWebhook(Map<String, dynamic> data) async {
    try {
      final method = data['method'];
      final params = data['params'];

      switch (method) {
        case 'CheckPerformTransaction':
          return _handlePaymeCheck(params);
        case 'CreateTransaction':
          return _handlePaymeCreate(params);
        case 'PerformTransaction':
          return _handlePaymePerform(params);
        case 'CancelTransaction':
          return _handlePaymeCancel(params);
        default:
          return {'error': {'code': -32601, 'message': 'Method not found'}};
      }
    } catch (e) {
      return {
        'error': {'code': -32400, 'message': e.toString()}
      };
    }
  }

  Future<Map<String, dynamic>> _handlePaymeCheck(Map<String, dynamic> params) async {
    // Implement check logic
    return {'result': {'allow': true}};
  }

  Future<Map<String, dynamic>> _handlePaymeCreate(Map<String, dynamic> params) async {
    // Implement create transaction logic
    return {
      'result': {
        'create_time': DateTime.now().millisecondsSinceEpoch,
        'transaction': params['id'],
        'state': 1,
      }
    };
  }

  Future<Map<String, dynamic>> _handlePaymePerform(Map<String, dynamic> params) async {
    // Implement perform transaction logic
    return {
      'result': {
        'transaction': params['id'],
        'perform_time': DateTime.now().millisecondsSinceEpoch,
        'state': 2,
      }
    };
  }

  Future<Map<String, dynamic>> _handlePaymeCancel(Map<String, dynamic> params) async {
    // Implement cancel transaction logic
    return {
      'result': {
        'transaction': params['id'],
        'cancel_time': DateTime.now().millisecondsSinceEpoch,
        'state': -1,
      }
    };
  }

  // Click webhook handler
  Future<Map<String, dynamic>> handleClickWebhook(Map<String, dynamic> data) async {
    try {
      final action = data['action'];

      if (action == 0) {
        // Prepare (check)
        return {'error': 0, 'error_note': 'Success'};
      } else if (action == 1) {
        // Complete
        return {
          'error': 0,
          'error_note': 'Success',
          'merchant_confirm_id': data['merchant_trans_id'],
          'merchant_prepare_id': data['merchant_trans_id'],
        };
      }

      return {'error': -8, 'error_note': 'Unknown action'};
    } catch (e) {
      return {'error': -9, 'error_note': e.toString()};
    }
  }

  // Refund payment
  Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required String paymentMethod,
    required double amount,
  }) async {
    switch (paymentMethod.toLowerCase()) {
      case 'payme':
        return await _refundPaymePayment(transactionId, amount);
      case 'click':
        return await _refundClickPayment(transactionId, amount);
      case 'uzcard':
        return await _refundUzcardPayment(transactionId, amount);
      default:
        return {'success': false, 'error': 'Refund not supported for this method'};
    }
  }

  Future<Map<String, dynamic>> _refundPaymePayment(String transactionId, double amount) async {
    // Implement Payme refund logic
    return {'success': true, 'message': 'Refund initiated'};
  }

  Future<Map<String, dynamic>> _refundClickPayment(String transactionId, double amount) async {
    // Implement Click refund logic
    return {'success': true, 'message': 'Refund initiated'};
  }

  Future<Map<String, dynamic>> _refundUzcardPayment(String transactionId, double amount) async {
    // Implement Uzcard refund logic
    return {'success': true, 'message': 'Refund initiated'};
  }
}
