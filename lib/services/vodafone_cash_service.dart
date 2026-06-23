import 'package:dio/dio.dart';
import 'dart:convert';

class LoginResult {
  final String seamlessToken;
  final String senderMsisdn;
  LoginResult({required this.seamlessToken, required this.senderMsisdn});
}

class PurchaseResult {
  final bool success;
  final String message;
  PurchaseResult({required this.success, required this.message});
}

class VodafoneCashService {
  // Use Dio to perfectly match Python's requests behavior
  final Dio _dio = Dio(BaseOptions(
    validateStatus: (status) => true, // Don't throw exceptions on 4xx/5xx
  ));

  Future<LoginResult> getSeamlessAndMsisdn() async {
    final url = "http://mobile.vodafone.com.eg/checkSeamless/realms/vf-realm/protocol/openid-connect/auth";
    final resp = await _dio.get(url, 
      queryParameters: {'client_id': "cash-app"},
      options: Options(
        headers: {
          'User-Agent': "okhttp/4.12.0",
          'Connection': "Keep-Alive",
          'Accept-Encoding': "gzip",
          'x-agent-operatingsystem': "16",
          'clientId': "AnaVodafoneAndroid",
          'Accept-Language': "ar",
          'x-agent-device': "Samsung SM-A165F",
          'x-agent-version': "2025.11.1",
          'x-agent-build': "1063",
          'digitalId': "",
          'device-id': "b26ba335813fad21",
          'If-Modified-Since': "Thu, 02 Apr 2026 09:09:07 GMT"
        }
      )
    );

    if (resp.statusCode != 200) throw Exception("فشل seamlessToken: ${resp.statusCode}");

    final data = resp.data;
    final rawMsisdn = data["msisdn"]?.toString();
    final formattedMsisdn = (rawMsisdn != null && rawMsisdn.startsWith('1')) ? '0$rawMsisdn' : rawMsisdn;

    return LoginResult(
      seamlessToken: data["seamlessToken"], 
      senderMsisdn: formattedMsisdn ?? "Unknown"
    );
  }

  Future<String> getAccessToken(String seamlessToken) async {
    final url = "https://mobile.vodafone.com.eg/auth/realms/vf-realm/protocol/openid-connect/token";
    final resp = await _dio.post(url,
      data: {
        'grant_type': "password",
        'client_secret': "b86e30a8-ae29-467a-a71f-65c73f2ff5e3",
        'client_id': "cash-app"
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'User-Agent': "okhttp/4.12.0",
          'Accept': "application/json, text/plain, */*",
          'Accept-Encoding': "gzip",
          'silentLogin': "true",
          'CRP': "false",
          'seamlessToken': seamlessToken,
          'firstTimeLogin': "true",
          'x-agent-operatingsystem': "16",
          'clientId': "AnaVodafoneAndroid",
          'Accept-Language': "ar",
          'x-agent-device': "Samsung SM-A165F",
          'x-agent-version': "2025.11.1",
          'x-agent-build': "1063",
          'digitalId': "",
          'device-id': "b26ba335813fad21"
        }
      )
    );

    if (resp.statusCode != 200) throw Exception("فشل access_token: ${resp.statusCode}");
    return resp.data["access_token"];
  }

  Future<PurchaseResult> purchaseProduct({
    required String selectedProduct,
    required String receiver,
    required String pin,
    required String seamlessToken,
    required String senderMsisdn,
  }) async {
    final accessToken = await getAccessToken(seamlessToken);
    final url = "https://mobile.vodafone.com.eg/services/dxl/pom/productOrder";

    // Exact payload from Python
    final payloadOrder = {
        "channel": {"name": "MobileApp"},
        "orderItem": [
            {
                "action": "insert",
                "id": selectedProduct,
                "product": selectedProduct,
                "@type": "CashFakkaAndMared",
                "eCode": 0,
                "characteristic": [
                    {"name": "PaymentMethod", "value": "VFCash"},
                    {"name": "USE_EMONEY", "value": "False"},
                    {"name": "MerchantCode", "value": ""}
                ],
                "relatedParty": [
                    {"id": senderMsisdn, "name": "MSISDN", "role": "Subscriber"},
                    {"id": receiver, "name": "Receiver", "role": "Receiver"}
                ]
            }
        ],
        "relatedParty": [
            {"id": pin, "name": "pin", "role": "Requestor"}
        ],
        "@type": "CashFakkaAndMared"
    };

    final resp = await _dio.post(url,
      data: payloadOrder,
      options: Options(
        contentType: "application/json; charset=UTF-8",
        headers: {
          'User-Agent': "okhttp/4.12.0",
          'Accept': "application/json",
          'Accept-Encoding': "gzip",
          'api-host': "ProductOrderingManagement",
          'useCase': "CashFakkaAndMared",
          'X-Request-ID': "bb81cbe5-0c77-4673-945e-d2c0de90007a", // Exact hardcoded UUID from python
          'device-id': "b26ba335813fad21",
          'api-version': "v2",
          'msisdn': senderMsisdn,
          'Authorization': "Bearer $accessToken",
          'Accept-Language': "ar",
          'x-agent-operatingsystem': "16",
          'clientId': "AnaVodafoneAndroid",
          'x-agent-device': "Samsung SM-A165F",
          'x-agent-version': "2025.11.1",
          'x-agent-build': "1063",
          'digitalId': "",
        }
      )
    );

    if (resp.statusCode == 200) {
      try {
        final result = resp.data is String ? jsonDecode(resp.data) : resp.data;
        if (result["code"] != null && result["code"] != "0000") {
          return PurchaseResult(success: false, message: result["reason"] ?? "خطأ غير معروف");
        } else {
          return PurchaseResult(success: true, message: "تم إرسال الطلب بنجاح!");
        }
      } catch (e) {
        return PurchaseResult(success: true, message: "تم الاستلام بنجاح");
      }
    } else {
      return PurchaseResult(success: false, message: "فشل الاتصال: ${resp.statusCode}");
    }
  }
}
