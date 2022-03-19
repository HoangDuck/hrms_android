import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:image_picker/image_picker.dart';

class ChatRoomView extends StatefulWidget {
  final data;

  ChatRoomView(this.data);

  @override
  _ChatRoomViewState createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  TextEditingController _textSearchController = TextEditingController();
  TextEditingController _textGroupController = TextEditingController();
  dynamic _users;
  List<dynamic> _listRoom = [];
  List<dynamic> _listSearchSuggest = [];
  bool _searching = false;
  List<dynamic> _listGroupSelected = [];
  File _avatarGroup;
  FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    _initUser();
  }

  @override
  void dispose() {
    _textSearchController.dispose();
    _textGroupController.dispose();
    FToast().removeCustomToast();
    super.dispose();
  }

  _initUser() async {
    SecureStorage().userProfile.then((userProfile) {
      _users = userProfile.data['data'][0];
      _getListRoomWithUser();
    });
    _connect();
  }

  _connect() {
    mQttServices.subscribe('GSCHAT');
    mQttServices.mqttClient.updates.listen((event) async {
      String message = await mQttServices.onMessage(event);
      switch (message[0]) {
        case '#':
          message = message.replaceAll('#', '');
          if (message.split('/')[0] == _users['ID']) return;
          int indexCheck = _listRoom.indexWhere((element) => element['ID'] == message.split('/')[1]);
          if (indexCheck != null) _reloadOnlyRoom(indexCheck);
          break;
        case '%':
          dynamic data = jsonDecode(message.replaceAll('%', ''));
          if (data['IDUserDelete'] == _users['ID'])
            setState(() {
              _listRoom.removeWhere((element) => element['ID'] == data['RoomID']);
            });
          break;
        case '@':
          dynamic data = jsonDecode(message.replaceAll('@', ''));
          if (data['ListUser']
              .split(';')
              .indexWhere((element) => element == _users['ID'].toString() && data['IDUserSent'] != _users['ID'].toString()) != -1)
            setState(() {
              _listRoom.add(data['RoomData']);
            });
            break;
        default:
          return;
      }
    });
  }

  _reloadOnlyRoom(int index) async {
    var roomResponse = await BaseViewModel().callApis(
        {"roomID": _listRoom[index]['ID'], "userID": _users['ID']}, chatGetRoomWithID, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (roomResponse.status.code == 200) {
      if (roomResponse.data['data'].length > 0)
        setState(() {
          _listRoom[index] = roomResponse.data['data'][0];
        });
    }
  }

  _getListRoomWithUser() async {
    List<dynamic> _listTemp = [];
    var response = await BaseViewModel().callApis({"ID": _users['ID']}, chatGetListIdRoom, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var ele in response.data['data']) {
        if (ele['TypeRoom']['v'] == '1') {
          List<String> _listUser = ele['PaticipantUser']['v'].split(';');
          for (var userEle in _listUser) {
            if (userEle != _users['ID']) {
              var _partner = await BaseViewModel().callApis({"userID": userEle}, GetOnlyUserProfile, method_post,
                  shouldSkipAuth: false, isNeedAuthenticated: true);
              if (_partner.status.code == 200) {
                ele['RoomName'] = _partner.data['data'][0]['full_name'];
                ele['AvaGroup'] = _partner.data['data'][0]['avatar'];
                if (ele['LastMessage']['v'] != '')
                  _listTemp.add({
                    ...ele,
                    ...{'ChatUser': _partner.data['data'][0]}
                  });
              }
            }
          }
        } else
          _listTemp.add(ele);
      }
      if (mounted)
        setState(() {
          _listRoom = _listTemp;
        });
    }
  }

  _searchRoom(String searchText, StateSetter state) async {
    _listSearchSuggest.clear();
    state(() {
      _searching = true;
    });
    var response = await BaseViewModel().callApis({'search_text': searchText, 'condition': '1 = 1'}, chatEmployeeList, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
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

  _checkRoom({String type = 'single', dynamic userCheckID}) async {
    var response = await BaseViewModel().callApis({
      'condition_1': '${_users['ID']};${userCheckID['ID']}',
      'condition_2': '${userCheckID['ID']};${_users['ID']}'
    }, CheckSingleRoom, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      if (response.data['data'].length > 0) {
        Navigator.pushNamed(
          context,
          Routers.chatEmpView,
          arguments: {
            "RoomData": {
              ...response.data['data'][0],
              ...{'ChatUser': userCheckID}
            }
          },
        ).then((value) {
          Navigator.pop(context);
        });
      } else {
        var createRoomResponse = await BaseViewModel().callApis({
          "tbname": 'xy3hrQRA0dDamQvkcYX2/w==',
          "MqttTopic": _createToken([_users['ID'], userCheckID['ID']]),
          'PaticipantUser': _createParticipantUser([_users['ID'], userCheckID['ID']]),
          "TypeRoom": 1,
          'KeyUser': _users['ID'],
        }, addDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
        if (createRoomResponse.status.code == 200) {
          await BaseViewModel().callApis({
            "listValues": _createRoomParticipant(
                [_users['ID'], userCheckID['ID']], createRoomResponse.data['data'][0]['dataid'].toString())
          }, InsertParticipant, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
          var selectData = await BaseViewModel().callApis({
            "roomID": createRoomResponse.data['data'][0]['dataid'],
            "userID": _users['ID']
          }, chatGetRoomWithID, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
          if (selectData.status.code == 200) {
            selectData.data['data'][0]['RoomName'] = userCheckID['full_name']['v'];
            selectData.data['data'][0]['AvaGroup'] = userCheckID['avatar']['v'];
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              Routers.chatEmpView,
              arguments: {
                "RoomData": {
                  ...selectData.data['data'][0],
                  ...{'ChatUser': userCheckID}
                }
              },
            ).then((value) {
              //_getListRoomWithUser();
            });
          }
        }
      }
    }
  }

  _createParticipantUser(List<String> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i] + (i < user.length - 1 ? ';' : '');
    }
    return participantUser;
  }

  _createToken(List<String> user) {
    String topic = '';
    for (var item in user) {
      topic = topic + item;
    }
    return topic;
  }

  _createRoomParticipant(List<String> user, String roomID) {
    String values = '';
    for (int i = 0; i < user.length; i++) {
      values = values + '( $roomID, ${user[i]} )' + (i < user.length - 1 ? ',' : '');
    }
    return values;
  }

  /*_createIDParticipant(List<String> user) {
    String participantUser = '';
    for (int i = 0; i < user.length; i++) {
      participantUser = participantUser + user[i] + (i < user.length - 1 ? ',' : '');
    }
    return participantUser;
  }*/

  _handleCheck(StateSetter state, int index) {
    state(() {
      _listGroupSelected.add(_listSearchSuggest[index]);
      _listSearchSuggest.removeAt(index);
    });
  }

  _showPopupCamera(TapDownDetails details, StateSetter state) {
    double left = details.globalPosition.dx;
    double top = details.globalPosition.dy;
    ImageSource imageSource;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
      items: [
        PopupMenuItem<String>(
            child: Row(
              children: [
                Icon(
                  Icons.photo_album,
                  color: Colors.black54,
                ),
                SizedBox(
                  width: 20,
                ),
                TKText('Thư viện'),
              ],
            ),
            value: 'library'),
        PopupMenuItem<String>(
            child: Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.black54,
                ),
                SizedBox(
                  width: 20,
                ),
                TKText('Camera'),
              ],
            ),
            value: 'camera')
      ],
      elevation: 8.0,
    ).then((value) async {
      switch (value) {
        case 'library':
          imageSource = ImageSource.gallery;
          break;
        case 'camera':
          imageSource = ImageSource.camera;
          break;
        default:
          print('none');
      }
      var imagePicker = await ImagePicker().getImage(source: imageSource, imageQuality: 50);
      state(() {
        _avatarGroup = File(imagePicker.path);
      });
    });
  }

  _createGroup(StateSetter state) async {
    if (_textGroupController.text == '') {
      _showToast('Bạn chưa đặt tên nhóm !');
      return;
    }
    showLoadingDialog(context);
    List<String> _listTopicMap = [];
    _listTopicMap.add(_users['ID']);
    _listGroupSelected.forEach((element) {
      _listTopicMap.add(element['ID']);
    });
    //create room
    var createRoomResponse = await BaseViewModel().callApis({
      "tbname": 'xy3hrQRA0dDamQvkcYX2/w==',
      "MqttTopic": _createToken(_listTopicMap),
      'PaticipantUser': _createParticipantUser(_listTopicMap),
      "RoomName": _textGroupController.text,
      if (_avatarGroup != null) 'AvaGroup': 'data:image/jpeg;base64,${base64Encode(_avatarGroup.readAsBytesSync())}',
      "TypeRoom": 2,
      'KeyUser': _users['ID'],
    }, addDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    //create participant
    if (createRoomResponse.status.code == 200) {
      var createParticipantResponse = await BaseViewModel().callApis({
        "listValues": _createRoomParticipant(_listTopicMap, createRoomResponse.data['data'][0]['dataid'].toString())
      }, InsertParticipant, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
      if (createParticipantResponse.status.code == 200) {
        var selectData = await BaseViewModel().callApis({
          "roomID": createRoomResponse.data['data'][0]['dataid'],
          "userID": _users['ID']
        }, chatGetRoomWithID, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
        if (selectData.status.code == 200) {
          _listRoom.add(selectData.data['data'][0]);
          Navigator.pop(context);
          Navigator.pop(context);
          setState(() {});
          Navigator.pushNamed(
            context,
            Routers.chatEmpView,
            arguments: {"RoomData": selectData.data['data'][0], 'isGroup': true},
          );
        }
      }
    }
  }

  _showToast(String text) {
    fToast.showToast(
      child: Container(
        margin: EdgeInsets.only(top: 0),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.grey.withOpacity(0.9),
        ),
        child: TKText(
          text,
          style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 26)),
        ),
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(
          context,
          () => Navigator.pop(context),
          () => showModalBottomSheet(
              context: context, isScrollControlled: true, builder: (context) => _buildBottomSheet(isGroup: true)),
          'Chat',
          Icons.group_add),
      body: Container(
        margin: EdgeInsets.only(top: Utils.resizeWidthUtil(context, 30), left: Utils.resizeWidthUtil(context, 30)),
        child: Column(
          children: [
            _buildSearch(),
            Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.only(top: Utils.resizeWidthUtil(context, 30)),
                    cacheExtent: 9999,
                    itemCount: _listRoom.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routers.chatEmpView,
                            arguments: {
                              "RoomData": _listRoom[index],
                              'isGroup': _listRoom[index]['TypeRoom']['v'] == '2'
                            },
                          ).then((value) {
                            if (value == 'deleteUser') _getListRoomWithUser();
                            setState(() {
                              _listRoom[index]['unSeenCount']['v'] = '0';
                            });
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              _buildListItem(_listRoom[index],
                                  isEnd: _listSearchSuggest.length - 1 == index, index: index),
                              SizedBox(
                                height: Utils.resizeWidthUtil(context, 30),
                              )
                            ],
                          ),
                        ),
                      );
                    }))
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() => GestureDetector(
        onTap: () {
          showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => _buildBottomSheet());
        },
        child: Container(
          margin: EdgeInsets.only(right: Utils.resizeWidthUtil(context, 30)),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(32),
          ),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              hintStyle: TextStyle(fontSize: 17),
              hintText: 'Tìm kiếm',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
      );

  Widget _buildBottomSheet({bool isGroup = false}) => Container(
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
                      if (isGroup)
                        Container(
                          margin: EdgeInsets.symmetric(
                              vertical: Utils.resizeWidthUtil(context, 10),
                              horizontal: Utils.resizeWidthUtil(context, 30)),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTapDown: (details) => _showPopupCamera(details, state),
                                child: _avatarGroup != null
                                    ? CircleAvatar(
                                        maxRadius: 22,
                                        backgroundColor: only_color,
                                        child: CircleAvatar(
                                          backgroundImage: FileImage(_avatarGroup),
                                        ),
                                      )
                                    : Icon(
                                        CupertinoIcons.camera_fill,
                                        color: Colors.black54,
                                        size: 30,
                                      ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _textGroupController,
                                  decoration: InputDecoration(
                                    hintStyle: TextStyle(fontSize: 17),
                                    hintText: 'Đặt tên nhóm (*)',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(20),
                                  ),
                                ),
                              ),
                            ],
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
                              _searchRoom(value, state);
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
                                    onTap: () => isGroup
                                        ? _handleCheck(state, index)
                                        : _checkRoom(type: 'single', userCheckID: _listSearchSuggest[index]),
                                    child: Container(
                                      color: Colors.transparent,
                                      child: !_searching
                                          ? _buildListItem(_listSearchSuggest[index],
                                              isSearch: true,
                                              isEnd: _listSearchSuggest.length - 1 == index,
                                              isGroup: isGroup)
                                          : Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                    ),
                                  ))))
                    ],
                  ),
                  isGroup && _listGroupSelected.length > 0
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
                                  onTap: () => _createGroup(state),
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
                      : SizedBox()
                ],
              )));

  Widget _buildListItem(dynamic itemData,
          {bool isSearch = false, bool isEnd = false, int index, bool isGroup = false}) =>
      Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                maxRadius: 22,
                backgroundColor:
                    itemData[isSearch ? 'avatar' : 'AvaGroup']['v'] != '' ? Colors.transparent : only_color,
                child: itemData[isSearch ? 'avatar' : 'AvaGroup']['v'] != ''
                    ? CachedNetworkImage(
                        imageUrl: '$avatarUrlAPIs${itemData[isSearch ? 'avatar' : 'AvaGroup']['v']}',
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
                        itemData[isSearch ? 'full_name' : 'RoomName']['v'].toString().substring(0, 1),
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
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TKText(
                            itemData[isSearch ? 'full_name' : 'RoomName']['v'],
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(fontSize: 20, color: neutral0.withOpacity(0.8)),
                          ),
                          if (!isSearch && itemData['LastMessage']['v'] != '') TKText(itemData['LastMessage']['v']),
                        ],
                      ),
                    ),
                    if (!isSearch && itemData['unSeenCount'] != null && itemData['unSeenCount']['v'] != '0')
                      CircleAvatar(
                        maxRadius: 10,
                        backgroundColor: txt_fail_color,
                        child: TKText(
                          itemData['unSeenCount']['v'],
                          tkFont: TKFont.SFProDisplayBold,
                          style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 18), color: Colors.white),
                        ),
                      ),
                    if (isGroup) Icon(CupertinoIcons.circle)
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
