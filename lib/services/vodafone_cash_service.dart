import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginResult {
  final String seamlessToken;
  final String senderMsisdn;

  LoginResult({required this.seamlessToken, required this.senderMsisdn});
}

class PurchaseResult {
  final bool success;
  final String message;
  final int statusCode;
  final String rawBody;

  PurchaseResult({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.rawBody,
  });
}

class VodafoneCashService {
  static const _deviceId = 'b26ba335813fad21';
  static const _userAgent = 'okhttp/4.12.0';

  Map<String, String> get _baseHeaders => const {
        'User-Agent': _userAgent,
        'Accept-Encoding': 'gzip',
        'x-agent-operatingsystem': '16',
        'clientId': 'AnaVodafoneAndroid',
        'Accept-Language': 'ar',
        'x-agent-device': 'Samsung SM-A165F',
        'x-agent-version': '2025.11.1',
        'x-agent-build': '1063',
        'digitalId': '',
        'device-id': _deviceId,
      };

  Future<LoginResult> getSeamlessAndMsisdn() async {
    final uri = Uri.parse(
      'http://mobile.vodafone.com.eg/checkSeamless/realms/vf-realm/protocol/openid-connect/auth',
    ).replace(queryParameters: {'client_id': 'cash-app'});

    final response = await http.get(
      uri,
      headers: {
        ..._baseHeaders,
        'Connection': 'Keep-Alive',
        'If-Modified-Since': 'Thu, 02 Apr 2026 09:09:07 GMT',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل الحصول على seamlessToken');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawMsisdn = data['msisdn']?.toString();
    final formattedMsisdn = rawMsisdn != null && rawMsisdn.startsWith('1')
        ? '0$rawMsisdn'
        : rawMsisdn;
    final token = data['seamlessToken']?.toString();

    if (token == null || formattedMsisdn == null) {
      throw Exception('بيانات تسجيل الدخول غير مكتملة');
    }

    return LoginResult(seamlessToken: token, senderMsisdn: formattedMsisdn);
  }

  Future<String> getAccessToken(String seamlessToken) async {
    final uri = Uri.parse(
      'https://mobile.vodafone.com.eg/auth/realms/vf-realm/protocol/openid-connect/token',
    );

    final response = await http.post(
      uri,
      body: {
        'grant_type': 'password',
        'client_secret': 'b86e30a8-ae29-467a-a71f-65c73f2ff5e3',
        'client_id': 'cash-app',
      },
      headers: {
        ..._baseHeaders,
        'Accept': 'application/json, text/plain, */*',
        'silentLogin': 'true',
        'CRP': 'false',
        'seamlessToken': seamlessToken,
        'firstTimeLogin': 'true',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل الحصول على access_token');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token']?.toString();
    if (token == null) throw Exception('لم يتم العثور على access_token');
    return token;
  }

  Future<PurchaseResult> purchaseProduct({
    required String selectedProduct,
    required String receiver,
    required String pin,
    required String seamlessToken,
    required String senderMsisdn,
  }) async {
    final accessToken = await getAccessToken(seamlessToken);
    final uri = Uri.parse('https://mobile.vodafone.com.eg/services/dxl/pom/productOrder');

    final payload = {
      'channel': {'name': 'MobileApp'},
      'orderItem': [
        {
          'action': 'insert',
          'id': selectedProduct,
          'product': selectedProduct,
          '@type': 'CashFakkaAndMared',
          'eCode': 0,
          'characteristic': [
            {'name': 'PaymentMethod', 'value': 'VFCash'},
            {'name': 'USE_EMONEY', 'value': 'False'},
            {'name': 'MerchantCode', 'value': ''},
          ],
          'relatedParty': [
            {'id': senderMsisdn, 'name': 'MSISDN', 'role': 'Subscriber'},
            {'id': receiver, 'name': 'Receiver', 'role': 'Receiver'},
          ],
        }
      ],
      'relatedParty': [
        {'id': pin, 'name': 'pin', 'role': 'Requestor'},
      ],
      '@type': 'CashFakkaAndMared',
    };

    final response = await http.post(
      uri,
      body: jsonEncode(payload),
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
        'api-host': 'ProductOrderingManagement',
        'useCase': 'CashFakkaAndMared',
        'X-Request-ID': DateTime.now().millisecondsSinceEpoch.toString(),
        'device-id': _deviceId,
        'api-version': 'v2',
        'msisdn': senderMsisdn,
        'Authorization': 'Bearer $accessToken',
        'Accept-Language': 'ar',
        'x-agent-operatingsystem': '16',
        'clientId': 'AnaVodafoneAndroid',
        'x-agent-device': 'Samsung SM-A165F',
        'x-agent-version': '2025.11.1',
        'x-agent-build': '1063',
        'digitalId': '',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      try {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final code = result['code']?.toString();
        if (code != null && code != '0000') {
          return PurchaseResult(
            success: false,
            message: result['reason']?.toString() ?? 'فشلت العملية',
            statusCode: response.statusCode,
            rawBody: response.body,
          );
        }
      } catch (_) {
        // Successful non-JSON or different JSON response.
      }
      return PurchaseResult(
        success: true,
        message: 'تم إرسال الطلب بنجاح',
        statusCode: response.statusCode,
        rawBody: response.body,
      );
    }

    return PurchaseResult(
      success: false,
      message: 'فشل الاتصال بالخدمة',
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }
}
