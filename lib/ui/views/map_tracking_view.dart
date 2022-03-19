import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';

class MapTrackingView extends StatefulWidget {
  final data;

  MapTrackingView(this.data);

  @override
  _State createState() => _State();
}

class _State extends State<MapTrackingView> {
  Set<Marker> _marker = Set<Marker>();
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _marker.add(
      Marker(
          markerId: MarkerId('${widget.data['location'].latitude}${widget.data['location'].longitude}'),
          position: widget.data['location'],
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: widget.data['title'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(context, () => Navigator.pop(context), () => {}, 'Bản đồ', null),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                  scrollGesturesEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  myLocationButtonEnabled: false,
                  initialCameraPosition: CameraPosition(zoom: 16, target: widget.data['location']),
                  mapType: _mapType,
                  markers: _marker),
            ),
            Positioned(
                right: Utils.resizeWidthUtil(context, 30),
                top: Utils.resizeWidthUtil(context, 30),
                child: _iconMapType())
          ],
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
}
