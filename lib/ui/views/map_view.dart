// ignore_for_file: missing_required_param

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/title_content_widget.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:http/http.dart' as http;

class MapView extends StatefulWidget {
  final dynamic data;

  MapView(this.data);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  double _cameraZoom = 16, _itemHeightSuggestList = 70, _searchBarHeight = 50;
  GoogleMapController _googleMapController;
  TextEditingController _positionWorkEdtController = TextEditingController();
  List<PlacesSearchResult> _listPlace;
  Position _currentCameraPosition;
  MapType _mapType = MapType.normal;
  bool _showSuggestionList = true,
      _showSearchList = false,
      _showSelectedList = false;
  List<dynamic> _listDefaultLocation = [];
  AnimationController expandController;
  Animation<double> animation;
  List<dynamic> _listSelected = [];
  bool _showIconHand = false;
  AnimationController animationController;
  int _idMarkerSelected;
  FocusNode _focusSearch = FocusNode();
  GoogleMapsPlaces places;
  List<dynamic> listApiKey = [];
  bool _isShowHistory = false;
  List<PlacesSearchResult> _listPlaceHistory;

  @override
  void initState() {
    super.initState();
    initGoogleMap();
    _getDefaultPosition();
    _prepareAnimations();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    animationController.repeat();
    _focusSearch.requestFocus();
  }

  initGoogleMap() async {
    String apiKey =
        await SecureStorage().getCustomString(SecureStorage.GOOGLE_KEY);
    listApiKey = jsonDecode(apiKey).toList();
    places = GoogleMapsPlaces(apiKey: listApiKey[0]);
    setState(() {});
  }

  startRotation() {
    animationController.repeat();
  }

  stopRotation() {
    animationController.stop();
  }

  @override
  void dispose() {
    _positionWorkEdtController.dispose();
    animationController.dispose();
    expandController.dispose();
    super.dispose();
  }

  void _prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  _moveCamera(Position position) {
    _googleMapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          position.latitude,
          position.longitude,
        ),
      ),
    );
  }

  _updateMarker(Position position) async {
    if (_idMarkerSelected != null) {
      int id = _idMarkerSelected;
      _listSelected[id]['marker'] = Marker(
          markerId: MarkerId(id.toString()),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarker,
          onTap: () {
            _showInfo(_listSelected[id]);
          });
      _listSelected[_idMarkerSelected]['latitude'] =
          position.latitude.toStringAsFixed(6);
      _listSelected[_idMarkerSelected]['longitude'] =
          position.longitude.toStringAsFixed(6);
      _listSelected[_idMarkerSelected]['defaultID'] = -1;
      _listSelected[_idMarkerSelected]['otherID'] = 1;
      _currentCameraPosition = position;
      setState(() {});
    }
  }

  void _getDefaultPosition() async {
    var response = await BaseViewModel().callApis(
        {}, locationOutsideUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      _listDefaultLocation = response.data['data'];
      setState(() {});
    }
  }

  void submitData() async {
    showLoadingDialog(context);
    BaseViewModel model = BaseViewModel();
    var response = await model.callApis(
        widget.data['data'], addDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      var encryptDataV2 =
          await Utils.encrypt("${widget.data['childTableName']}");
      for (int i = 0; i < _listSelected.length; i++) {
        var childrenData = {
          "tbname": encryptDataV2,
          widget.data['type'] == 'outside'
              ? "outsideCalendar_ID"
              : 'overtime_ID': response.data['data'][0]['dataid'],
          "latitude_mutil": _listSelected[i]['latitude'],
          "longitude_mutil": _listSelected[i]['longitude'],
          "location_id_default_mutil": _listSelected[i]['defaultID'],
          "location_id_check_mutil": _listSelected[i]['otherID'],
          "to_place_mutil": _listSelected[i]['name'],
          "to_place_mutil_full": _listSelected[i]['address'] == null
              ? ''
              : _listSelected[i]['address']
        };
        var responseV2 = await model.callApis(
            childrenData, addDataUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        if (responseV2.status.code != 200) {
          Navigator.pop(context);
          showMessageDialog(context,
              description: Utils.getString(context, txt_register_failed));
          break;
        } else if (i == _listSelected.length - 1 &&
            responseV2.status.code == 200) {
          Future.delayed(Duration(seconds: 2), () async {
            var responseV3 = await model.callApis({
              "tbname": widget.data['data']['tbname'],
              "dataid": response.data['data'][0]['dataid'],
              "iscomplete": true
            }, updateDataUrl, method_post,
                isNeedAuthenticated: true, shouldSkipAuth: false);
            if (responseV3.status.code == 200) {
              Navigator.pop(context);
              showMessageDialogIOS(context,
                  description: Utils.getString(context, txt_register_success),
                  onPress: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, Routers.main, (r) => false);
              });
            } else
              showMessageDialog(context,
                  description: Utils.getString(context, txt_register_failed));
          });
        }
      }
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_register_failed));
  }

  Future updatePlace(Location location, int idMarker) async {
    PlacesSearchResponse response =
        await places.searchNearbyWithRankBy(location, 'distance', type: '');
    _listSelected[idMarker]['name'] = response.results[0].name;
    PlaceDetails placeDetails =
        await getDetailByPlaceID(response.results[0].placeId);
    _listSelected[idMarker]['address'] =
        placeDetails.formattedAddress.replaceAll("Vietnam", "Việt Nam");
    _listSelected[idMarker]['latitude'] = location.lat;
    _listSelected[idMarker]['longitude'] = location.lng;
    _listSelected[idMarker]['marker'] = Marker(
        markerId: MarkerId(idMarker.toString()),
        position: LatLng(location.lat, location.lng),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () {
          _showInfo(_listSelected[idMarker], editMarker: true);
        });
    _showInfo(_listSelected[idMarker], editMarker: true);
    _idMarkerSelected = null;
  }

  Future<List<PlacesSearchResult>> getListSuggestion(String newValue) async {
    List<PlacesSearchResult> finalResponse;
    for (int i = 0; i < listApiKey.length; i++) {
      places = GoogleMapsPlaces(apiKey: listApiKey[i]);
      PlacesSearchResponse response = await places.searchByText(newValue);
      if (response.status == 'OK') {
        finalResponse = response.results;
        break;
      }
    }
    if (finalResponse == null) {
      finalResponse = [];
      var response = await http.post(
          Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=$newValue&format=json&polygon=1&addressdetails=1'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          });
      if (jsonDecode(response.body).length > 0)
        for (var item in jsonDecode(response.body)) {
          finalResponse.add(PlacesSearchResult(
              placeId: item['place_id'].toString(),
              name: item['display_name'].split(',')[0],
              formattedAddress: item['display_name'],
              geometry: Geometry(
                  location: Location.fromJson({
                'lat': num.parse(item['lat']),
                'lng': num.parse(item['lon'])
              })),
              vicinity: item['display_name'],
              reference: ''));
        }
    }
    if (finalResponse == null || finalResponse.length == 0) {
      showMessageDialog(context, description: 'Không tìm thấy vị trí!');
    }
    return finalResponse;
  }

  Future<List<PlacesSearchResult>> searchPlaceFromLatLong(
      Location location) async {
    List<PlacesSearchResult> finalResponse;
    for (int i = 0; i < listApiKey.length; i++) {
      places = GoogleMapsPlaces(apiKey: listApiKey[i]);
      PlacesSearchResponse response =
          await places.searchNearbyWithRankBy(location, 'distance', type: '');
      if (response.status == 'OK') {
        finalResponse = response.results;
        break;
      }
    }
    return finalResponse.toList();
  }

  Future<PlaceDetails> getDetailByPlaceID(String placeId) async {
    PlaceDetails finalResponse;
    for (int i = 0; i < listApiKey.length; i++) {
      places = GoogleMapsPlaces(apiKey: listApiKey[i]);
      PlacesDetailsResponse response =
          await places.getDetailsByPlaceId(placeId);
      if (response.status == 'OK') {
        finalResponse = response.result;
        break;
      }
    }
    return finalResponse;
  }

  getHistoryPlaces() async {
    if (_listPlaceHistory == null) {
      var response = await BaseViewModel().callApis(
          {}, widget.data['type'] == 'outside' ? LocationOutsideEmployee : LocationOvertimeEmployee, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      if (response.status.code == 200) {
        if (response.data['data'].length > 0) {
          _listPlaceHistory = [];
          for (var item in response.data['data']) {
            _listPlaceHistory.add(PlacesSearchResult(
                placeId: item['ID'].toString(),
                name: item['to_place_mutil']['v'],
                formattedAddress: item['to_place_mutil_full']['v'],
                geometry: Geometry(
                    location: Location.fromJson({
                  'lat': num.parse(item['latitude_mutil']['v']),
                  'lng': num.parse(item['longitude_mutil']['v'])
                })),
                vicinity: item['to_place_mutil_full']['v'] == ''
                    ? item['to_place_mutil']['v']
                    : item['to_place_mutil_full']['v'],
                reference: ''));
          }
        }
      }
    }
    setState(() {
      _listPlace = _listPlaceHistory;
      _showSearchList = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          listApiKey.length == 0 ? CircularProgressIndicator() : _buildMap(),
          _actionButtons(context),
          if (_focusSearch.hasFocus || _showSuggestionList || _showSelectedList || _showSearchList)
            _buildOutSideClick(),
          _buildSuggestionList(),
          if (_listPlace != null) _buildSearchList(),
          _iconHand(),
          _buildPlaceSearch(),
          if (_showSelectedList) _buildSelectedList(),
        ],
      ),
    );
  }

  Widget _iconMyLocations(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showLoadingDialog(context);
        Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        ).then((position) async {
          _googleMapController.moveCamera(CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude)));
          _listPlace = await searchPlaceFromLatLong(
              Location(lat: position.latitude, lng: position.longitude));
          setState(() {
            _showSearchList = true;
            _showSuggestionList = true;
          });
          Navigator.pop(context);
          /*searchPlaceFromLatLong(Location(position.latitude, position.longitude)).then((places) {
              places.asMap().forEach((index, item) async {
                PlaceDetails placeDetails = await getDetailByPlaceID(item.placeId);
                item.formattedAddress = placeDetails.formattedAddress.replaceAll("Vietnam", "Việt Nam");
                if (index == places.length - 1) {
                  setState(() {
                    _showSearchList = true;
                    _listPlace = places;
                    _showSuggestionList = true;
                  });
                  Navigator.pop(context);
                }
              });
            }).catchError((e) {});*/
        }).catchError((e) {
          print(e);
        });
      },
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.8),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Icon(
          Icons.location_searching,
          color: txt_grey_color_v1,
        ),
      ),
    );
  }

  Widget _iconMapType() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_mapType == MapType.normal)
            _mapType = MapType.hybrid;
          else
            _mapType = MapType.normal;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.8),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Icon(
          Icons.map,
          color: _mapType == MapType.normal ? txt_grey_color_v1 : only_color,
        ),
      ),
    );
  }

  Widget _iconLocations() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSelectedList = true;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.8),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Image.asset(ic_locations),
      ),
    );
  }

  Widget _buildMap() => GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        setState(() {
          _googleMapController = controller;
        });
      },
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
          zoom: _cameraZoom,
          target: _currentCameraPosition != null
              ? LatLng(_currentCameraPosition.latitude,
                  _currentCameraPosition.longitude)
              : Utils.latLngCompany),
      onCameraIdle: () async {
        if (_idMarkerSelected != null) {
          await updatePlace(
              Location(
                  lat: _currentCameraPosition.latitude,
                  lng: _currentCameraPosition.longitude),
              _idMarkerSelected);
        }
      },
      onCameraMove: (_position) async {
        if (_idMarkerSelected != null)
          _updateMarker(Position(
              latitude: _position.target.latitude,
              longitude: _position.target.longitude));
      },
      mapType: _mapType,
      markers:
          _listSelected.map((value) => (value['marker'] as Marker)).toSet());

  Widget _iconHand() => Visibility(
        visible: _showIconHand,
        child: GestureDetector(
          onTap: () {
            stopRotation();
            setState(() {
              _showIconHand = false;
            });
          },
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black.withOpacity(0.5),
            padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.4,
                MediaQuery.of(context).size.height * 0.6,
                0,
                0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AnimatedBuilder(
                  animation: animationController,
                  child: Image.asset(
                    ic_hand_move,
                    color: white_color,
                    height: Utils.resizeWidthUtil(context, 150),
                    width: Utils.resizeWidthUtil(context, 150),
                  ),
                  builder: (BuildContext context, Widget _widget) {
                    return Transform.rotate(
                      angle: animationController.value * -0.5,
                      origin: Offset(10.0, 50.0),
                      child: _widget,
                    );
                  },
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 10),
                ),
                TKText(
                  Utils.getString(context, txt_direction_change_location),
                  textAlign: TextAlign.center,
                  tkFont: TKFont.SFProDisplaySemiBold,
                  style: TextStyle(
                      color: white_color,
                      fontSize: Utils.resizeWidthUtil(context, 28)),
                )
              ],
            ),
          ),
        ),
      );

  Widget _buildSuggestionList() {
    double heightList = _showSuggestionList
        ? ((_listDefaultLocation.length > 5 ? 5 : _listDefaultLocation.length) *
                _itemHeightSuggestList) +
            10
        : 0;
    return SafeArea(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(top: _searchBarHeight + 25, left: 5, right: 5),
        height: heightList,
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Container(
                  height: heightList,
                  padding: EdgeInsets.only(top: 10),
                  child: ListView.builder(
                      itemCount: _listDefaultLocation.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _itemSuggestList(_listDefaultLocation[index]);
                      }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchList() {
    double heightList = _showSearchList
        ? (_listPlace.length * _itemHeightSuggestList) >
                (MediaQuery.of(context).size.height * 0.7)
            ? MediaQuery.of(context).size.height * 0.7
            : _listPlace.length * _itemHeightSuggestList
        : 0;
    return SafeArea(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(top: _searchBarHeight + 25, left: 5, right: 5),
        height: heightList,
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Container(
                    height: heightList,
                    child: ListView.builder(
                        itemCount: _listPlace.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _itemSearchList(_listPlace[index]);
                        }),
                  )),
            )
          ],
        ),
      ),
    );
  }

  Widget _itemSuggestList(location) {
    return GestureDetector(
      onTap: () {
        _moveCamera(Position(
            latitude: num.parse(location['ID'] != null
                ? location['lat']['v']
                : location['latitude']),
            longitude: num.parse(location['ID'] != null
                ? location['long']['v']
                : location['longitude'])));
        _showInfo(location, isRePick: location['ID'] == null);
        _showSuggestionList = false;
        setState(() {});
      },
      child: Container(
          padding: EdgeInsets.only(left: 10),
          height: _itemHeightSuggestList,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TKText(
                  location['ID'] != null
                      ? location['name']['v']
                      : location['name'].toString(),
                  maxLines: 2,
                  tkFont: TKFont.SFProDisplaySemiBold,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 32),
                      color: txt_grey_color_v2),
                ),
                TKText(
                  location['ID'] != null
                      ? location['location']['v']
                      : location['address'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      color: txt_grey_color_v1),
                ),
              ])),
    );
  }

  Widget _itemSearchList(PlacesSearchResult place) {
    return GestureDetector(
      onTap: () {
        _moveCamera(Position(
            latitude: place.geometry.location.lat,
            longitude: place.geometry.location.lng));
        _showInfo(place);
        _showSearchList = false;
        _isShowHistory = false;
        _positionWorkEdtController.text = '';
        _focusSearch.unfocus();
      },
      child: Container(
          padding: EdgeInsets.only(left: 10),
          margin: EdgeInsets.only(top: 10),
          height: _itemHeightSuggestList,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TKText(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  tkFont: TKFont.SFProDisplaySemiBold,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 32),
                      color: txt_grey_color_v2),
                ),
                TKText(
                  place.formattedAddress != null
                      ? place.formattedAddress
                      : place.vicinity != null
                          ? place.vicinity
                          : '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      color: txt_grey_color_v1),
                ),
              ])),
    );
  }

  Widget _buildOutSideClick() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _focusSearch.unfocus();
        setState(() {
          _showSearchList = false;
          _showSuggestionList = false;
        });
      },
      child: SizedBox.expand(),
    );
  }

  Widget _buildPlaceSearch() {
    return SafeArea(
      child: Container(
        // height: _searchBarHeight,
        margin: EdgeInsets.only(top: 20, left: 5, right: 5),
        child: Stack(
          children: <Widget>[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                margin: EdgeInsets.only(left: 20),
                padding: EdgeInsets.only(left: 10, right: 40),
                child: TextField(
                    onSubmitted: (value) async {
                      if (value.isNotEmpty)
                        getListSuggestion(
                                _positionWorkEdtController.text.trim())
                            .then((places) {
                          setState(() {
                            _showSearchList = true;
                            _listPlace = places;
                          });
                        }).catchError((e) {});
                    },
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        _showSuggestionList = false;
                      } else {
                        _showSearchList = false;
                        _showSuggestionList = true;
                      }
                      setState(() {});
                    },
                    controller: _positionWorkEdtController,
                    focusNode: _focusSearch,
                    onTap: () {
                      if (_listDefaultLocation.length > 0 &&
                          _positionWorkEdtController.text.isEmpty) {
                        _showSuggestionList = true;
                        setState(() {});
                      }
                    },
                    style: TextStyle(
                      fontFamily: "SFProDisplay-Medium",
                      fontSize: Utils.resizeWidthUtil(context, 32),
                    ),
                    decoration: InputDecoration(
                        hintText:
                            Utils.getString(context, txt_find_location_outside),
                        hintStyle: TextStyle(fontFamily: "SFProDisplay-Medium"),
                        border: InputBorder.none)),
              ),
            ),
            Positioned(
              left: -5,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  child: Icon(Icons.arrow_back),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      getHistoryPlaces();
                    },
                    child: Container(
                      // width: 50,
                      child: Icon(Icons.history),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_positionWorkEdtController.text != '') {
                        _positionWorkEdtController.text = '';
                        if (_listDefaultLocation.length > 0) {
                          setState(() {
                            _showSuggestionList = true;
                          });
                        }
                      } else {
                        _focusSearch.unfocus();
                        if (_showSuggestionList) {
                          setState(() {
                            _showSuggestionList = false;
                          });
                        }
                      }
                    },
                    child: Container(
                      width: 50,
                      child: Icon(Icons.clear),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
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
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.9,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(height: 12),
                  TKText('Vị trí công tác',
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 32),
                          color: txt_grey_color_v2,
                          fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                        itemCount: _listSelected.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            direction: DismissDirection.endToStart,
                            background: Container(
                                padding: EdgeInsets.only(right: 16),
                                alignment: Alignment.centerRight,
                                color: Colors.grey,
                                child: Icon(Icons.restore_from_trash,
                                    color: Colors.white, size: 30)),
                            key: UniqueKey(),
                            onDismissed: (direction) {
                              // Remove the item from the data source.
                              if (_listSelected[index]['defaultID'] == 1)
                                _listDefaultLocation.add(_listSelected[index]);
                              _listSelected.removeAt(index);
                              if (_listSelected.length == 0)
                                _showSelectedList = false;
                              setState(() {});
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _showSelectedList = false;
                                _moveCamera(Position(
                                    latitude: _listSelected[index]['latitude']
                                            is double
                                        ? _listSelected[index]['latitude']
                                        : double.parse(
                                            _listSelected[index]['latitude']),
                                    longitude: _listSelected[index]['longitude']
                                            is double
                                        ? _listSelected[index]['longitude']
                                        : double.parse(_listSelected[index]
                                            ['longitude'])));
                                _showInfo(_listSelected[index],
                                    editMarker: true);
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                        bottom: BorderSide(
                                            color: index ==
                                                    _listSelected.length - 1
                                                ? Colors.white
                                                : Colors.grey,
                                            width: 0.5))),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height:
                                          Utils.resizeWidthUtil(context, 60),
                                      width: Utils.resizeWidthUtil(context, 60),
                                      alignment: Alignment.center,
                                      margin: EdgeInsets.only(
                                          right: Utils.resizeWidthUtil(
                                              context, 20)),
                                      decoration: BoxDecoration(
                                          color: blue_light,
                                          shape: BoxShape.circle),
                                      child: TKText(
                                        '${index + 1}',
                                        tkFont: TKFont.SFProDisplaySemiBold,
                                        style: TextStyle(color: white_color),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          SizedBox(height: 5),
                                          TKText(
                                            _listSelected[index]['defaultID'] !=
                                                    null
                                                ? _listSelected[index]['name']
                                                : _listSelected[index]['name']
                                                    ['v'],
                                            maxLines: 2,
                                            tkFont: TKFont.SFProDisplaySemiBold,
                                            style: TextStyle(
                                                fontSize: Utils.resizeWidthUtil(
                                                    context, 32),
                                                color: txt_grey_color_v2),
                                          ),
                                          TKText(
                                            _listSelected[index]['defaultID'] !=
                                                    null
                                                ? _listSelected[index]
                                                    ['address']
                                                : _listSelected[index]
                                                    ['location']['v'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            tkFont: TKFont.SFProDisplayRegular,
                                            style: TextStyle(
                                                fontSize: Utils.resizeWidthUtil(
                                                    context, 28),
                                                color: txt_grey_color_v1),
                                          ),
                                          SizedBox(height: 10),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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

  _showInfo(dynamic location,
          {bool editMarker = false, bool isRePick = false}) =>
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
                height: MediaQuery.of(context).size.height * 0.4,
                padding: EdgeInsets.only(
                    top: Utils.resizeWidthUtil(context, 15),
                    left: Utils.resizeWidthUtil(context, 20),
                    right: Utils.resizeWidthUtil(context, 20)),
                decoration: BoxDecoration(
                    color: white_color,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        topLeft: Radius.circular(20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: txt_grey_color_v1.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 5,
                      width: Utils.resizeWidthUtil(context, 100),
                      decoration: BoxDecoration(
                          color: txt_grey_color_v1.withOpacity(0.3),
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                    ),
                    SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: Utils.resizeWidthUtil(context, 80),
                          width: Utils.resizeWidthUtil(context, 80),
                          margin: EdgeInsets.only(
                              right: Utils.resizeWidthUtil(context, 20)),
                          padding: EdgeInsets.all(
                              Utils.resizeWidthUtil(context, 20)),
                          decoration: BoxDecoration(
                              color: blue_light.withOpacity(0.3),
                              shape: BoxShape.circle),
                          child: Image.asset(
                            ic_marker,
                            color: only_color,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TKText(
                                location is PlacesSearchResult
                                    ? location.name
                                    : editMarker || isRePick
                                        ? location['name'].toString()
                                        : location['name']['v'],
                                maxLines: 2,
                                tkFont: TKFont.SFProDisplaySemiBold,
                                style: TextStyle(
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 32),
                                    color: txt_grey_color_v2),
                              ),
                              TKText(
                                location is PlacesSearchResult
                                    ? location.formattedAddress
                                    : editMarker || isRePick
                                        ? location['address'].toString()
                                        : location['location']['v'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                tkFont: TKFont.SFProDisplayRegular,
                                style: TextStyle(
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 28),
                                    color: txt_grey_color_v1),
                              ),
                              titleContentWidget(
                                  context,
                                  txt_coordinate,
                                  '${location is PlacesSearchResult ? location.geometry.location.lat : editMarker || isRePick ? location['latitude'].toString() : location['lat']['v']}'
                                  ', ${location is PlacesSearchResult ? location.geometry.location.lng : editMarker || isRePick ? location['longitude'].toString() : location['long']['v']}',
                                  color: bg_text_field,
                                  margin: EdgeInsets.only(
                                      top: Utils.resizeHeightUtil(context, 20),
                                      bottom:
                                          Utils.resizeHeightUtil(context, 20)),
                                  padding: EdgeInsets.all(
                                      Utils.resizeWidthUtil(context, 20))),
                            ],
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            TKButton(
                              Utils.getString(
                                  context, txt_remove_out_site_place),
                              backgroundColor: only_color,
                              width: Utils.resizeWidthUtil(context, 300),
                              onPress: () async {
                                _listSelected.removeWhere((element) =>
                                    element['marker'].markerId ==
                                    location['marker'].markerId);
                                if (!(location is PlacesSearchResult))
                                  _listDefaultLocation.add(location);
                                _focusSearch.unfocus();
                                _showSuggestionList = false;
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                            TKButton(
                              Utils.getString(
                                  context,
                                  editMarker
                                      ? txt_change_out_site_place
                                      : txt_add_out_site_place),
                              backgroundColor: txt_fail_color,
                              width: Utils.resizeWidthUtil(context, 300),
                              onPress: () async {
                                if (editMarker) {
                                  Navigator.pop(context);
                                  startRotation();
                                  _idMarkerSelected = num.parse(
                                      location['marker'].markerId.value);
                                  String checkManual = await SecureStorage()
                                      .getCustomString('manual');
                                  if (checkManual == null ||
                                      checkManual.isEmpty) {
                                    _showIconHand = true;
                                    await SecureStorage()
                                        .saveCustomString('manual', 'yes');
                                  }
                                } else {
                                  int id = _listSelected.length;
                                  var newLocation;
                                  if (location is PlacesSearchResult) {
                                    newLocation = {
                                      "name": location.name,
                                      "address": location.formattedAddress,
                                      "latitude":
                                          location.geometry.location.lat,
                                      "longitude":
                                          location.geometry.location.lng,
                                      "defaultID": -1,
                                      "otherID": 1,
                                      "marker": Marker(
                                          markerId: MarkerId(id.toString()),
                                          position: LatLng(
                                              location.geometry.location.lat,
                                              location.geometry.location.lng),
                                          icon: BitmapDescriptor.defaultMarker,
                                          onTap: () {
                                            _showInfo(newLocation,
                                                editMarker: true);
                                          })
                                    };
                                  } else {
                                    newLocation = {
                                      "name": isRePick
                                          ? location['name']
                                          : location['name']['v'],
                                      "address": isRePick
                                          ? location['address']
                                          : location['location']['v'],
                                      "latitude": isRePick
                                          ? location['latitude']
                                          : location['lat']['v'],
                                      "longitude": isRePick
                                          ? location['longitude']
                                          : location['long']['v'],
                                      "defaultID": 1,
                                      "otherID": 1,
                                      'marker': Marker(
                                          markerId: MarkerId(id.toString()),
                                          position: LatLng(
                                              double.parse(isRePick
                                                  ? location['latitude']
                                                  : location['lat']['v']),
                                              double.parse(isRePick
                                                  ? location['longitude']
                                                  : location['long']['v'])),
                                          icon: BitmapDescriptor.defaultMarker,
                                          onTap: () {
                                            _showInfo(newLocation,
                                                editMarker: true);
                                          })
                                    };
                                    _listDefaultLocation.removeWhere(
                                        (element) => element == location);
                                  }
                                  _listSelected.add(newLocation);
                                  Navigator.pop(context);
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )).whenComplete(() {
        if (_positionWorkEdtController.text.isEmpty && _focusSearch.hasFocus) {
          setState(() {
            _showSuggestionList = true;
          });
        } else {
          _showSuggestionList = false;
          FocusScope.of(context).requestFocus(new FocusNode());
        }
      });

  Widget _actionButtons(BuildContext context) => Positioned(
        bottom: 10,
        right: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _iconMapType(),
            SizedBox(height: 10),
            _iconMyLocations(context),
            SizedBox(height: 10),
            if (_listSelected.length > 0) _iconLocations(),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                if (_listSelected.length > 0) _showConfirmInfo();
              },
              child: Container(
                padding:
                    EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    color: _listSelected.length > 0
                        ? only_color
                        : txt_grey_color_v1.withOpacity(0.5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TKText(
                      Utils.getString(context, txt_continue),
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 32),
                          color: white_color),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: white_color,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      );

  _showConfirmInfo() => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.86,
          padding: EdgeInsets.only(
              left: Utils.resizeWidthUtil(context, 20),
              right: Utils.resizeWidthUtil(context, 20),
              bottom: Utils.resizeWidthUtil(context, 20),
              top: Utils.resizeWidthUtil(context, 10)),
          decoration: BoxDecoration(
            color: white_color,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: widget.data['type'] == 'outside'
                          ? confirmContentOutside()
                          : confirmContentOvertime(),
                    ),
                  ),
                  SizedBox(height: 50 + Utils.resizeWidthUtil(context, 30)),
                ],
              ),
              Container(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 5,
                  width: Utils.resizeWidthUtil(context, 100),
                  decoration: BoxDecoration(
                      color: txt_grey_color_v1.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: TKButton(
                  Utils.getString(context, txt_button_send),
                  onPress: () {
                    submitData();
                  },
                ),
              )
            ],
          ),
        );
      });

  Widget confirmContentOutside() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 25),
          TKText(
            Utils.getString(context, txt_confirm_info),
            tkFont: TKFont.SFProDisplaySemiBold,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 32),
                color: txt_grey_color_v3),
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.access_time,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(Utils.getString(context, txt_time_register))
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _timeOff(),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.date_range,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(
                      widget.data['gen_row_define']['quota_outside']['name'])
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _textContent(
                    widget.data['data']['quota_outside'].toString()),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.motorcycle,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['transport']['name'])
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _textContent(widget.data['data']['transport']),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.assignment,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['content']['name'])
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _textContent(widget.data['data']['content']),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.location_on,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['location_id_default']
                      ['name'])
                ],
              ),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        vertical: Utils.resizeHeightUtil(context, 10)),
                    itemCount: _listSelected.length,
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            height: Utils.resizeWidthUtil(context, 60),
                            width: Utils.resizeWidthUtil(context, 60),
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(
                                right: Utils.resizeWidthUtil(context, 20)),
                            decoration: BoxDecoration(
                                color: blue_light, shape: BoxShape.circle),
                            child: TKText(
                              '${index + 1}',
                              tkFont: TKFont.SFProDisplaySemiBold,
                              style: TextStyle(color: white_color),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TKText(
                                  _listSelected[index]['name'],
                                  maxLines: 2,
                                  tkFont: TKFont.SFProDisplaySemiBold,
                                  style: TextStyle(
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 32),
                                      color: txt_grey_color_v2),
                                ),
                                TKText(
                                  _listSelected[index]['address'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  tkFont: TKFont.SFProDisplayRegular,
                                  style: TextStyle(
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 28),
                                      color: txt_grey_color_v1),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          )
                        ],
                      );
                    }),
              )
            ],
          )
        ],
      );

  Widget confirmContentOvertime() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 25),
          TKText(
            Utils.getString(context, txt_confirm_info),
            tkFont: TKFont.SFProDisplaySemiBold,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 32),
                color: txt_grey_color_v3),
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.access_time,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(Utils.getString(context, txt_time_register))
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _timeOff(),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.timelapse,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['break_time_employee']
                      ['name'])
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _textContent(
                    widget.data['data']['break_time_employee'].toString()),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.assignment,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['reason']['name'])
                ],
              ),
              SizedBox(height: 5),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: _textContent(widget.data['data']['reason']),
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.location_on,
                    color: only_color,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  _getTitle(widget.data['gen_row_define']['place_name']['name'])
                ],
              ),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.only(left: 30),
                child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        vertical: Utils.resizeHeightUtil(context, 10)),
                    itemCount: _listSelected.length,
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            height: Utils.resizeWidthUtil(context, 60),
                            width: Utils.resizeWidthUtil(context, 60),
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(
                                right: Utils.resizeWidthUtil(context, 20)),
                            decoration: BoxDecoration(
                                color: blue_light, shape: BoxShape.circle),
                            child: TKText(
                              '${index + 1}',
                              tkFont: TKFont.SFProDisplaySemiBold,
                              style: TextStyle(color: white_color),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TKText(
                                  _listSelected[index]['name'],
                                  maxLines: 2,
                                  tkFont: TKFont.SFProDisplaySemiBold,
                                  style: TextStyle(
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 32),
                                      color: txt_grey_color_v2),
                                ),
                                TKText(
                                  _listSelected[index]['address'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  tkFont: TKFont.SFProDisplayRegular,
                                  style: TextStyle(
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 28),
                                      color: txt_grey_color_v1),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          )
                        ],
                      );
                    }),
              )
            ],
          )
        ],
      );

  Widget _getTitle(String title) => TKText(
        title,
        tkFont: TKFont.SFProDisplayRegular,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 32),
            color: txt_grey_color_v3),
      );

  Widget _timeOff() => Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              _iconCircleTime(),
              Container(
                height: Utils.resizeHeightUtil(context, 50),
                width: 2,
                color: button_color,
              ),
              _iconCircleTime()
            ],
          ),
          SizedBox(
            width: Utils.resizeWidthUtil(context, 35),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(widget.data['from_time'],
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        color: txt_grey_color_v1,
                        fontSize: Utils.resizeWidthUtil(context, 28))),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                TKText(widget.data['to_time'],
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        color: txt_grey_color_v1,
                        fontSize: Utils.resizeWidthUtil(context, 28))),
              ],
            ),
          )
        ],
      );

  Widget _iconCircleTime() {
    return Container(
      width: Utils.resizeWidthUtil(context, 23),
      height: Utils.resizeWidthUtil(context, 23),
      decoration: BoxDecoration(
          border: Border.all(
              color: button_color, width: Utils.resizeWidthUtil(context, 5)),
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 11.4))),
    );
  }

  Widget _textContent(String text) => TKText(text,
      tkFont: TKFont.SFProDisplayRegular,
      style: TextStyle(
          color: txt_grey_color_v1,
          fontSize: Utils.resizeWidthUtil(context, 28),
          fontFamily: "SFProDisplay-Regular"));
}
