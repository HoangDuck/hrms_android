import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:gsot_timekeeping/ui/widgets/chats_widget/src/chat_theme.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:http/http.dart' as http;

class ManageMemberView extends StatefulWidget {
  final data;

  ManageMemberView(this.data);

  @override
  _ManageMemberViewState createState() => _ManageMemberViewState();
}

class _ManageMemberViewState extends State<ManageMemberView> {
  List<dynamic> _listMember = [];
  dynamic _users;
  TextEditingController _textSearchController = TextEditingController();
  List<dynamic> _listSearchSuggest = [];
  bool _searching = false;
  List<dynamic> _listGroupSelected = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _listMember.addAll(widget.data['ListUser']);
    _initUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _initUser() async {
    SecureStorage().userProfile.then((userProfile) {
      setState(() {
        _users = userProfile.data['data'][0];
        _listMember.insert(0, _users);
        if(widget.data['RoomData']['KeyUser']['v'] == _users['ID'])
          _isOwner = true;
      });
    });
  }

  _showPopupMenu(Offset offset, int index) async {
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
                TKText(
                  'Mời ra khỏi nhóm',
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(color: txt_fail_color),
                ),
              ],
            ),
            value: 'delete'),
        PopupMenuItem<String>(
              child: Row(
                children: [
                  Icon(CupertinoIcons.chat_bubble_2_fill, color: txt_yellow,),
                  SizedBox(
                    width: 20,
                  ),
                  TKText('Nhắn tin'),
                ],
              ),
              value: 'message')
      ],
      elevation: 8.0,
    ).then((value) {
      switch (value) {
        case 'delete':
          _deleteMember(index);
          break;
        case 'message':
          _checkRoom(index);
          break;
        default:
          print('none');
      }
    });
  }

  _deleteMember(index) async {
    dynamic member = _listMember[index];
    _listMember.removeAt(index);
    var response = await BaseViewModel().callApis({
      'roomID': widget.data['RoomData']['ID'],
      'userID': member['ID'],
      'userUpdate': _createParticipantUser(_listMember)
    }, RemoveMemberChatGroup, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      String payload = jsonEncode({
        'EventType': 'deleteUser',
        'IDUserSent': _users['ID'],
        'IDUserDelete': member['ID'],
        'RoomID': widget.data['RoomData']['ID']
      });
      mQttServices.publish(widget.data['RoomData']['MqttTopic']['v'], payload);
      mQttServices.publish("GSCHAT", "%$payload");
      setState(() {});
    }
  }

  _createParticipantUser(List<dynamic> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i]['ID'] + (i < user.length - 1 ? ';' : '');
    }
    return participantUser;
  }

  _createParticipantUserSingle(List<String> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i] + (i < user.length - 1 ? ';' : '');
    }
    return participantUser;
  }

  _createIDParticipant(List<dynamic> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i]['ID'] + (i < user.length - 1 ? ',' : '');
    }
    return participantUser;
  }

  _searchUser(String searchText, StateSetter state) async {
    _listSearchSuggest.clear();
    state(() {
      _searching = true;
    });
    var response = await BaseViewModel().callApis({
      'search_text': searchText,
      'condition': 'ID NOT IN (${_createIDParticipant(_listMember)}) '
    }, chatEmployeeList, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      response.data['data'].forEach((ele) {
        if (_listGroupSelected.where((element) => element['ID'] == ele['ID']).toList().length == 0)
          _listSearchSuggest.add(ele);
      });
      state(() {
        _searching = false;
      });
    }
  }

  _handleCheck(StateSetter state, int index) {
    state(() {
      _listGroupSelected.add(_listSearchSuggest[index]);
      _listSearchSuggest.removeAt(index);
    });
  }

  _callInvite(state) async {
    _listMember.addAll(_listGroupSelected);
    var createParticipantResponse = await BaseViewModel().callApis({
      "listValues": _createRoomParticipant(_listGroupSelected, widget.data['RoomData']['ID'].toString()),
      'roomID': widget.data['RoomData']['ID'],
      'userUpdate': _createParticipantUser(_listMember)
    }, AddMemberChatGroup, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (createParticipantResponse.status.code == 200) {
      String payload = jsonEncode({
        'IDUserSent': _users['ID'],
        'RoomData': widget.data['RoomData'],
        'ListUser': _createParticipantUser(_listMember)
      });
      mQttServices.publish("GSCHAT", "@$payload");
      _pushNotification();
      setState(() {});
      Navigator.pop(context);
    }
  }

  _createRoomParticipant(List<dynamic> user, String roomID) {
    String values = '';
    for (int i = 0; i < user.length; i++) {
      values = values + '( $roomID, ${user[i]['ID']} )' + (i < user.length - 1 ? ',' : '');
    }
    return values;
  }

  _createRoomParticipantSingle(List<dynamic> user, String roomID) {
    String values = '';
    for (int i = 0; i < user.length; i++) {
      values = values + '( $roomID, ${user[i]} )' + (i < user.length - 1 ? ',' : '');
    }
    return values;
  }

  _checkRoom(index) async {
    var response = await BaseViewModel().callApis({
      'condition_1': '${_users['ID']};${_listMember[index]['ID']}',
      'condition_2': '${_listMember[index]['ID']};${_users['ID']}'
    }, CheckSingleRoom, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      if (response.data['data'].length > 0) {
        Navigator.pushNamed(
          context,
          Routers.chatEmpView,
          arguments: {
            "RoomData": {
              ...response.data['data'][0],
              ...{'ChatUser': _listMember[index]}
            }
          },
        ).then((value) {
          Navigator.pop(context);
        });
      } else {
        var createRoomResponse = await BaseViewModel().callApis({
          "tbname": 'xy3hrQRA0dDamQvkcYX2/w==',
          "MqttTopic": _createToken([_users['ID'], _listMember[index]['ID']]),
          'PaticipantUser': _createParticipantUserSingle([_users['ID'], _listMember[index]['ID']]),
          "TypeRoom": 1,
          'KeyUser': _users['ID'],
        }, addDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
        if (createRoomResponse.status.code == 200) {
          await BaseViewModel().callApis({
            "listValues": _createRoomParticipantSingle(
                [_users['ID'], _listMember[index]['ID']], createRoomResponse.data['data'][0]['dataid'].toString())
          }, InsertParticipant, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
          var selectData = await BaseViewModel().callApis({
            "roomID": createRoomResponse.data['data'][0]['dataid'],
            "userID": _users['ID']
          }, chatGetRoomWithID, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
          if (selectData.status.code == 200) {
            selectData.data['data'][0]['RoomName'] = _listMember[index]['full_name']['v'];
            selectData.data['data'][0]['AvaGroup'] = _listMember[index]['avatar']['v'];
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              Routers.chatEmpView,
              arguments: {
                'isGroup': false,
                "RoomData": {
                  ...selectData.data['data'][0],
                  ...{'ChatUser': _listMember[index]}
                }
              },
            );
          }
        }
      }
    }
  }

  _createToken(List<String> user) {
    String topic = '';
    for (var item in user) {
      topic = topic + item;
    }
    return topic;
  }

  _pushNotification() async {
    dynamic data = {
      'isGroup': true,
      'RoomData': {
        "ID": widget.data['RoomData']['ID'],
        'MqttTopic': widget.data['RoomData']['MqttTopic'],
        'AvaGroup': widget.data['RoomData']['AvaGroup'],
        'RoomName': widget.data['RoomData']['RoomName'],
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
          "title": 'Thông báo',
          "body": '${_users['full_name']['v']} đã thêm bạn vào nhóm ${widget.data['RoomData']['RoomName']['v']}',
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
          "title": 'Thông báo',
          "body": '${_users['full_name']} đã thêm bạn vào nhóm ${widget.data['RoomData']['RoomName']}',
          "vi": "",
          "type": "4",
          "navigator": "chatHome",
          "html": "",
          "buttons": []
        },
        "condition": _formatListUserKey()
      }),
    );
  }

  _formatListUserKey() {
    String topics = '';
    for (int i = 0; i < _listGroupSelected.length; i++) {
      topics = topics +
          '\'${_listGroupSelected[i]['AccUserKey']['v'].replaceAll(new RegExp(r'[^\w\s]+'), '')}\'' +
          (i < _listGroupSelected.length - 1 ? ' in topics || ' : ' in topics');
    }
    return topics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(
          context,
          () => Navigator.pop(context),
          () => showModalBottomSheet(
              context: context, isScrollControlled: true, builder: (context) => _buildBottomSheet()),
          'Quản lý thành viên',
          CupertinoIcons.person_add),
      body: Container(
        padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: Utils.resizeWidthUtil(context, 30)),
              child: TKText(
                'Thành viên (${_listMember.length})',
                tkFont: TKFont.SFProDisplayMedium,
                style: TextStyle(fontSize: 17, color: gradient_start_color),
              ),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: _listMember.length,
                  itemBuilder: (context, index) {
                    return _buildItemList(index);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(int index) => Container(
        padding: EdgeInsets.only(bottom: Utils.resizeWidthUtil(context, 30)),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 7, bottom: 5),
                  child: CircleAvatar(
                    maxRadius: 22,
                    backgroundColor: only_color,
                    child: _listMember[index]['avatar']['v'] != ''
                        ? CachedNetworkImage(
                            imageUrl: '$avatarUrlAPIs${_listMember[index]['avatar']['v']}',
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(width: 1, color: only_color),
                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                            placeholder: (context, url) => CupertinoActivityIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          )
                        : TKText(
                            _listMember[index]['full_name']['v'].toString().substring(0, 1),
                            tkFont: TKFont.SFProDisplayBold,
                            style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 40), color: Colors.white),
                          ),
                  ),
                ),
                widget.data['RoomData']['KeyUser']['v'] == _listMember[index]['ID']
                    ? Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                            child: Icon(
                              Icons.vpn_key_outlined,
                              color: Colors.yellow,
                              size: 10,
                            )))
                    : SizedBox()
              ],
            ),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 30),
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TKText(_users != null ?
                  _listMember[index]['ID'] == _users['ID'] ? 'Bạn' : _listMember[index]['full_name']['v'] : '',
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(fontSize: 20, color: neutral0.withOpacity(0.8)),
                ),
                TKText(
                    widget.data['RoomData']['KeyUser']['v'] == _listMember[index]['ID'] ? 'Trưởng nhóm' : 'Thành viên'),
              ],
            )),
            if (_listMember[index]['ID'] != _users['ID'] && _isOwner)
              GestureDetector(
                onTapDown: (details) => _showPopupMenu(details.globalPosition, index),
                child: Icon(Icons.more_vert, color: neutral0.withOpacity(0.8)),
              )
          ],
        ),
      );

  Widget _buildBottomSheet() => Container(
      color: main_background,
      height: MediaQuery.of(context).size.height - (kToolbarHeight + MediaQuery.of(context).viewPadding.top),
      width: double.infinity,
      child: StatefulBuilder(
          builder: (context, state) => Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(5),
                        alignment: Alignment.center,
                        child: Container(
                          height: 5,
                          width: 50,
                          decoration:
                              BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.all(Radius.circular(10))),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(
                            vertical: Utils.resizeWidthUtil(context, 10),
                            horizontal: Utils.resizeWidthUtil(context, 20)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: TextField(
                            controller: _textSearchController,
                            decoration: InputDecoration(
                              hintStyle: TextStyle(fontSize: 17),
                              hintText: 'Tìm kiếm',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _textSearchController.clear();
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(20),
                            ),
                            onSubmitted: (value) {
                              _searchUser(value, state);
                            },
                          ),
                        ),
                      ),
                      Container(
                        height: 0.8,
                        margin: EdgeInsets.only(top: Utils.resizeWidthUtil(context, 10)),
                        color: Colors.black12,
                      ),
                      Expanded(
                          child: ListView.builder(
                              itemCount: _listSearchSuggest.length,
                              cacheExtent: 9999,
                              itemBuilder: (context, index) => Container(
                                  padding: EdgeInsets.only(
                                      left: Utils.resizeWidthUtil(context, 30),
                                      top: Utils.resizeWidthUtil(context, 30)),
                                  child: GestureDetector(
                                    onTap: () => _handleCheck(state, index),
                                    child: Container(
                                      color: Colors.transparent,
                                      child: !_searching
                                          ? _buildListItem(_listSearchSuggest[index],
                                              isEnd: _listSearchSuggest.length - 1 == index)
                                          : Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                    ),
                                  ))))
                    ],
                  ),
                  _listGroupSelected.length > 0
                      ? Positioned(
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: Container(
                            height: Utils.resizeHeightUtil(context, 100),
                            padding: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 30)),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [BoxShadow(offset: Offset(0, 0), blurRadius: 5, color: Colors.grey)]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                      itemCount: _listGroupSelected.length,
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            state(() {
                                              _listSearchSuggest.add(_listGroupSelected[index]);
                                              _listGroupSelected.removeAt(index);
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Stack(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(right: 8),
                                                    child: _buildGroupSelectItem(_listGroupSelected[index]),
                                                  ),
                                                  Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Icon(
                                                        Icons.cancel_rounded,
                                                        color: Colors.black54,
                                                      ))
                                                ],
                                              ),
                                              SizedBox(
                                                width: 10,
                                              )
                                            ],
                                          ),
                                        );
                                      }),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                GestureDetector(
                                  onTap: () => _callInvite(state),
                                  child: Container(
                                    height: Utils.resizeWidthUtil(context, 70),
                                    width: Utils.resizeWidthUtil(context, 70),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: only_color, boxShadow: [
                                      BoxShadow(offset: Offset(0, 3), blurRadius: 5, color: Colors.grey)
                                    ]),
                                    child: Icon(
                                      Icons.forward,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ))
                      : SizedBox.shrink()
                ],
              )));

  Widget _buildListItem(dynamic itemData, {bool isEnd = false}) => Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                maxRadius: 22,
                backgroundColor: itemData['avatar']['v'] != '' ? Colors.transparent : only_color,
                child: itemData['avatar']['v'] != ''
                    ? CachedNetworkImage(
                        imageUrl: '$avatarUrlAPIs${itemData['avatar']['v']}',
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(width: 1, color: only_color),
                            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                        placeholder: (context, url) => CupertinoActivityIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    : TKText(
                        itemData['full_name']['v'].toString().substring(0, 1),
                        tkFont: TKFont.SFProDisplayBold,
                        style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 40), color: Colors.white),
                      ),
              ),
              SizedBox(
                height: Utils.resizeWidthUtil(context, 30),
              ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(right: Utils.resizeWidthUtil(context, 30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TKText(
                      itemData['full_name']['v'],
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(fontSize: 20, color: neutral0.withOpacity(0.8)),
                    ),
                    Icon(CupertinoIcons.circle)
                  ],
                ),
              ),
              SizedBox(
                height: Utils.resizeWidthUtil(context, 30),
              ),
              Container(
                height: 0.5,
                color: Colors.black12,
              )
            ],
          )),
        ],
      );

  Widget _buildGroupSelectItem(dynamic itemData) => CircleAvatar(
        maxRadius: 22,
        backgroundColor: itemData['avatar']['v'] != '' ? Colors.transparent : only_color,
        child: itemData['avatar']['v'] != ''
            ? CachedNetworkImage(
                imageUrl: '$avatarUrlAPIs${itemData['avatar']['v']}',
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 1, color: only_color),
                    image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
                placeholder: (context, url) => CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
            : TKText(
                itemData['full_name']['v'].toString().substring(0, 1),
                tkFont: TKFont.SFProDisplayBold,
                style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 40), color: Colors.white),
              ),
      );
}
