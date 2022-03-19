import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:gsot_timekeeping/core/mqtt/mqtt_config.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class Mqtt {
  MqttServerClient mqttClient;

  MqttConnectionState connectionState;
  static String broker = MQTTConfig.broker;
  static int port = MQTTConfig.port;
  static String username = MQTTConfig.userName;
  static String password = MQTTConfig.passWord;
  static Future<String> clientId = MQTTConfig.clientId;

  Mqtt._privateConstructor();

  static final Mqtt mQttServices = Mqtt._privateConstructor();

  void init() async {
    var client = await SecureStorage().clientID;
    mqttClient = MqttServerClient.withPort(broker, client, port);
    mqttClient.port = port;
    mqttClient.logging(on: true);
    mqttClient.keepAlivePeriod = 10000;
    mqttClient.onDisconnected = onDisConnect;
    mqttClient.onConnected = onConnected;
    mqttClient.autoReconnect = true;

    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .withClientIdentifier(client)
        .startClean()
        .keepAliveFor(30)
        .withWillQos(MqttQos.atLeastOnce);
    mqttClient.connectionMessage = connectMessage;

    await connect();
  }

  connect(/*String topic, String keepOnline*/) async {
    if(mqttClient.connectionStatus.state != MqttConnectionState.connected) {
      try {
        var result = await mqttClient.connect(username, password);
        print('MQTT CONNECT RESULT: ${result.state}');
        if(result.state == MqttConnectionState.connected)
          connectionState = mqttClient.connectionStatus.state;
      } catch (e) {
        disConnect();
      }
    }
    //subscribe(topic);
    //Timer.periodic(Duration(seconds: 15), (Timer t) => publish(keepOnline, "ON"));
  }

  void disConnect() {
    debugPrint('MQTT run disConnect');
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected ||
        mqttClient.connectionStatus.state == MqttConnectionState.connecting) {
      mqttClient.disconnect();
      onDisConnect();
    } else {
      debugPrint("[MQTT client] disconnect failed");
    }
  }

  void onDisConnect() {
    debugPrint('[MQTT client] run onDisConnect');
    connectionState = MqttConnectionState.disconnected;
    mqttClient = null;
  }

  void publish(String topic, String message) {
    debugPrint("[MQTT client] Publish to topic $topic message $message");
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addUTF8String(message);
      mqttClient.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
    }
  }

  void subscribe(String topic) async {
    debugPrint("[MQTT client] Subscribe to $topic");
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      mqttClient.subscribe(topic, MqttQos.exactlyOnce);
    }
  }

  void unSubscribe(String topic) async {
    debugPrint("[MQTT client] unSubscribe from $topic");
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      mqttClient.unsubscribe(topic);
    }
  }

  Future<String> onMessage(List<MqttReceivedMessage> event) async {
    debugPrint("[MQTT client] run onMessage");
    final MqttPublishMessage recMessage = event[0].payload as MqttPublishMessage;
    final String message = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
    String decoder = utf8.decode(message.runes.toList());
    return decoder;
  }

  void onConnected() {
    debugPrint('[MQTT client] OnConnected client callback - Client connection was Successful');
  }
}
