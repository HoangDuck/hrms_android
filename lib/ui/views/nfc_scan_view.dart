import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:gsot_timekeeping/core/enums/timekeeping_type.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class NFCScanView extends StatefulWidget {
  @override
  _NFCScanViewState createState() => _NFCScanViewState();
}

class _NFCScanViewState extends State<NFCScanView>
    with TickerProviderStateMixin {
  AnimationController animationController;
  NFCTag _tag;
  bool scanning = true;

  @override
  void initState() {
    super.initState();
    nfcScan();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    animationController.repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  nfcScan() async {
    try {
      _tag = await FlutterNfcKit.poll();
      Navigator.pushReplacementNamed(context, Routers.checkLocation,
          arguments: CameraArgument(
              deviceBrand: _tag.id, timekeepingType: TimekeepingType.NFC));
    } catch (e) {
      setState(() {
        scanning = false;
      });
      showMessageDialogIOS(context,
          description: 'Thiết bị không hỗ trợ NFC hoặc NFC chưa được bật. Hãy kiểm tra và thử lại!', onPress: () {
            Navigator.pop(context);
            Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: txt_grey_color_v1,
      appBar: appBarCustom(context, () => Navigator.pop(context), null,
          Utils.getString(context, txt_nfc_timekeeping), null,
          hideBackground: false),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: scanning ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: animationController,
                child: Image.asset(
                  ic_nfc,
                  color: white_color,
                  height: Utils.resizeWidthUtil(context, 250),
                  width: Utils.resizeWidthUtil(context, 250),
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
                height: Utils.resizeHeightUtil(context, 50),
              ),
              TKText(
                Utils.getString(context, txt_scanning),
                tkFont: TKFont.SFProDisplaySemiBold,
                style: TextStyle(
                    color: white_color,
                    fontSize: Utils.resizeWidthUtil(context, 36)),
              )
            ],
          ) : Container(),
        ),
      ),
    );
  }
}
