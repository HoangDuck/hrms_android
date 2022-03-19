import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatEmpView extends StatefulWidget {
  final dynamic data;

  const ChatEmpView(this.data);

  @override
  _ChatEmpViewState createState() => _ChatEmpViewState();
}

class _ChatEmpViewState extends State<ChatEmpView> {
  List<String> _listMessage = List();
  String message = " ";
  TextEditingController _chatMessageController;
  dynamic _users;

  Image chatAvatar;
  ScrollController _scrollController;
  final focusNode = FocusNode();
  bool _showPicker = false;
  var keyboardVisibilityController = KeyboardVisibilityController();
  List<dynamic> _listMessageLoad = List();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    getCurrentUser();
    getListMessage();
    focusNode.addListener(() => print('focusNode updated: hasFocus: ${focusNode.hasFocus}'));
    chatAvatar = Image.network(mainHost + widget.data["ChatUser"]['avatar']['v']);
    _chatMessageController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    focusNode.dispose();
    mQttServices.unSubscribe(widget.data['Room']['MqttTopic']['v']);
    super.dispose();
  }

  void getListMessage() async {
    var messageResponse = await BaseViewModel().callApis(
        {"IDRoom": widget.data['Room']['ID']}, chatMessageWithIDRoom, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (messageResponse.status.code == 200) {
      if (_listMessageLoad.length != 0) {
        setState(() {
          _listMessageLoad.clear();
          _listMessageLoad.addAll(messageResponse.data['data']);
        });
      } else
        setState(() {
          _listMessageLoad.addAll(messageResponse.data['data']);
        });
    }
    addHistoryChat(_listMessageLoad);
  }

  void addHistoryChat(List<dynamic> list) {
    List<String> listTemp = List();
    list.forEach((element) {
      String jsonMessage = '{'
          '"IDUserSent":"${element['IDUserSent']['v']}",'
          '"MessageText":"${element['MessageText']['v']}",'
          // '"TimeSent":"${DateFormat('yyyy-MM-dd HH:mm:ss aaa').format(DateTime.now())}"'
          '"DateTimeSent":"${element['DateTimeSent']['v']}"'
          '}';
      listTemp.add(jsonMessage);
    });
    setState(() {
      _listMessage = listTemp;
    });
  }

  void getCurrentUser() async {
    var users = await SecureStorage().userProfile;
    _users = users.data['data'][0];
    _connect();
  }

  _connect() async {
    mQttServices.subscribe(widget.data['Room']['MqttTopic']['v']);
    mQttServices.mqttClient.updates.listen((event) async {
      message = await mQttServices.onMessage(event);
      if (event[0].topic == widget.data['Room']['MqttTopic']['v']) {
        _listMessage.add(message);
        if (_scrollController.hasClients)
          _scrollController.animateTo(_scrollController.position.maxScrollExtent + 500,
              duration: Duration(milliseconds: 10), curve: Curves.fastOutSlowIn);
        try {
          await BaseViewModel().callApis({
            "tbname": 'xy3hrQRA0dDamQvkcYX2/w==', //tb_chat_room
            "dataid": widget.data['Room']['ID'],
            "HaveSeen": "TRUE",
            "HaveSeenCount": 0
          }, updateDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
        } catch (e) {
          debugPrint(e);
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: main_background,
        appBar: AppBar(
          leading: InkWell(
              onTap: () => Navigator.pop(context),
              child: Padding(
                  padding: EdgeInsets.all(17),
                  child: Image.asset(
                    ic_back,
                    color: white_color,
                  ))),
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
              Container(
                  child: CircleAvatar(
                      maxRadius: 24,
                      backgroundColor: Colors.amber,
                      child: CircleAvatar(
                        maxRadius: 23,
                        backgroundImage: widget.data["ChatUser"]['avatar']['v'] != ""
                            ? Image.network(mainHost + widget.data["ChatUser"]['avatar']['v']).image
                            : Image.asset(avatar_default).image,
                        backgroundColor: Colors.transparent,
                      ))),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      widget.data['Contact'] != null
                          ? widget.data['Contact']['ContactUser']['v']
                          : widget.data["ChatUser"]['full_name']['v'],
                      style: appBarTextStyle(Utils.resizeWidthUtil(context, app_bar_font_size))),
                  Text("Trực tuyến", style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 25))),
                ],
              )
            ],
          ),
          actions: <Widget>[
            InkWell(
              child:
                  Icon(Icons.list, color: icon_app_bar_color, size: Utils.resizeWidthUtil(context, app_bar_icon_size)),
              onTap: () {
                Navigator.pushNamed(context, Routers.chatOptionView, arguments: widget.data);
              },
            ),
            Container(
              width: 30.0,
            )
          ],
        ),
        body: GestureDetector(
          onTap: () {
            Utils.closeKeyboard(context);
            hireEmoji();
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  child: _listMessage.length != 0
                      ? ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: _listMessage.length,
                    itemBuilder: (context, index) {
                      return (json.decode(_listMessage[index])['IDUserSent']) == _users['ID']
                          ? chatBubble(json.decode(_listMessage[index])['MessageText'],
                          json.decode(_listMessage[index])['DateTimeSent'], 1) // tự gửi
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.only(top: 10),
                              child: CircleAvatar(
                                maxRadius: 19,
                                backgroundColor: Colors.transparent,
                                child: CircleAvatar(
                                  maxRadius: 18,
                                  backgroundImage: chatAvatar.image,
                                  backgroundColor: Colors.transparent,
                                ),
                              )),
                          chatBubble(json.decode(_listMessage[index])['MessageText'],
                              json.decode(_listMessage[index])['DateTimeSent'], 2)
                        ],
                      ); // nhận về
                    },
                    //chatBubble(json.decode(_listMessage[index])['Message'],
                    //                                     json.decode(_listMessage[index])['TimeSent'], 2);
                  )
                      : Container(),
                ),
              ),
              chatTextField()
            ],
          ),
        ));
  }

  //1/26/2021 5:13:32 PM
  //01/28/2021 14:44:25 PM

  Widget chatBubble(String message, String date, int type) {
    String times = "";

    if (date != null && date != "") {
      DateFormat format = DateFormat("MM/dd/yyyy HH:mm:ss aaa");
      DateTime timeFormat = format.parse(date);
      if (timeFormat.day == DateTime.now().day &&
          timeFormat.month == DateTime.now().month &&
          timeFormat.year == DateTime.now().year) {
        times = DateFormat('HH:mm').format(timeFormat);
      } else {
        times = DateFormat('dd/MM').format(timeFormat);
      }
    }

    return Container(
        alignment: type == 1 ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10),
          constraints: BoxConstraints(
              maxWidth: type == 1 ? Utils.resizeWidthUtil(context, 550) : Utils.resizeWidthUtil(context, 450),
              minHeight: Utils.resizeHeightUtil(context, 60)),
          margin: EdgeInsets.only(top: 5, right: 10, bottom: 5, left: 5),
          decoration: BoxDecoration(
            color: type == 1 ? Color(0xFFD3EFFF) : Color(0xFFFEFEFE),
            /*boxShadow: [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 3),
              ),
            ],*/
            border: Border.all(width: 0.5, color: Colors.red),
            borderRadius: BorderRadius.all(Radius.circular(13)),
            //  border: Border.all(color: Colors.deepOrange, width: 1)
          ),
          child: Stack(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    //real message
                    TextSpan(
                        text: message + "    ",
                        style: TextStyle(color: Colors.black87, fontSize: Utils.resizeWidthUtil(context, 28))),
                    //Text(f.format(DateFormat('MM/dd/yyyy HH:mm:ss aaa')
                    //  .parse(widget.listHistory[widget.index]['DateDeal']['v']))),
                    TextSpan(text: times, style: TextStyle(color: Colors.transparent)),
                  ],
                ),
              ),
            ),

            //real additionalInfo
            Positioned(
              child: Text(
                //  f.format(DateFormat('MM/dd/yyyy HH:mm:ss').parse(date)),
                times,
                style: TextStyle(fontSize: 10.0, color: txt_grey_color_v1),
              ),
              right: 8.0,
              bottom: 1.0,
            )
          ]),
        ));
  }

  void addDataApis() async {
    var tbName = await Utils.encrypt("tb_chat_message");
    var response = await BaseViewModel().callApis({
      "tbname": tbName,
      "IDRoom": widget.data['Room']['ID'],
      "IDUserSent": _users['ID'],
      "DateTimeSent": DateFormat('yyyy-MM-dd HH:mm:ss.sss').format(DateTime.now()),
      "MessageText": _chatMessageController.text,
    }, addDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);

    if (response.status.code == 200) {
      _chatMessageController.clear();
      getListMessage();
    }
  }

  void pushNoti() async {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAA4SPuNic:APA91bFKpI5f-vohW67kBkjzCBO7o1xhsteCnsghw5ntQVmBou2mZvHN5htcoioZwVx34HCG6ger4aMEjrs3k3yM3-bMgQYL2qMUCI-gh6JGSORT0I7AnGCUzfcgEFkps-l4xjNAQlYV'
      },
      body: jsonEncode(<String, Object>{
        "notification": {
          "title": "Thông Báo",
          "body": "Bạn có tin nhắn mới",
          "content_available": true,
          "icon": "app_icon_local_notification",
          "sound": "default"
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "title": "Thông báo",
          "body": "Bạn có một tin nhắn mới",
          "vi": "",
          "type": "4",
          "navigator": "chatHome",
          "html": "",
          "buttons": []
        },
        "to": "/topics/${widget.data["ChatUser"]['AccUserKey']['v']}"
      }),
    );
  }

  Widget chatTextField() {
    return Container(
      alignment: Alignment.center,
      color: Color.fromRGBO(242, 242, 242, 1),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35.0),
                      boxShadow: [BoxShadow(offset: Offset(0, 3), blurRadius: 5, color: Colors.grey)],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                            icon: Icon(
                              Icons.face,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () {
                              if (!_showPicker) {
                                // keyboard is visible
                                hireKeyboard();
                                showEmoji();
                              } else {
                                showKeyboard();
                                hireEmoji();
                              }
                            }),
                        Expanded(
                          child: TextField(
                            focusNode: focusNode,
                            controller: _chatMessageController,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            onTap: () {
                              hireEmoji();
                            },
                            //Normal textInputField will be displayed
                            maxLines: 5,
                            style: TextStyle(color: Colors.blueAccent),
                            decoration: InputDecoration(
                                hintText: "Tin nhắn...",
                                hintStyle: TextStyle(color: Colors.blueAccent),
                                border: InputBorder.none),
                          ),
                        ),
                        // IconButton(
                        //   icon: Icon(Icons.photo_camera, color: Colors.blueAccent),
                        //   onPressed: () {},
                        // ),
                        // IconButton(
                        //   icon: Icon(Icons.attach_file, color: Colors.blueAccent),
                        //   onPressed: () {},
                        // )
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 15),
                GestureDetector(
                    onTap: () {
                      if (_chatMessageController.text != "" && _chatMessageController.text != null) {
                        /*String jsonMessage = '{'
                            '"IDUserSent":"${_users['ID']}",'
                            '"MessageText":"${_chatMessageController.text}",'
                            '"DateTimeSent":"${(DateFormat('MM/dd/yyyy HH:mm:ss aaa').format(DateTime.now()))[0] == '0' ? DateFormat('MM/dd/yyyy hh:mm:ss aaa').format(DateTime.now()).replaceAll(new RegExp(r'^0+(?=.)'), '') : DateFormat('MM/dd/yyyy hh:mm:ss aaa').format(DateTime.now())}"'
                            '}';*/
                        dynamic jsonMessage = {
                          'IDUserSent': _users['ID'],
                          'SenderName': _users['full_name']['v'],
                          'Avatar':  _users['avatar']['v'],
                          'MessageText': _chatMessageController.text,
                          'DateTimeSent': DateFormat('MM/dd/yyyy HH:mm:ss aaa').format(DateTime.now())
                        };
                        mQttServices.publish(widget.data['Room']['MqttTopic']['v'], jsonEncode(jsonMessage));
                        mQttServices.publish("GSCHAT/${widget.data['ChatUser']['ID']}", "NewMessage");
                        pushNoti();

                        addDataApis();
                      }
                      Utils.closeKeyboard(context);
                      hireEmoji();
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      //decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Image.asset(
                        ic_sent_message,
                        width: 25,
                        height: 25,
                        color: Colors.blue,
                        fit: BoxFit.fill,
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 2,
          ),
          //_showPicker ? buildSticker() : Container(),
        ],
      ),
    );
  }

  showKeyboard() => focusNode.requestFocus();

  hireKeyboard() => focusNode.unfocus();

  showEmoji() {
    setState(() {
      _showPicker = true;
    });
  }

  hireEmoji() {
    setState(() {
      _showPicker = false;
    });
  }

  /*Widget buildSticker() {
    return Container(
      child: EmojiPicker(
        rows: 3,
        columns: 7,
        buttonMode: ButtonMode.MATERIAL,
        numRecommended: 10,
        onEmojiSelected: (emoji, category) {
          _chatMessageController.text = _chatMessageController.text + emoji.emoji;
        },
      ),
    );
  }*/
}
