import requests
import json

fakka_products = [
    "Fakka_2.5_Unite",
    "Fakka_4.25_Unite",
    "Fakka_5_Unite",
    "Fakka_6_NewUnite",
    "Fakka_7_Unite",
    "Fakka_9_Unite",
    "Fakka_10_Unite",
    "Fakka_10_NewUnite",
    "Fakka_10.5_Unite",
    "Fakka_11.5_Unite",
    "Fakka_12_Unite",
    "Fakka_12.5_Unite",
    "Fakka_13_Unite",
    "Fakka_13.5_Unite",
    "Fakka_15_Unite",
    "Fakka_15_NewUnite",
    "Fakka_15.5_Unite",
    "Fakka_16.5_Unite",
    "Fakka_17.5_Unite",
    "Fakka_19.5_NewUnite",
    "Fakka_20_Unite",
    "Fakka_26_Unite"
]

mared_products = [
    "Mared_10_Minuts",
    "Mared_10_Flexs",
    "Mared_10_Social"
]

all_products = fakka_products + mared_products


def get_seamless_and_msisdn():
    url = "http://mobile.vodafone.com.eg/checkSeamless/realms/vf-realm/protocol/openid-connect/auth"
    params = {'client_id': "cash-app"}
    headers = {
        'User-Agent': "okhttp/4.12.0", 'Connection': "Keep-Alive", 'Accept-Encoding': "gzip",
        'x-agent-operatingsystem': "16", 'clientId': "AnaVodafoneAndroid", 'Accept-Language': "ar",
        'x-agent-device': "Samsung SM-A165F", 'x-agent-version': "2025.11.1", 'x-agent-build': "1063",
        'digitalId': "", 'device-id': "b26ba335813fad21", 'If-Modified-Since': "Thu, 02 Apr 2026 09:09:07 GMT"
    }
    resp = requests.get(url, params=params, headers=headers)
    if resp.status_code != 200:
        raise Exception("فشل seamlessToken")
    data = resp.json()
    raw_msisdn = data.get("msisdn")
    if raw_msisdn and raw_msisdn.startswith('1'):
        formatted_msisdn = '0' + raw_msisdn
    else:
        formatted_msisdn = raw_msisdn
    return data.get("seamlessToken"), formatted_msisdn


def get_access_token(seamless_token):
    url = "https://mobile.vodafone.com.eg/auth/realms/vf-realm/protocol/openid-connect/token"
    payload = {
        'grant_type': "password",
        'client_secret': "b86e30a8-ae29-467a-a71f-65c73f2ff5e3",
        'client_id': "cash-app"
    }
    headers = {
        'User-Agent': "okhttp/4.12.0", 'Accept': "application/json, text/plain, */*", 'Accept-Encoding': "gzip",
        'silentLogin': "true", 'CRP': "false", 'seamlessToken': seamless_token, 'firstTimeLogin': "true",
        'x-agent-operatingsystem': "16", 'clientId': "AnaVodafoneAndroid", 'Accept-Language': "ar",
        'x-agent-device': "Samsung SM-A165F", 'x-agent-version': "2025.11.1", 'x-agent-build': "1063",
        'digitalId': "", 'device-id': "b26ba335813fad21"
    }
    resp = requests.post(url, data=payload, headers=headers)
    if resp.status_code != 200:
        raise Exception("فشل access_token")
    return resp.json().get("access_token")


# ------------------ تسجيل الدخول ------------------
print("🔄 جاري تسجيل الدخول...")
seamless_token, msisdn_sender = get_seamless_and_msisdn()
print(f"✅ الرقم المرسل: {msisdn_sender}")
access_token = get_access_token(seamless_token)
print("✅ تم الحصول على التوكن")

# ------------------ عرض الكروت ------------------
print("\n📋 قائمة الكروت:")
for i, pid in enumerate(all_products, start=1):
    print(f"{i}. {pid}")

choice = int(input("\n🔢 اختر رقم الكارت: "))
selected_product = all_products[choice - 1]
print(f"✅ تم اختيار: {selected_product}")

# ------------------ إدخال رقم المستلم ------------------
receiver = input("📱 أدخل رقم المستلم: ").strip()
if not (receiver.startswith('01') and len(receiver) == 11 and receiver.isdigit()):
    print("⚠️ تحذير: الرقم قد لا يكون صحيحاً، سيتم المتابعة كما هو.")

# ------------------ إدخال الرقم السري ------------------
pin = input("🔐 الرقم السري لفودافون كاش (6 أرقام): ").strip()
while not (pin.isdigit() and len(pin) == 6):
    pin = input("❌ يجب أن يكون 6 أرقام فقط، حاول مرة أخرى: ").strip()

# ------------------ تحديث التوكن ------------------
print("🔄 تحديث التوكن...")
access_token = get_access_token(seamless_token)

# ------------------ طلب الشراء ------------------
url_order = "https://mobile.vodafone.com.eg/services/dxl/pom/productOrder"

# ✅ الـ payload الصح - نفس هيكل faka.py الأصلي اللي شغال
payload_order = {
    "channel": {"name": "MobileApp"},
    "orderItem": [
        {
            "action": "insert",
            "id": selected_product,
            "product": selected_product,
            "@type": "CashFakkaAndMared",  # ✅ مش ثابت على Fakka_2.5
            "eCode": 0,
            "characteristic": [
                {"name": "PaymentMethod", "value": "VFCash"},
                {"name": "USE_EMONEY", "value": "False"},
                {"name": "MerchantCode", "value": ""}
            ],
            "relatedParty": [
                {"id": msisdn_sender, "name": "MSISDN", "role": "Subscriber"},
                {"id": receiver, "name": "Receiver", "role": "Receiver"}  # ✅ id و role صح
            ]
        }
    ],
    "relatedParty": [
        {"id": pin, "name": "pin", "role": "Requestor"}
    ],
    "@type": "CashFakkaAndMared"
}

headers_order = {
    'User-Agent': "okhttp/4.12.0",
    'Accept': "application/json",
    'Accept-Encoding': "gzip",
    'api-host': "ProductOrderingManagement",
    'useCase': "CashFakkaAndMared",
    'X-Request-ID': "bb81cbe5-0c77-4673-945e-d2c0de90007a",
    'device-id': "b26ba335813fad21",
    'api-version': "v2",
    'msisdn': msisdn_sender,
    'Authorization': f"Bearer {access_token}",
    'Accept-Language': "ar",
    'x-agent-operatingsystem': "16",
    'clientId': "AnaVodafoneAndroid",
    'x-agent-device': "Samsung SM-A165F",
    'x-agent-version': "2025.11.1",
    'x-agent-build': "1063",
    'digitalId': "",
    'Content-Type': "application/json; charset=UTF-8"
}

print("\n🔄 جاري تنفيذ عملية الشراء...")
# ✅ json=payload بدل data=json.dumps(payload)
resp = requests.post(url_order, json=payload_order, headers=headers_order)
print("\n📦 الرد:")
print(resp.text)

if resp.status_code == 200:
    try:
        result = resp.json()
        if "code" in result and result["code"] != "0000":
            print("⚠️ فشلت العملية: " + result.get("reason", "خطأ غير معروف"))
        else:
            print("✅ تم إرسال الطلب بنجاح!")
    except:
        print("✅ تم الاستلام")
else:
    print("❌ فشل الاتصال")
