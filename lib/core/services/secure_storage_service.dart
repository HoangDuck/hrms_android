import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';

class SecureStorage {
  static const String API_TOKEN = "apiToken";
  static const String FCM_TOKEN = "fcmToken";
  static const String PUSH_TOKEN = 'pushToken';
  static const String IS_FIRST_TIME = "is_first_time";
  static const String PROFILE_CUSTOMER = "profile_customer";
  static const String WIFI_INFO = "wifi_info";
  static const String PASSWORD = "password";
  static const String USERNAME = "username";
  static const String CHANGE_PASSWORD = "change_password";
  static const String IS_USING_AUTHORIZATION = "is_using_authorization";
  static const String COMPANY_INFO = "company_info";
  static const String SOCIAL_LOGIN = "social_login";
  static const String FACE_ID_LOGIN = "face_id_login";
  static const String QR_CODE = 'qr_code';
  static const String NFC = 'nfc';
  static const String TENSOR_FLOW = 'tensor_flow';
  static const String GOOGLE_KEY = 'google_key';
  static const String IS_WEB_VIEW = 'is_web_view';
  static const String ClientID = 'clientid';

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String> get apiToken async =>
      await _secureStorage.read(key: API_TOKEN);

  Future<String> get fcmToken async =>
      await _secureStorage.read(key: FCM_TOKEN);

  Future<String> get pushToken async =>
      await _secureStorage.read(key: PUSH_TOKEN);

  Future<BaseResponse> get userProfile async => await _secureStorage
      .read(key: PROFILE_CUSTOMER)
      .then<BaseResponse>((response) => response != null
          ? BaseResponse.fromJson(json.decode(response))
          : null);

  Future<dynamic> get companyInfo async =>
      await _secureStorage.read(key: COMPANY_INFO);

  Future<String> get isWebView async =>
      await _secureStorage.read(key: IS_WEB_VIEW);

  Future<String> get clientID async =>
      await _secureStorage.read(key: ClientID);

  saveApiToken(String token) async {
    await _secureStorage.write(key: API_TOKEN, value: token);
  }

  saveFcmToken(String fcmToken) async {
    await _secureStorage.write(key: FCM_TOKEN, value: fcmToken);
  }

  savePushToken(String pushToken) async {
    await _secureStorage.write(key: PUSH_TOKEN, value: pushToken);
  }

  saveIsWebView() async {
    await _secureStorage.write(key: IS_WEB_VIEW, value: 'true');
  }

  saveProfileCustomer(BaseResponse baseResponse) async {
    await _secureStorage.write(
        key: PROFILE_CUSTOMER, value: json.encode(baseResponse));
  }

  saveIsFirstTime() async {
    await _secureStorage.write(key: IS_FIRST_TIME, value: 'false');
  }

  saveCompanyInfo(String data) async {
    await _secureStorage.write(key: COMPANY_INFO, value: data);
  }

  saveClientID(String clientID) async {
    await _secureStorage.write(key: ClientID, value: clientID);
  }

  Future<bool> isLogin() async {
    final userProfileResult = await _secureStorage.read(key: PROFILE_CUSTOMER);
    return userProfileResult?.isNotEmpty;
  }

  Future<bool> isFirstTime() async {
    final isFirstTime = await _secureStorage.read(key: IS_FIRST_TIME);
    return isFirstTime == null || isFirstTime == 'true';
  }

  deleteAllSS() async {
    // Delete all
    await _secureStorage.deleteAll();
  }

  deleteToken() async {
    await _secureStorage.delete(key: API_TOKEN);
  }

  deleteCompany() async {
    await _secureStorage.delete(key: COMPANY_INFO);
  }

  deletePushToken() async {
    await _secureStorage.delete(key: PUSH_TOKEN);
  }

  Future<String> getCustomString(String key) async =>
      await _secureStorage.read(key: key);

  saveCustomString(String key, String data) async {
    await _secureStorage.write(key: key, value: data);
  }

  removeCustomString(String key) async {
    await _secureStorage.delete(key: key);
  }
}
