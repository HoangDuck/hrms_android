import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';

import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';

import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';

class ChatView extends StatefulWidget {
  final data;

  ChatView(this.data);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with TickerProviderStateMixin {
  int _currentIndex = 0;
  PageController _pageController;
  List<dynamic> _listChatUser = List();
  List<dynamic> _listContact = List();
  dynamic _users;
  List<dynamic> _listIdRoom = List();
  List<dynamic> _listRoom = List();
  List<String> _listIDRoomOnlyId = List();
  List<dynamic> _listChatRoom = List();
  List<dynamic> _listGroupChat = List();
  String mqttMessage = "";
  List<dynamic> _listDataShow = List();
  TextEditingController _searchEdtController = TextEditingController();
  bool _showSelectedList = false;
  bool _showSelectedListEmp = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    getCurrentUser();
  }

  @override
  void dispose() {
    print('RUN DISPOSE');
    _pageController.dispose();
    _searchEdtController.dispose();
    mQttServices.unSubscribe('GSCHAT/${_users['ID']}');
    super.dispose();
  }

  void getCurrentUser() async {
    var users = await SecureStorage().userProfile;
    setState(() {
      _users = users.data['data'][0];
      getChatListUser(num.parse(users.data['data'][0]['ID']));
      getMqtt();
      getListRoomID();
      //  getListChatRoomOfUser();
    });
  }

  getMqtt() {
    mQttServices.subscribe('GSCHAT/${_users['ID']}');
    //mQttServices.connect("GSCHAT/${_users['ID']}", "GSCHAT/Online/${_users['ID']}");
    mQttServices.mqttClient.updates.listen((event) async {
      mqttMessage = await mQttServices.onMessage(event);
      if (event[0].topic == "GSCHAT/${_users['ID']}") {
        if (mqttMessage == "NewMessage") getListRoomID();
      }
    });
  }

  void getChatListUser(int id) async {
    var response = await BaseViewModel().callApis({"ID": _users['ID']}, chatEmployeeList, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    var listContactResponse = await BaseViewModel()
        .callApis({"ID": id}, chatGetContact, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200 && listContactResponse.status.code == 200) {
      if (_listChatUser.length != 0) {
        setState(() {
          if (listContactResponse.status.code == 200) {
            if (_listContact.length != 0) {
              _listContact.clear();
              _listContact.addAll(listContactResponse.data['data']);
            } else {
              _listContact.addAll(listContactResponse.data['data']);
            }
          }
          _listChatUser.clear();
          _listChatUser.addAll(response.data['data']);
          _listDataShow = _listChatUser;
        });
      } else
        setState(() {
          if (listContactResponse.status.code == 200) {
            if (_listContact.length != 0) {
              _listContact.clear();
              _listContact.addAll(listContactResponse.data['data']);
            } else {
              _listContact.addAll(listContactResponse.data['data']);
            }
          }
          _listChatUser.addAll(response.data['data']);
          _listDataShow = _listChatUser;
        });
    }
  }

  void getListRoomID() async {
    var response = await BaseViewModel().callApis({"ID": _users['ID']}, chatGetListIdRoom, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (_listIdRoom.length != 0) {
        setState(() {
          _listIdRoom.clear();
          _listIdRoom.addAll(response.data['data']);
        });
      } else {
        setState(() {
          _listIdRoom.addAll(response.data['data']);
        });
      }
    }
    if (_listIDRoomOnlyId.length != 0) {
      _listIDRoomOnlyId.clear();
      _listIdRoom.forEach((item) {
        _listIDRoomOnlyId.add(item['IDRoom']['v']);
      });
    } else {
      _listIdRoom.forEach((item) {
        _listIDRoomOnlyId.add(item['IDRoom']['v']);
      });
    }
    getListRoom();
  }

  void getListRoom(//{String condition="1=1", int index}
      ) async {
    var response = await BaseViewModel().callApis(
        //  {'condition': condition}
        {"list": _listIDRoomOnlyId.toString().replaceAll('[', '(').replaceAll(']', ')')}, chatGetListChatRoomJoinUser,
        method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      // if (index!=null){
      //   setState(() {
      //     _listRoom[index]=response.data['data'][0];
      //   });
      // }else  setState(() {
      //   _listRoom.addAll(response.data['data']);
      // });
      if (_listRoom.length != 0) {
        setState(() {
          _listRoom.clear();
          _listRoom.addAll(response.data['data']);
        });
      } else {
        setState(() {
          _listRoom.addAll(response.data['data']);
        });
      }
    }
    getListChatRoomOfUser();
  }

  bool checkExist(String id, dynamic item) {
    if (item['IdUser']['v'] == id) {
      return true;
    }
    return false;
  }

  void getListChatRoomOfUser() {
    if (_listChatRoom.length != 0) {
      _listChatRoom.clear();
    }
    if (_listGroupChat.length != 0) {
      _listGroupChat.clear();
    }
    _listRoom.forEach((item) {
      if (item['TypeRoom']['v'] == "1") {
        if (!checkExist(_users['ID'], item)) {
          setState(() {
            _listChatRoom.add(item);
          });
        }
      } else {
        if (checkExist(_users['ID'], item)) {
          setState(() {
            _listGroupChat.add(item);
          });
        }
      }
    });
  }

  void onPageChanged(int page) {
    setState(() {
      this._currentIndex = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(context, () {
        Navigator.pop(context);
      }, () {
        _showSelectedList = true;
        setState(() {});
      }, Utils.getString(context, txt_chat), Icons.add_comment_rounded),
      /*bottomNavigationBar: FFNavigationBar(
        theme: FFNavigationBarTheme(
          barBackgroundColor: Colors.white,
          selectedItemBorderColor: Colors.transparent,
          selectedItemBackgroundColor: Colors.green,
          selectedItemIconColor: Colors.white,
          selectedItemLabelColor: Colors.black,
          showSelectedItemShadow: false,
          barHeight: 70,
        ),
        selectedIndex: _currentIndex,
        onSelectTab: (index) => setState(
          () {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          },
        ),
        items: [
          FFNavigationBarItem(
            iconData: Icons.message_outlined,
            label: Utils.getString(context, txt_chat),
          ),
          FFNavigationBarItem(
            iconData: Icons.group,
            label: Utils.getString(context, txt_chat_group),
            selectedBackgroundColor: Colors.orange,
          ),
        ],
      ),*/
      body: Stack(
        children: [
          SizedBox.expand(
            child: PageView(
              controller: _pageController,
              onPageChanged: onPageChanged,
              children: <Widget>[
                messageScreen(),
                groupScreen(),
                //contactScreen(),
              ],
            ),
          ),
          if (_showSelectedList) _buildSelectedList(),
          if (_showSelectedListEmp) _buildSelectedListEmp(),
        ],
      ),
    );
  }

  Widget _buildSelectedList() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 0.5),
              ),
            ],
          ),
          height: MediaQuery.of(context).size.height * 0.2,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(height: 12),
                  Center(
                    child: TKText('Thêm cuộc trò chuyện',
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 32),
                            color: txt_grey_color_v2,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showSelectedListEmp = true;
                            _showSelectedList = false;
                            setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: Utils.resizeWidthUtil(context, 30),
                                vertical: Utils.resizeWidthUtil(context, 10)),
                            child: Row(
                              children: [
                                Icon(Icons.person_add_alt_1_rounded, size: 30),
                                SizedBox(width: 5),
                                TKText('Thêm người trò chuyện',
                                    style: TextStyle(
                                        fontSize: Utils.resizeWidthUtil(context, 32),
                                        color: txt_grey_color_v2,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            /*_showSelectedListEmpGroup = true;
                            _showSelectedList = false;
                            setState(() {});*/
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: Utils.resizeWidthUtil(context, 30),
                                vertical: Utils.resizeWidthUtil(context, 10)),
                            child: Row(
                              children: [
                                Icon(Icons.group_add_rounded, size: 30),
                                SizedBox(width: 5),
                                TKText('Thêm nhóm trò chuyện',
                                    style: TextStyle(
                                        fontSize: Utils.resizeWidthUtil(context, 32),
                                        color: txt_grey_color_v2,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12)
                ],
              ),
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    _showSelectedList = false;
                    setState(() {});
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Icon(Icons.clear, color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedListEmp() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 0.5),
              ),
            ],
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.9,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(height: 12),
                  Center(
                    child: TKText('Chọn người trò chuyện',
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 32),
                            color: txt_grey_color_v2,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: contactScreen(),
                  ),
                  SizedBox(height: 12)
                ],
              ),
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    _showSelectedListEmp = false;
                    _showSelectedList = false;
                    setState(() {});
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Icon(Icons.clear, color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ////--------------------------------------------Message---------------------------------------------------------//

  Widget messageScreen() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: Utils.resizeWidthUtil(context, 30), vertical: Utils.resizeWidthUtil(context, 10)),
          child: TextFieldCustom(
            enable: true,
            expandMultiLine: false,
            //controller: _searchEdtController,
            hintText: 'Tìm kiếm',
            onChange: (value) {
              /*setState(() {
                _listDataShow = _listChatUser.where((item) {
                  return item["full_name"]['v']
                      .toLowerCase()
                      .contains(value.toLowerCase());
                }).toList();
              });*/
            },
          ),
        ),
        Expanded(
            child: ListView.builder(
          itemCount: _listChatRoom.length,
          itemBuilder: (ctx, i) {
            return Container(
                margin: EdgeInsets.only(top: 10),
                child: _listChatRoom.length != 0 && _listChatRoom != null
                    ? _chatMessageWidget(
                        _listChatRoom[i]['IdUser']['v'],
                        _listChatRoom[i]['LastMessage']['v'] != null || _listChatRoom[i]['LastMessage']['v'] != ""
                            ? _listChatRoom[i]['LastMessage']['v']
                            : "",
                        _listChatRoom[i]['LastMessageDateTime']['v'] != null ||
                                _listChatRoom[i]['LastMessageDateTime']['v'] != ""
                            ? _listChatRoom[i]['LastMessageDateTime']['v']
                            : "",
                        _listChatRoom[i],
                        _listChatRoom[i]['HaveSeen']['v'],
                        _listChatRoom[i]['HaveSeenCount']['v'],
                        _listChatRoom[i]['LastMessageUserSentID']['v'])
                    : Container(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(),
                      ));
          },
        )),
      ],
    );
  }

  String getAva(String element) {
    _listChatUser.forEach((index) {
      if (element == index['ID']) {
        return index['avatar']['v'];
      }
    });
    _listDataShow.forEach((index) {
      if (element == index['ID']) {
        return index['avatar']['v'];
      }
    });
    return "";
  }

  Widget _chatMessageWidget(String id, String lastMessage, String time, dynamic room, String haveSeen,
      String haveSeenCount, String idUserLast) {
    String name = "";
    String ava = "";
    String times = "";
    dynamic chatUser;
    dynamic contact;
    bool isUser = false;
    if (idUserLast != _users['ID']) {
      isUser = true;
    } else
      isUser = false;

    if (time != null && time != "") {
      DateFormat format = DateFormat("MM/dd/yyyy HH:mm:ss aaa");
      DateTime timeFormat = format.parse(time);
      if (timeFormat.day == DateTime.now().day &&
          timeFormat.month == DateTime.now().month &&
          timeFormat.year == DateTime.now().year) {
        times = DateFormat('HH:mm').format(timeFormat);
      } else {
        times = DateFormat('dd/MM').format(timeFormat);
      }
    }
    _listChatUser.forEach((element) {
      if (element['ID'] == id) {
        name = element['full_name']['v'];
        ava = element['avatar']['v'];
        chatUser = element;
      }
    });
    _listDataShow.forEach((element) {
      if (element['ID'] == id) {
        name = element['full_name']['v'];
        ava = element['avatar']['v'];
        chatUser = element;
      }
    });
    _listContact.forEach((element) {
      if (element['IdPartner']['v'] == id) {
        name = element['ContactUser']['v'];
        contact = element;
      }
    });
    return Card(
        margin: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 30)),
        child: Column(
          children: [
            ListTile(
              isThreeLine: true,
              onLongPress: () {
                Utils.closeKeyboard(context);
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => SingleChildScrollView(
                    child: Container(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top),
                        decoration: BoxDecoration(
                          border: Border.all(style: BorderStyle.none),
                        ),
                        child: StatefulBuilder(builder: (context, setModalState) {
                          return _modalBottomSheet(setModalState, room);
                        })),
                  ),
                );
              },
              onTap: () async {
                var tbName = await Utils.encrypt("tb_chat_room");
                await BaseViewModel().callApis({
                  "tbname": tbName,
                  "dataid": room['ID'],
                  "HaveSeen": "TRUE",
                  "HaveSeenCount": 0
                }, updateDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
                Navigator.pushNamed(
                  context,
                  Routers.chatEmpView,
                  arguments: {"ChatUser": chatUser, "Contact": contact != null ? contact : null, "Room": room},
                ).then((value) {
                  getMqtt();
                  getListRoom();
                });
              },
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(.3), offset: Offset(0, 5), blurRadius: 25)],
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                        child: ava != ""
                            ? CircleAvatar(
                                maxRadius: 30,
                                backgroundImage: Image.network(mainHost + ava).image,
                                backgroundColor: Colors.transparent,
                              )
                            : Container(
                                //   margin: EdgeInsets.all(10),
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: Text(
                                  name != null && name != "" ? name[0] : "",
                                  style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 65), color: Colors.white),
                                ),
                              )),
                    // Align(
                    //   alignment: Alignment.topRight,
                    //   child: Container(
                    //     height: 15,
                    //     width: 15,
                    //     decoration: BoxDecoration(
                    //       border: Border.all(
                    //         color: Colors.white,
                    //         width: 3,
                    //       ),
                    //       shape: BoxShape.circle,
                    //       color: Colors.green,
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
              title: Container(
                  //color: Colors.blue,
                  height: Utils.resizeHeightUtil(context, 50),
                  //   margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 10)),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                            fontWeight: isUser
                                ? haveSeen == "False"
                                    ? FontWeight.bold
                                    : FontWeight.normal
                                : FontWeight.normal),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                    ],
                  )),
              subtitle: Text(
                lastMessage,
                style: TextStyle(
                    fontWeight: isUser
                        ? haveSeen == "False"
                            ? FontWeight.bold
                            : FontWeight.normal
                        : FontWeight.normal),
              ),
              trailing: Container(
                width: Utils.resizeWidthUtil(context, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      height: Utils.resizeHeightUtil(context, 16),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          times,
                          style: TextStyle(
                              fontWeight: isUser
                                  ? haveSeen == "False"
                                      ? FontWeight.bold
                                      : FontWeight.normal
                                  : FontWeight.normal),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    // Icon(
                    //   Icons.check,
                    //   size: 15,
                    // ),
                    isUser
                        ? haveSeen == "False"
                            ? Container(
                                alignment: Alignment.center,
                                height: Utils.resizeWidthUtil(context, 35),
                                width: Utils.resizeWidthUtil(context, 35),
                                decoration: BoxDecoration(
                                  // border: Border.all(
                                  //   color: Colors.white,
                                  //   width: 3,
                                  // ),
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent,
                                ),
                                child: haveSeenCount != "" && haveSeenCount != null
                                    ? Text(
                                        num.parse(haveSeenCount) >= 5 ? "5+" : haveSeenCount,
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : Text(
                                        "1",
                                        style: TextStyle(color: Colors.white),
                                      ),
                              )
                            : Container()
                        : Container()

                    // friendsList[i]['hasUnSeenMsgs']
                    //     ? Container(
                    //   alignment: Alignment.center,
                    //   height: 25,
                    //   width: 25,
                    //   decoration: BoxDecoration(
                    //     color: myGreen,
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: Text(
                    //     "${friendsList[i]['unseenCount']}",
                    //     style: TextStyle(color: Colors.white),
                    //   ),
                    // )
                  ],
                ),
              ),
            ),
            /*Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Expanded(
              flex: 4,
              child: Container(
                  height: Utils.resizeHeightUtil(context, 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                    //color: Colors.blue),
                  )),
            )
          ],
        )*/
          ],
        ));
  }

  // Widget _widgetChatItem(String image, String name, String message, String date) {
  //   return Container(
  //       margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 10)),
  //       child: Row(
  //         children: [
  //           Expanded(
  //               flex: 2,
  //               child: Container(
  //                   child: CircleAvatar(
  //                 maxRadius: 40,
  //                 backgroundColor: Colors.transparent,
  //                 child: CircleAvatar(
  //                   maxRadius: 30,
  //                   backgroundImage: Image.asset(
  //                     image,
  //                     fit: BoxFit.fitWidth,
  //                   ).image,
  //                   backgroundColor: Colors.transparent,
  //                 ),
  //               ))),
  //           Expanded(
  //               flex: 6,
  //               child: Container(
  //                 padding: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
  //                 decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
  //                 child: Row(
  //                   children: [
  //                     Expanded(
  //                         flex: 5,
  //                         child: Container(
  //                           decoration: BoxDecoration(),
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 name,
  //                                 style: TextStyle(
  //                                   fontSize: 20,
  //                                 ),
  //                               ),
  //                               SizedBox(
  //                                 height: Utils.resizeHeightUtil(context, 8),
  //                               ),
  //                               Text(
  //                                 message,
  //                                 style: TextStyle(fontSize: 16, color: Colors.grey),
  //                               )
  //                             ],
  //                           ),
  //                         )),
  //                     Expanded(
  //                         flex: 1,
  //                         child: Container(
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(date),
  //                               Text(""),
  //                             ],
  //                           ),
  //                         ))
  //                   ],
  //                 ),
  //               ))
  //         ],
  //       ));
  // }

  Future<dynamic> addData(String topic, String id) async {
    dynamic room;
    var tbChatRoom = await Utils.encrypt("tb_chat_room");
    await Utils.encrypt("tb_chat_room");
    var tbChatRoomParticipant = await Utils.encrypt("tb_chat_room_paticipant");

    var insertChatRoom = await BaseViewModel().callApis({
      "tbname": tbChatRoom,
      "MqttTopic": topic,
      "TypeRoom": 1,
    }, addDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false); //----->DatatId

    await BaseViewModel().callApis({
      "tbname": tbChatRoomParticipant,
      "IDRoom": insertChatRoom.data['data'][0]['dataid'],
      "IdUser": id
    }, addDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    await BaseViewModel().callApis({
      "tbname": tbChatRoomParticipant,
      "IDRoom": insertChatRoom.data['data'][0]['dataid'],
      "IdUser": _users['ID']
    }, addDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    // select ngược lại từ db.
    var selectData = await BaseViewModel().callApis(
        {"ID": insertChatRoom.data['data'][0]['dataid']}, chatGetRoomWithID, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (selectData.status.code == 200) {
      room = selectData.data['data'][0];
    }

    return room;
    //******************************************************
  }

  String createTopic(String id) {
    String topic = "";
    int idCurrentUser = num.parse(_users['ID']);
    int chatUser = num.parse(id);

    if (idCurrentUser > chatUser) {
      topic = id + _users['ID'];
    } else
      topic = _users['ID'] + id;
    return topic;
  }

  Widget _widgetPhoneBookItem(
      String id, String image, String name, String role, String empId, int index, List<dynamic> contact) {
    bool isExist = false;
    dynamic room;
    _listRoom.forEach((item) {
      if (checkExist(id, item)) {
        isExist = true;
        room = item;
      }
    });

    int position;
    for (int i = 0; i < contact.length; i++) {
      if (contact[i]['IdPartner']['v'] == id) {
        position = i;
        break;
      } else {
        continue;
      }
    }

    String topic = createTopic(id);

    return Container(
      decoration: BoxDecoration(
          //   color: (index % 2==0) ? Colors.transparent: Colors.grey.withOpacity(0.1),
          border: Border(top: BorderSide(width: 1, color: Colors.grey.shade200))),
      // margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 10)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (!isExist) {
                  room = await addData(topic, id);
                }
                Navigator.pushNamed(
                  context,
                  Routers.chatEmpView,
                  arguments: {
                    "ChatUser": _listDataShow[index],
                    "Contact": position != null ? contact[position] : null,
                    "Room": room
                  },
                ).then((value) {
                  Navigator.popAndPushNamed(context, Routers.chatView);
                });
              },
              child: Container(
                  child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Container(
                          child: CircleAvatar(
                              maxRadius: 30,
                              backgroundColor: Colors.transparent,
                              child: image != ""
                                  ? CircleAvatar(
                                      maxRadius: 20,
                                      backgroundImage: Image.network(mainHost + image).image,
                                      backgroundColor: Colors.transparent,
                                    )
                                  : Container(
                                      margin: EdgeInsets.all(10),
                                      width: double.infinity,
                                      height: double.infinity,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                      child: Text(
                                        name[0],
                                        style: TextStyle(
                                            fontSize: Utils.resizeWidthUtil(context, 65), color: Colors.white),
                                      ),
                                    )))),
                  Expanded(
                      flex: 6,
                      child: Container(
                        padding: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
                        //    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 5,
                                child: Container(
                                  decoration: BoxDecoration(),
                                  child: TKText(
                                    position == null
                                        ? name + ' (' + empId + ')'
                                        : contact[position]['ContactUser']['v'],
                                    style: TextStyle(
                                      fontSize: Utils.resizeWidthUtil(context, 30),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      )),
                ],
              )),
            ),
          ),
          /*GestureDetector(
            onTap: () {
              print("ba chấm $name");
            },
            child: Container(
              child: Icon(Icons.more_horiz),
            ),
          ),
          SizedBox(width: 10)*/
        ],
      ),
    );
  }

  //---------------------------------------------------Group----------------------//

  Widget groupScreen() {
    return Container(
      child: SingleChildScrollView(
        child: Column(
          children: [],
        ),
      ),
    );
  }

//-------------------------------------danh bạ----------------//

  Widget contactScreen() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: Utils.resizeWidthUtil(context, 30), vertical: Utils.resizeWidthUtil(context, 10)),
          child: TextFieldCustom(
            enable: true,
            expandMultiLine: false,
            controller: _searchEdtController,
            hintText: 'Tìm kiếm tên nhân viên',
            onChange: (value) {
              setState(() {
                _listDataShow = _listChatUser.where((item) {
                  return item["full_name"]['v'].toLowerCase().contains(value.toLowerCase());
                }).toList();
              });
            },
          ),
        ),
        Expanded(
            child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          child: _listDataShow.length != 0
              ? ListView.builder(
                  itemCount: _listDataShow.length,
                  itemBuilder: (context, index) {
                    return (_widgetPhoneBookItem(
                        _listDataShow[index]['ID'],
                        _listDataShow[index]['avatar']['v'],
                        _listDataShow[index]['full_name']['v'],
                        _listDataShow[index]['name_role']['v'],
                        _listDataShow[index]['emp_id']['v'],
                        index,
                        _listContact));
                  },
                )
              : Container(),
        )),
      ],
    );
  }

  Widget _modalBottomSheet(StateSetter setModalState, dynamic room) {
    return Container(
      //height: MediaQuery.of(context).size.height * 0.5,
      padding: EdgeInsets.only(
          left: Utils.resizeWidthUtil(context, 30),
          right: Utils.resizeWidthUtil(context, 30),
          top: Utils.resizeHeightUtil(context, 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
          topRight: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Container(
            color: white_color,
            height: 10,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Container(
                height: 5,
                width: Utils.resizeWidthUtil(context, 100),
                decoration: BoxDecoration(
                    color: txt_grey_color_v1.withOpacity(0.3), borderRadius: BorderRadius.all(Radius.circular(8.0))),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 50),
                        ),
                        Center(
                          child: TKText("Tùy chọn",
                              tkFont: TKFont.SFProDisplayBold,
                              style: TextStyle(color: txt_black_color, fontSize: Utils.resizeWidthUtil(context, 32))),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 40),
                        ),
                        GestureDetector(
                          onTap: () {
                            print('ghim');
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin_outlined,
                                size: 30,
                                color: txt_grey_color_v1,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 10),
                              ),
                              TKText("Ghim",
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            print('Ẩn trò chuyện');
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 30,
                                color: txt_grey_color_v1,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 10),
                              ),
                              TKText("Ẩn trò chuyện",
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            showMessageChoose(context, description: "Bạn có đồng ý xóa cuộc trò chuyện?",
                                onPress: () async {
                              Navigator.pop(context);
                              var tbName = await Utils.encrypt("tb_chat_room");
                              await BaseViewModel().callApis({
                                "tbname": tbName,
                                "dataid": room['ID'],
                              }, deleteDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false).then(
                                  (value) {
                                getListRoom();
                              });
                              Navigator.pop(context);
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 30,
                                color: Colors.red,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 10),
                              ),
                              TKText("Xóa cuộc trò chuyện",
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(color: Colors.red, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            print('Đánh dấu đã đọc');
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 30,
                                color: txt_grey_color_v1,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 10),
                              ),
                              TKText("Đánh dấu đã đọc",
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            print('Tắt thông báo');
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 30,
                                color: txt_grey_color_v1,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 10),
                              ),
                              TKText("Tắt thông báo",
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: Utils.resizeHeightUtil(context, 30),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
