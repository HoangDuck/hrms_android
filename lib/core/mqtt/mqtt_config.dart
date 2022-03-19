import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';

class MQTTConfig {
//  static String broker = "soldier.cloudmqtt.com";
//  static String clientId = "Redmi Note 8";
//  static int port = 10189;
//  static String userName = "edayqhwn";
//  static String passWord = "dkSoYDnivMmD";
  static String broker = "hassio2.gsotgroup.vn";
  static Future<String> clientId = SecureStorage().clientID;
  static int port = 1883;
  static String userName = "GSOT";
  static String passWord = "smartthing";
}
