/*
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class Mqtt {

  static const int port = 1883;
  static const String broker = "hassio.gsotgroup.vn";
  static const String clientId = "Client";
  static const String userName = "GSOT";
  static const String passWord = "smartthing";

  MqttServerClient mqttClient =
  MqttServerClient.withPort(broker, clientId, port);
  MqttConnectionState connectionState;

  connect() async {
    int reLoad = 0;
    mqttClient.port = port;
    mqttClient.logging(on: true);
    mqttClient.keepAlivePeriod = 30;

    mqttClient.onDisconnected = onDisConnect;
    mqttClient.onConnected = onConnected;
    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(30);
    //  .withWillQos(MqttQos.atLeastOnce);
    mqttClient.connectionMessage = connectMessage;
    print(connectMessage);
    try {
      await mqttClient.connect(userName, passWord);
    } catch (e) {
      disConnect();
      return false;
    }
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      connectionState = mqttClient.connectionStatus.state;
      return true;
    } else {
      if(reLoad == 0) {
        connect();
        reLoad++;
      } else disConnect();
    }
  }

  void disConnect() {
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected ||
        mqttClient.connectionStatus.state == MqttConnectionState.connecting) {
      mqttClient.disconnect();
      onDisConnect();
    } else {
      print("[MQTT client] Client is not connect");
    }
  }

  void onDisConnect() {
    connectionState = MqttConnectionState.disconnected;
    mqttClient = null;
  }

  void publish(String topic, String message) {
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(message);
      mqttClient.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
    }
  }

  void onConnected() {
    print(
        '[MQTT client] OnConnected client callback - Client connection was successful');
  }
}*/
