// ignore_for_file: missing_required_param

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/title_content_widget.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class MapLocationOwnerView extends StatefulWidget {
  final dynamic data;

  MapLocationOwnerView(this.data);

  @override
  _MapLocationOwnerViewState createState() => _MapLocationOwnerViewState();
}

class _MapLocationOwnerViewState extends State<MapLocationOwnerView>
    with TickerProviderStateMixin {
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
  final places =
      GoogleMapsPlaces(apiKey: "AIzaSyDCzLHg5D-79ECAylCJDDV9h4SHlCMvFdI");

  @override
  void initState() {
    super.initState();
    if (widget.data['type'].contains('update')) _initLocation();
    _prepareAnimations();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    animationController.repeat();
    _focusSearch.requestFocus();
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

  _initLocation() {
    var newLocation;
    newLocation = {
      "name": widget.data['data']['address'],
      "address": widget.data['data']['address'],
      "latitude": widget.data['data']['lat'],
      "longitude": widget.data['data']['long'],
      "marker": Marker(
          markerId: MarkerId('${_listSelected.length}'),
          position:
              LatLng(widget.data['data']['lat'], widget.data['data']['long']),
          icon: BitmapDescriptor.defaultMarker,
          onTap: () {
            _showInfo(newLocation, editMarker: true);
          }),
      "circle": Circle(
          circleId: CircleId('${_listSelected.length}'),
          center:
              LatLng(widget.data['data']['lat'], widget.data['data']['long']),
          radius: widget.data['data']['radius'],
          strokeColor: Colors.transparent,
          strokeWidth: 1,
          fillColor: only_color.withOpacity(0.2))
    };
    _listSelected.add(newLocation);
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

  Future updatePlace(Location location, int idMarker) async {
    PlacesSearchResponse response =
        await places.searchNearbyWithRankBy(location, 'distance', type: '');
    _listSelected[idMarker]['name'] = response.results[0].name;
    _listSelected[idMarker]['address'] = response.results[0].vicinity;
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
    PlacesSearchResponse response = await places.searchByText(newValue);
    return response.results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            _buildMap(),
            _buildButton(),
            if (_focusSearch.hasFocus ||
                _showSuggestionList ||
                _showSelectedList)
              _buildOutSideClick(),
            _buildSuggestionList(),
            if (_listPlace != null) _buildSearchList(),
            _iconHand(),
            _buildPlaceSearch(),
          ],
        ));
  }

  Widget _buildMap() => GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            _googleMapController = controller;
          });
        },
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: CameraPosition(
            zoom: _cameraZoom,
            target: widget.data['type'].contains('update')
                ? LatLng(
                    widget.data['data']['lat'], widget.data['data']['long'])
                : Utils.latLngCompany),
        onCameraIdle: () async {
          if (_idMarkerSelected != null) {
            await updatePlace(
                Location(lat: _currentCameraPosition.latitude,
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
            _listSelected.map((value) => (value['marker'] as Marker)).toSet(),
        circles:
            _listSelected.map((value) => (value['circle'] as Circle)).toSet(),
      );

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
        margin: EdgeInsets.only(top: _searchBarHeight + 20, left: 5, right: 5),
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
        margin: EdgeInsets.only(top: _searchBarHeight + 20, left: 5, right: 5),
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
        _positionWorkEdtController.text = '';
        _focusSearch.unfocus();
      },
      child: Container(
          padding: EdgeInsets.only(left: 10),
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
                  place.formattedAddress,
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
        if (_showSuggestionList) {
          setState(() {
            _showSuggestionList = false;
          });
        }
      },
      child: SizedBox.expand(),
    );
  }

  Widget _buildPlaceSearch() {
    return SafeArea(
      child: Container(
        height: _searchBarHeight,
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
                      getListSuggestion(_positionWorkEdtController.text.trim())
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
                        hintText: Utils.getString(context, txt_find),
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
              child: GestureDetector(
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
            )
          ],
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
                                  _listSelected.clear();
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
                                      "marker": Marker(
                                          markerId: MarkerId(id.toString()),
                                          position: LatLng(
                                              location.geometry.location.lat,
                                              location.geometry.location.lng),
                                          icon: BitmapDescriptor.defaultMarker,
                                          onTap: () {
                                            _showInfo(newLocation,
                                                editMarker: true);
                                          }),
                                      "circle": Circle(
                                          circleId: CircleId(
                                              '${_listSelected.length}'),
                                          center: LatLng(
                                              location.geometry.location.lat,
                                              location.geometry.location.lng),
                                          radius: widget.data['data']['radius'],
                                          strokeColor: Colors.transparent,
                                          strokeWidth: 1,
                                          fillColor:
                                              only_color.withOpacity(0.2))
                                    };
                                  } else {
                                    _listSelected.clear();
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
                                          }),
                                      "circle": Circle(
                                          circleId: CircleId(
                                              '${_listSelected.length}'),
                                          center: LatLng(
                                              location.geometry.location.lat,
                                              location.geometry.location.lng),
                                          radius: widget.data['data']['radius'],
                                          strokeColor: Colors.transparent,
                                          strokeWidth: 1,
                                          fillColor:
                                              only_color.withOpacity(0.2))
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

  Widget _buildButton() => Positioned(
        bottom: Utils.resizeWidthUtil(context, 20),
        right: Utils.resizeWidthUtil(context, 20),
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context, _listSelected[0]);
          },
          child: Container(
            padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                color: _listSelected.length > 0
                    ? only_color
                    : txt_grey_color_v1.withOpacity(0.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.check_circle,
                  color: white_color,
                ),
                TKText(
                  Utils.getString(context, txt_done),
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 32),
                      color: white_color),
                )
              ],
            ),
          ),
        ),
      );
}
