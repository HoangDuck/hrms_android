/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/components/mqtt.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';

class OwnerView extends StatefulWidget {
  final CameraArgument arguments;

  OwnerView(this.arguments);

  @override
  _OwnerViewState createState() => _OwnerViewState();
}

class _OwnerViewState extends State<OwnerView> {
  List<dynamic> listItem = [];
  Mqtt mQTT = Mqtt();

  @override
  void initState() {
    super.initState();
    mQTT.connect();
    getData();
  }

  void getData() {
    for (int i = 1; i <= 10; i++)
      listItem.add({'id': i, 'name': 'Tủ số $i', 'isOpen': false});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBarCustom(context, () => {}, () => {}, 'Chọn tủ', null),
      body: Container(
        padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 20)),
        height: double.infinity,
        width: double.infinity,
        child: _gridView(),
      ),
    );
  }

  Widget _gridView() {
    return GridView.builder(
        itemCount: listItem.length,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            child: Card(
                elevation: listItem[index]['id'] == 1 || listItem[index]['id'] == 3 ? 5.0 : 0.0,
                color: listItem[index]['id'] == 1 || listItem[index]['id'] == 3 ? Colors.white : txt_grey_color_v1.withOpacity(0.1),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    listItem[index]['id'].toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Utils.resizeWidthUtil(context, 32)),
                  ),
                )),
            onTap: () {
              if(listItem[index]['id'] == 1 || listItem[index]['id'] == 3)
                Navigator.pushNamed(context, Router.timeKeeping,
                    arguments: CameraArgument(
                        mqtt: listItem[index]['id'].toString(),
                        deviceBrand: widget.arguments.deviceBrand));
            },
          );
        });
  }
}
*/
