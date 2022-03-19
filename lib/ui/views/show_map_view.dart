import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/widgets/title_content_widget.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class ShowMapView extends StatefulWidget {
  final CameraArgument arguments;

  const ShowMapView(this.arguments);

  @override
  _ShowMapViewState createState() => _ShowMapViewState();
}

class _ShowMapViewState extends State<ShowMapView> {
  double _cameraZoom = 16;

  Set<Marker> _marker = Set<Marker>();

  Set<Circle> _circle = Set<Circle>();

  Position _currentLocation;

  double _distance;

  dynamic _place;

  GoogleMapController _controller;

  bool isReload = false;

  @override
  void initState() {
    super.initState();
    initLocation();
    _currentLocation = widget.arguments.currentLocation;
    _distance = widget.arguments.distance;
    _place = widget.arguments.place;
    _marker = widget.arguments.marker;
    _circle = widget.arguments.circle;
  }

  getZoomLevel(double radius) {
    double scale = radius / 500;
    return (16 - math.log(scale) / math.log(2));
  }

  LatLng computeCentroid(List<LatLng> points) {
    double latitude = 0;
    double longitude = 0;
    int n = points.length;

    for (LatLng point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }
    return new LatLng(latitude / n, longitude / n);
  }

  initLocation() {
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    )
        .then((position) async {
      _refreshLocation(position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  _refreshLocation(Position position) {
    if (position != null && mounted) {
      double distance = Utils.getDistance(
          position.latitude, position.longitude, double.parse(_place['lat']), double.parse(_place['lng']));
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _currentLocation = position;
          _distance = distance.roundToDouble();
          isReload = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            color: Colors.white,
            height: double.infinity,
            width: double.infinity,
            child: Container(
              child: GoogleMap(
                  onMapCreated: (controller) {
                    _controller = controller;
                    _cameraZoom = getZoomLevel(_distance);
                    LatLng latLngStart = LatLng(_currentLocation.latitude, _currentLocation.longitude);
                    LatLng latLngEnd = LatLng(double.parse(_place['lat']), double.parse(_place['lng']));
                    List<LatLng> listLatLng = [latLngStart, latLngEnd];
                    _controller.animateCamera(CameraUpdate.newLatLngZoom(computeCentroid(listLatLng), _cameraZoom));
                    debugPrint(_cameraZoom.toString());
                  },
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                      zoom: _cameraZoom, target: LatLng(_currentLocation.latitude, _currentLocation.longitude)),
                  mapType: MapType.normal,
                  circles: _circle,
                  markers: _marker),
            ),
          ),
          _buildCloseButton(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
        top: Utils.resizeHeightUtil(context, 60),
        left: Utils.resizeWidthUtil(context, 30),
        child: GestureDetector(
          onTap: () => Navigator.pop(context, CameraArgument(distance: _distance, currentLocation: _currentLocation)),
          child: Container(
            padding: EdgeInsets.all(10),
            height: Utils.resizeHeightUtil(context, 74),
            width: Utils.resizeWidthUtil(context, 74),
            decoration: BoxDecoration(
              color: white_color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: txt_grey_color_v1.withOpacity(0.3), blurRadius: 10.0, spreadRadius: 2.0)],
            ),
            child: Image.asset(ic_cancel),
          ),
        ));
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      child: Container(
        padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Utils.resizeWidthUtil(context, 40)),
              topRight: Radius.circular(Utils.resizeWidthUtil(context, 40))),
          boxShadow: [
            BoxShadow(
              color: txt_grey_color_v1.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(right: Utils.resizeWidthUtil(context, 30)),
                  height: Utils.resizeHeightUtil(context, 70),
                  width: Utils.resizeWidthUtil(context, 70),
                  decoration: BoxDecoration(
                    color: blue_light.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(ic_marker),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TKText(
                        _place['name'],
                        tkFont: TKFont.SFProDisplaySemiBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 32), color: txt_grey_color_v2),
                      ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                      titleContentWidget(
                          context, txt_coordinate, '${_currentLocation.latitude}, ${_currentLocation.longitude}',
                          color: bg_text_field,
                          width: Utils.resizeWidthUtil(context, 570),
                          padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30))),
                      SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                      titleContentWidget(context, txt_distance, '${_distance}m',
                          color: bg_text_field,
                          textColor: _distance > 500 ? txt_fail_color : txt_grey_color_v2,
                          width: Utils.resizeWidthUtil(context, 570),
                          padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30))),
                      SizedBox(height: Utils.resizeHeightUtil(context, 32)),
                    ],
                  ),
                )
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              child: TKButton(
                isReload ? 'Đang tải...' : Utils.getString(context, txt_reload_location),
                enable: !isReload,
                onPress: () {
                  setState(() {
                    isReload = true;
                  });
                  Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.best,
                    forceAndroidLocationManager: false
                    ).then((position) async {
                      _refreshLocation(position);
                      _controller.moveCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
                    }).catchError((e) {
                      print(e);
                    });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
