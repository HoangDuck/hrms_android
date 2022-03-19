import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/app_value.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/chats_widget/flutter_chat_ui.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';

import '../../widgets/chats_widget/flutter_chat_types/flutter_chat_types.dart' as types;
class ChatsView extends StatefulWidget {
  final dynamic data;

  const ChatsView(this.data);

  @override
  _ChatsViewState createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  List<types.Message> _messages = [];
  types.User _user;
  var _usersData;
  DateFormat _timeFormat = DateFormat('MM/dd/yyyy HH:mm:ss aaa');
  bool _isLoading = true;
  List<dynamic> _listUserParticipant = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    currentPage = 'ChatsView';
  }

  @override
  void dispose() {
    mQttServices.unSubscribe(widget.data['RoomData']['MqttTopic']['v']);
    super.dispose();
  }

  void getCurrentUser() async {
    _usersData = await SecureStorage().userProfile;
    _user = types.User(
        id: _usersData.data['data'][0]['ID'].toString(),
        firstName: _usersData.data['data'][0]['full_name']['v'],
        imageUrl: _usersData.data['data'][0]['avatar']['v']);
    //check is group chat
    if (widget.data['isGroup']) _getAccUserKey();
    _loadMessages();
  }

  _getAccUserKey() async {
    List<String> _listUserID = widget.data['RoomData']['PaticipantUser']['v'].split(';');
    _listUserID.removeWhere((element) => element == _user.id.toString());
    var listUserResponse = await BaseViewModel().callApis(
        {"userID": _createIDParticipant(_listUserID)}, GetOnlyUserProfile, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (listUserResponse.status.code == 200) {
      _listUserParticipant = listUserResponse.data['data'];
    }
  }

  _createIDParticipant(List<String> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i] + (i < user.length - 1 ? ',' : '');
    }
    return participantUser;
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _loadMessages() async {
    List<dynamic> _messageResponse = [];
    var messageResponse = await BaseViewModel().callApis(
        {"IDRoom": widget.data['RoomData']['ID']}, chatMessageWithIDRoom, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (messageResponse.status.code == 200) {
      for (var i = messageResponse.data['data'].length - 1; i >= 0; i--) {
        var stepResponse = messageResponse.data['data'][i];
        if (stepResponse['HideWithUser']['v'] != _user.id) {
          _messageResponse.add({
            "author": {
              "firstName": stepResponse['full_name']['v'],
              "id": stepResponse['IDUserSent']['v'],
              "imageUrl": stepResponse['avatar']['v'] != '' ? '$avatarUrl${stepResponse['avatar']['v']}' : null
            },
            "createdAt": (_timeFormat.parse(stepResponse['DateTimeSent']['v']).microsecondsSinceEpoch / 1000).round(),
            "id": stepResponse['ID'],
            "status": stepResponse['MessageStatus']['v'],
            "text": stepResponse['MessageText']['v'],
            "type": stepResponse['MessageTypes']['v'],
            "uri":
                "$avatarUrlAPIs${stepResponse[stepResponse['MessageTypes']['v'] == 'image' ? 'ImageUrl' : 'FileUrl']['v']}",
            "width": 1128,
            "mimeType": stepResponse['MimeType']['v'],
            "name": stepResponse['FileName']['v'],
            "size": stepResponse['FileSize'] != null && stepResponse['FileSize']['v'] != ''
                ? num.parse(stepResponse['FileSize']['v'])
                : null
          });

          //update message status
          if (i == messageResponse.data['data'].length - 1 &&
              stepResponse['IDUserSent']['v'] != _user.id &&
              stepResponse['MessageStatus']['v'] != 'seen') {
            await BaseViewModel().callApis(
                {"roomID": widget.data['RoomData']['ID'], "userID": _user.id}, UpdateMessageStatus, method_post,
                isNeedAuthenticated: true, shouldSkipAuth: false);
            mQttServices.publish(
                widget.data['RoomData']['MqttTopic']['v'],
                jsonEncode({
                  'EventType': 'status',
                  'IDUserSent': _user.id,
                  'MessageID': stepResponse['ID'],
                  'MessageTypes': stepResponse['MessageTypes']['v']
                }));
          }
        }
      }
      final messages = _messageResponse.map((e) => types.Message.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
    await _connect();
  }

  _connect() async {
    mQttServices.subscribe(widget.data['RoomData']['MqttTopic']['v']);
    mQttServices.mqttClient.updates.listen((event) async {
      var message = await mQttServices.onMessage(event);
      if (event[0].topic == widget.data['RoomData']['MqttTopic']['v']) {
        var _messageResponse = await jsonDecode(message);
        if (_messageResponse['IDUserSent'] == _usersData.data['data'][0]['ID']) return;
        String _eventType = _messageResponse['EventType'];
        switch (_eventType) {
          case 'insert':
            _messages.insert(
                0,
                types.Message.fromJson({
                  "author": {
                    "firstName": _messageResponse['SenderName'],
                    "id": _messageResponse['IDUserSent'].toString(),
                    "imageUrl": _messageResponse['Avatar'] != '' ? '$avatarUrl${_messageResponse['Avatar']}' : null
                  },
                  "createdAt": (DateFormat('MM/dd/yyyy HH:mm:ss')
                              .parse(_messageResponse['DateTimeSent'])
                              .microsecondsSinceEpoch /
                          1000)
                      .round(),
                  "id": _messageResponse['MessageID'],
                  "status": 'seen',
                  "text": _messageResponse['MessageText'],
                  "type": _messageResponse['MessageTypes'],
                  "uri":
                      "$avatarUrlAPIs${_messageResponse[_messageResponse['MessageTypes'] == 'image' ? 'MessageImage' : 'MessageFile']}",
                  "width": 1128,
                  "mimeType": _messageResponse['MimeType'],
                  "name": _messageResponse['FileName'],
                  "size": _messageResponse['FileSize']
                }));
            await BaseViewModel().callApis({
              "tbname": 'xy3hrQRA0dCFocFVVX5yLA==', //tb_chat_message
              "dataid": _messageResponse['MessageID'],
              "MessageStatus": "seen"
            }, updateDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
            mQttServices.publish(
                widget.data['RoomData']['MqttTopic']['v'],
                jsonEncode({
                  'EventType': 'status',
                  'IDUserSent': _user.id,
                  'MessageID': _messageResponse['MessageID'],
                  'MessageTypes': _messageResponse['MessageTypes']
                }));
            break;
          case 'delete':
            _messages.removeWhere((element) => element.id == _messageResponse['MessageID']);
            break;
          case 'update':
            int index = _messages.indexWhere((item) => item.id == _messageResponse['MessageID']);
            dynamic _editMessage = _messages[index];
            _editMessage = {
              "author": {
                "firstName": _editMessage.author.firstName,
                "id": _editMessage.author.id,
                "imageUrl": _editMessage.author.imageUrl
              },
              "createdAt": _editMessage.createdAt,
              "id": _editMessage.id,
              "status": 'seen',
              "text": _messageResponse['MessageText'],
              "type": 'text'
            };
            _messages[index] = types.Message.fromJson(_editMessage);
            break;
          case 'status':
            int index = _messages.indexWhere((item) => item.id == _messageResponse['MessageID']);
            dynamic _editMessage = _messages[index];
            _editMessage = {
              "author": {
                "firstName": _editMessage.author.firstName,
                "id": _editMessage.author.id,
                "imageUrl": _editMessage.author.imageUrl
              },
              "createdAt": _editMessage.createdAt,
              "id": _editMessage.id,
              "status": 'seen',
              if (_editMessage.type == types.MessageType.text) "text": _editMessage.text,
              if (_editMessage.type != types.MessageType.text) "uri": _editMessage.uri,
              "width": 1128,
              "type": _editMessage.type.toString().split('.')[1],
              if (_editMessage.type == types.MessageType.file) "mimeType": _editMessage.mimeType,
              if (_editMessage.type != types.MessageType.text) "name": _editMessage.name,
              if (_editMessage.type != types.MessageType.text) "size": _editMessage.size
            };
            _messages[index] = types.Message.fromJson(_editMessage);
            break;
          case 'deleteUser':
            if(_messageResponse['IDUserDelete'] == _user.id)
              Navigator.pop(context, 'deleteUser');
        }
        if (mounted) setState(() {});
      }
    });
  }

  void _handleFileSelection() async {
    FilePickerResult file = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false
    );
    List<File> _listFile = file.paths.map((path) => File(path)).toList();

    if(_listFile.length == 0)
      return;

    File result = _listFile[0];

    if (result.length != null && result.path != null) {
      bool _isFail = true;

      List<http.MultipartFile> multipartFile = [];
      var stream =
          // ignore: deprecated_member_use
          http.ByteStream(DelegatingStream.typed(result.openRead()));
      var length = await result.length();
      var _multipartFile = http.MultipartFile('FileUrl', stream, length, filename: path.basename(result.path));
      multipartFile.add(_multipartFile);
      var response = await _addDataApis(
          file: multipartFile,
          type: 'file',
          mimeType: lookupMimeType(result.path),
          fileName: path.basename(result.path),
          fileSize: result.lengthSync());

      if (response.status.code == 200) {
        _isFail = false;

        dynamic jsonMessage = {
          'EventType': 'insert',
          'MessageID': response.data['data'][0]['dataid'].toString(),
          'IDUserSent': _usersData.data['data'][0]['ID'],
          'SenderName': _usersData.data['data'][0]['full_name']['v'],
          'Avatar': _usersData.data['data'][0]['avatar']['v'],
          'MessageFile': response.data['data'][0]['FileUrl'],
          'MessageTypes': 'file',
          'DateTimeSent': DateFormat('MM/dd/yyyy HH:mm:ss aaa').format(DateTime.now()),
          'MimeType': lookupMimeType(result.path),
          'FileName': path.basename(result.path),
          'FileSize': result.lengthSync(),
        };
        mQttServices.publish(widget.data['RoomData']['MqttTopic']['v'], jsonEncode(jsonMessage));
        mQttServices.publish("GSCHAT", "#${_user.id}/${widget.data['RoomData']['ID']}");

        _pushNotification(title: _usersData.data['data'][0]['full_name']['v'], body: 'Đã gửi file cho bạn');
      }

      final message = types.FileMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: response.data['data'][0]['dataid'].toString(),
          mimeType: lookupMimeType(result.path),
          name: path.basename(result.path),
          size: result.lengthSync(),
          uri: result.path,
          status: _isFail ? types.Status.error : types.Status.delivered);

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().getImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      bool _isFail = true;
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      var response = await _addDataApis(
          imageBase64: base64.encode(bytes),
          type: 'image',
          fileName: path.basename(result.path),
          fileSize: bytes.length);

      if (response.status.code == 200) {
        _isFail = false;
        dynamic jsonMessage = {
          'EventType': 'insert',
          'MessageID': response.data['data'][0]['dataid'].toString(),
          'IDUserSent': _usersData.data['data'][0]['ID'],
          'SenderName': _usersData.data['data'][0]['full_name']['v'],
          'Avatar': _usersData.data['data'][0]['avatar']['v'],
          'MessageImage': response.data['data'][0]['ImageUrl'],
          'MessageTypes': 'image',
          'DateTimeSent': DateFormat('MM/dd/yyyy HH:mm:ss aaa').format(DateTime.now()),
          'FileName': path.basename(result.path),
          'FileSize': bytes.length,
        };
        mQttServices.publish(widget.data['RoomData']['MqttTopic']['v'], jsonEncode(jsonMessage));
        mQttServices.publish("GSCHAT", "#${_user.id}/${widget.data['RoomData']['ID']}");

        _pushNotification(title: _usersData.data['data'][0]['full_name']['v'], body: 'Đã gửi ảnh cho bạn');
      }

      final message = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height.toDouble(),
          id: response.data['data'][0]['dataid'].toString(),
          name: path.basename(result.path),
          size: bytes.length,
          uri: result.path,
          width: image.width.toDouble(),
          status: _isFail ? types.Status.error : types.Status.delivered);

      _addMessage(message);
    }
  }

  void _handleMessageTap(types.Message message) async {
    if (message is types.FileMessage) {
      VideoPlayerController _controller;
      if (message.mimeType.contains('video')) {
        _controller = VideoPlayerController.network(message.uri)
          ..initialize().then((_) {
            showCupertinoDialog(
                context: context,
                builder: (context) {
                  return Theme(
                      data: ThemeData(
                        cupertinoOverrideTheme: CupertinoThemeData(brightness: Brightness.light),
                      ),
                      child: CupertinoAlertDialog(
                        content: _controller.value.isInitialized
                            ? StatefulBuilder(builder: (context, state) {
                                return GestureDetector(
                                  onTap: () {
                                    if (!_controller.value.isPlaying)
                                      _controller.play();
                                    else
                                      _controller.pause();
                                    state(() {});
                                  },
                                  child: AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: Stack(
                                      children: [
                                        VideoPlayer(_controller),
                                        !_controller.value.isPlaying
                                            ? Center(
                                                child: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.grey.withOpacity(0.8),
                                                  size: 80,
                                                ),
                                              )
                                            : SizedBox.shrink()
                                      ],
                                    ),
                                  ),
                                );
                              })
                            : Container(),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: Text('Đóng'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      ));
                }).then((value) {
              Future.delayed(Duration(seconds: 2), () => _controller.dispose());
            });
          });
      } else
        await OpenFile.open(message.uri);
    }
  }

  void _handleMessageLongPressDetail(LongPressStartDetails details, types.Message message) async {
    _showPopupMenu(details.globalPosition, message);
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    bool _isFail = true;
    var response = await _addDataApis(message: message, type: 'text');

    if (response.status.code == 200) {
      _isFail = false;
      dynamic jsonMessage = {
        'EventType': 'insert',
        'MessageID': response.data['data'][0]['dataid'].toString(),
        'IDUserSent': _usersData.data['data'][0]['ID'],
        'SenderName': _usersData.data['data'][0]['full_name']['v'],
        'Avatar': _usersData.data['data'][0]['avatar']['v'],
        'MessageText': message.text,
        'MessageTypes': 'text',
        'DateTimeSent': DateFormat('MM/dd/yyyy HH:mm:ss aaa').format(DateTime.now())
      };
      mQttServices.publish(widget.data['RoomData']['MqttTopic']['v'], jsonEncode(jsonMessage));
      mQttServices.publish("GSCHAT", "#${_user.id}/${widget.data['RoomData']['ID']}");

      _pushNotification(title: _usersData.data['data'][0]['full_name']['v'], body: message.text);
    }
    final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: response.data['data'][0]['dataid'].toString(),
        text: message.text,
        status: _isFail ? types.Status.error : types.Status.delivered);

    _addMessage(textMessage);
  }

  _pushNotification({String title, String body}) async {
    String accUserKey = await SecureStorage().pushToken;
    dynamic data = {
      'isGroup': widget.data['isGroup'],
      'RoomData': {
        "ID": widget.data['RoomData']['ID'],
        'MqttTopic': widget.data['RoomData']['MqttTopic'],
        if (widget.data['isGroup']) 'AvaGroup': widget.data['RoomData']['AvaGroup'],
        if (widget.data['isGroup']) 'RoomName': widget.data['RoomData']['RoomName'],
        if (!widget.data['isGroup'])
          'ChatUser': {
            'ID': _usersData.data['data'][0]['ID'],
            'full_name': _usersData.data['data'][0]['full_name'],
            'avatar': _usersData.data['data'][0]['avatar'],
            'AccUserKey': {'v': accUserKey}
          }
      }
    };

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAA4SPuNic:APA91bFKpI5f-vohW67kBkjzCBO7o1xhsteCnsghw5ntQVmBou2mZvHN5htcoioZwVx34HCG6ger4aMEjrs3k3yM3-bMgQYL2qMUCI-gh6JGSORT0I7AnGCUzfcgEFkps-l4xjNAQlYV'
      },
      body: jsonEncode(<String, Object>{
        "notification": {
          "title": title,
          "body": body,
          "content_available": true,
          "icon": "app_icon_local_notification",
          "sound": "default",
          "alert": true
        },
        "priority": "high",
        "data": {
          "notification_types": "chat_message",
          "room_data": data,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "title": title,
          "body": body,
          "vi": "",
          "type": "4",
          "navigator": "chatHome",
          "html": "",
          "buttons": []
        },
        if (widget.data['isGroup'])
          "condition": _formatListUserKey()
        else
          "to": "/topics/${widget.data['RoomData']["ChatUser"]['AccUserKey']['v']}"
      }),
    );
  }

  _formatListUserKey() {
    String topics = '';
    for (int i = 0; i < _listUserParticipant.length; i++) {
      topics = topics +
          '\'${_listUserParticipant[i]['AccUserKey']['v'].replaceAll(new RegExp(r'[^\w\s]+'), '')}\'' +
          (i < _listUserParticipant.length - 1 ? ' in topics || ' : ' in topics');
    }
    return topics;
  }

  _addDataApis(
      {types.PartialText message,
      String imageBase64,
      List<http.MultipartFile> file,
      String type,
      String mimeType,
      int fileSize,
      String fileName}) async {
    var response = await BaseViewModel().callApis({
      "tbname": 'xy3hrQRA0dCFocFVVX5yLA==', //tb_chat_message
      "IDRoom": widget.data['RoomData']['ID'],
      "IDUserSent": _usersData.data['data'][0]['ID'],
      "DateTimeSent": DateFormat('yyyy-MM-dd HH:mm:ss.sss').format(DateTime.now()),
      "MessageTypes": type,
      "MessageStatus": 'delivered',
      if (mimeType != null) "MimeType": mimeType,
      if (fileName != null) "FileName": fileName,
      if (fileSize != null) "FileSize": fileSize.toString(),
      if (message != null) "MessageText": message.text,
      if (imageBase64 != null) "ImageUrl": 'data:image/jpeg;base64,$imageBase64'
    }, addDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false, multipartFile: file, isMultiPart: file != null);
    return response;
  }

  _showPopupMenu(Offset offset, types.Message message) async {
    double left = offset.dx;
    double top = offset.dy;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
      items: [
        PopupMenuItem<String>(
            child: Row(
              children: [
                Image.asset(
                  'images/chat_images/icon-delete.png',
                  color: txt_fail_color,
                  height: 24,
                  width: 24,
                ),
                SizedBox(
                  width: 20,
                ),
                TKText('Xóa'),
              ],
            ),
            value: 'delete'),
        if (message.type == types.MessageType.text && message.author.id == _user.id)
          PopupMenuItem<String>(
              child: Row(
                children: [
                  Image.asset('images/chat_images/icon-edit.png', height: 24, width: 24, color: txt_orange_color),
                  SizedBox(
                    width: 20,
                  ),
                  TKText('Sửa'),
                ],
              ),
              value: 'edit')
      ],
      elevation: 8.0,
    ).then((value) {
      switch (value) {
        case 'delete':
          _deleteMessage(message);
          break;
        case 'edit':
          _editMessage(message);
          break;
        default:
          print('none');
      }
    });
  }

  _deleteMessage(types.Message message) async {
    bool _isCurrentUser = message.author.id == _user.id;
    var response = await BaseViewModel().callApis({
      "tbname": 'xy3hrQRA0dCFocFVVX5yLA==',
      "dataid": message.id,
      if (!_isCurrentUser) "HideWithUser": _user.id
    }, _isCurrentUser ? deleteDataUrl : updateDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      if (_isCurrentUser)
        mQttServices.publish(widget.data['RoomData']['MqttTopic']['v'],
            jsonEncode({'EventType': 'delete', 'IDUserSent': _user.id, 'MessageID': message.id}));
      _messages.removeWhere((element) => element.id == message.id);
      setState(() {});
    }
  }

  _editMessage(dynamic message) async {
    final _textController = TextEditingController();
    _textController.text = message.text;
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return Theme(
              data: ThemeData(
                cupertinoOverrideTheme: CupertinoThemeData(brightness: Brightness.light),
              ),
              child: CupertinoAlertDialog(
                content: CupertinoTextField(
                  controller: _textController,
                  cursorColor: Colors.red,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text('Sửa'),
                    onPressed: () async {
                      int index = _messages.indexWhere((item) => item.id == message.id);
                      dynamic _editMessage = _messages[index];
                      _editMessage = {
                        "author": {
                          "firstName": _editMessage.author.firstName,
                          "id": _editMessage.author.id,
                          "imageUrl": _editMessage.author.imageUrl
                        },
                        "createdAt": _editMessage.createdAt,
                        "id": _editMessage.id,
                        "status": "seen",
                        "text": _textController.text,
                        "type": 'text'
                      };
                      setState(() => _messages[index] = types.Message.fromJson(_editMessage));
                      await _updateMessage(_messages[index]);
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoDialogAction(
                    child: Text('Hủy'),
                    onPressed: () {
                      _textController.dispose();
                      Navigator.pop(context);
                    },
                  )
                ],
              ));
        });
  }

  _updateMessage(dynamic message) async {
    var response = await BaseViewModel().callApis({
      "tbname": 'xy3hrQRA0dCFocFVVX5yLA==',
      "dataid": message.id,
      "MessageText": message.text
    }, updateDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      mQttServices.publish(
          widget.data['RoomData']['MqttTopic']['v'],
          jsonEncode(
              {'EventType': 'update', 'IDUserSent': _user.id, 'MessageID': message.id, 'MessageText': message.text}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        currentPage = null;
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: SafeArea(
          bottom: false,
          child: !_isLoading
              ? Chat(
                  showUserAvatars: true,
                  showUserNames: true,
                  messages: _messages,
                  dateLocale: 'vi',
                  timeFormat: DateFormat('HH:mm'),
                  onMessageTap: _handleMessageTap,
                  onMessageLongPressDetail: _handleMessageLongPressDetail,
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  onImagePressed: _handleImageSelection,
                  onFilePressed: _handleFileSelection,
                  user: _user,
                )
              : Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => AppBar(
        /*leading: GestureDetector(
            onTap: () {
              currentPage = null;
              Navigator.pop(context, true);
            },
            child: Padding(
                padding: EdgeInsets.all(17),
                child: Image.asset(
                  ic_back,
                  color: white_color,
                ))),*/
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: <Color>[gradient_end_color, gradient_start_color])),
        ),
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            GestureDetector(
                onTap: () {
                  currentPage = null;
                  Navigator.pop(context, true);
                },
                child: Image.asset(
                  ic_back,
                  width: kToolbarHeight * 0.4,
                  height: kToolbarHeight * 0.4,
                  color: white_color,
                )),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 30),
            ),
            CircleAvatar(
              maxRadius: 22,
              backgroundColor: (widget.data['isGroup']
                          ? widget.data['RoomData']['AvaGroup']['v']
                          : widget.data['RoomData']["ChatUser"]['avatar']['v']) !=
                      ''
                  ? Colors.transparent
                  : Colors.white,
              child: (widget.data['isGroup']
                          ? widget.data['RoomData']['AvaGroup']['v']
                          : widget.data['RoomData']["ChatUser"]['avatar']['v']) !=
                      ''
                  ? CachedNetworkImage(
                      imageUrl: avatarUrlAPIs +
                          (widget.data['isGroup']
                              ? widget.data['RoomData']['AvaGroup']['v']
                              : widget.data['RoomData']["ChatUser"]['avatar']['v']),
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 1, color: only_color),
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                      placeholder: (context, url) => CupertinoTheme(
                        data: CupertinoTheme.of(context).copyWith(brightness: Brightness.dark),
                        child: CupertinoActivityIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : TKText(
                      (widget.data['isGroup']
                              ? widget.data['RoomData']['RoomName']['v']
                              : widget.data['RoomData']["ChatUser"]['full_name']['v'])
                          .toString()
                          .substring(0, 1),
                      tkFont: TKFont.SFProDisplayBold,
                      style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 40), color: only_color),
                    ),
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.data['isGroup']
                        ? widget.data['RoomData']['RoomName']['v']
                        : widget.data['RoomData']["ChatUser"]['full_name']['v'],
                    style: appBarTextStyle(Utils.resizeWidthUtil(context, app_bar_font_size))),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Routers.chatManageMemberView, arguments: {
                      'RoomData': widget.data['RoomData'],
                      'ListUser': _listUserParticipant
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.data['isGroup'])
                        Icon(
                          CupertinoIcons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      if (widget.data['isGroup'])
                        SizedBox(
                          width: 5,
                        ),
                      Text(widget.data['isGroup'] ? '${_listUserParticipant.length + 1} thành viên' : 'Trực tuyến',
                          style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 25))),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
        actions: <Widget>[
          InkWell(
            child: Image.asset(
              'images/chat_images/icon-list.png',
              height: Utils.resizeWidthUtil(context, app_bar_icon_size - 5),
              width: Utils.resizeWidthUtil(context, app_bar_icon_size - 5),
              color: icon_app_bar_color,
            ),
            //Icon(Icons.list, color: icon_app_bar_color, size: Utils.resizeWidthUtil(context, app_bar_icon_size)),
            onTap: () {
              Navigator.pushNamed(context, Routers.chatOptionView, arguments: widget.data);
            },
          ),
          SizedBox(
            width: 10.0,
          )
        ],
      );
}
