import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/views/show_image_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/marquee.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:signature/signature.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachFileView extends StatefulWidget {
  final dynamic data;

  AttachFileView(this.data);

  @override
  _AttachFileViewState createState() => _AttachFileViewState();
}

class _AttachFileViewState extends State<AttachFileView> {
  List<File> _listFile = [];
  List<String> _listFileInit = [];
  TextEditingController _noteController = TextEditingController();
  List<bool> _listRate = [false, false, false, false, false];
  int ratePoint;
  bool enableSignature = false;
  bool enableButton = false;
  String signatureUrl = '';
  dynamic genRow = {};
  dynamic data = {};
  bool initComplete = false;
  final SpeechToText speech = SpeechToText();
  double minSoundLevel = 50000;
  double level = 0.0;
  double maxSoundLevel = -50000;
  String lastError = "";
  String lastWords = "";
  String lastStatus = "";
  bool isOpenModal = false;
  List<String> listExtensions = [];

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: only_color,
    exportBackgroundColor: white_color,
  );

  @override
  void initState() {
    super.initState();
  }

  getGenRow(BaseViewModel model) async {
    var response = await model.callApis({
      "TbName": "vw_tb_hrms_congtacngoai_outside_calendar_place",
    }, getGenRowDefineUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        genRow = Utils.getListGenRow(response.data['data'], 'add');
      });
    else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  loadData(BaseViewModel model) async {
    var response = await model.callApis({
      "col_select": '*',
      "tablename": "vw_tb_hrms_congtacngoai_outside_calendar_place",
      "condition": "ID = ${widget.data['child_id']}"
    }, getDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      setState(() {
        data = response.data['data'][0];
        _noteController.text = response.data['data'][0]['location_notes']['v'];
        ratePoint = response.data['data'][0]['location_star_id']['v'] != ''
            ? num.parse(response.data['data'][0]['location_star_id']['v'])
            : 0;
        if (response.data['data'][0]['location_file_upload']['v'] != '')
          _listFileInit =
              response.data['data'][0]['location_file_upload']['v'].split(';');
        signatureUrl = response.data['data'][0]['location_signature']['v'];
        for (int i = 0; i < ratePoint; i++) _listRate[i] = true;
        initComplete = true;
      });
    }
  }

  getExtensions(BaseViewModel model) async {
    var response = await model.callApis({
      'col_select': 'colValueTxt',
      'tablename': 'tbSystemInfo',
      'condition': 'colName = \'FileTypeAllow\''
    }, getDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if(response.status.code == 200) {
      listExtensions = response.data['data'][0]['colValueTxt']['v'].toString().split(';');
    }
  }

  Future getImage(ImageSource imageSource) async {
    var imagePicker =
        await ImagePicker().getImage(source: imageSource, imageQuality: 10);
    File image = File(imagePicker.path);
    setState(() {
      _listFile.add(image);
    });
  }

  Future getFile() async {
    FilePickerResult file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: listExtensions,
    );
    List<File> _listFile = file.paths.map((path) => File(path)).toList();
    setState(() {
      if (file != null) {
        _listFile.addAll(_listFile);
      } else {
        print('error');
      }
    });
  }

  openFile(File file) async {
    await OpenFile.open(file.path);
  }

  saveData(BaseViewModel model) async {
    showLoadingDialog(context);
    var encryptData =
        await Utils.encrypt("vw_tb_hrms_congtacngoai_outside_calendar_place");
    Uint8List imageSignByte = await _controller.toPngBytes();
    final imageBase64 = Utils.convertBase64(imageSignByte);
    List<http.MultipartFile> multipartFile = [];
    for (int i = 0; i < _listFile.length; i++) {
      var stream =
          http.ByteStream(DelegatingStream.typed(_listFile[i].openRead()));
      var length = await _listFile[i].length();
      var _multipartFile = http.MultipartFile(
          'location_file_upload', stream, length,
          filename: path.basename(_listFile[i].path));
      multipartFile.add(_multipartFile);
    }
    var response = await BaseViewModel().callApis({
      "tbname": encryptData,
      "dataid": widget.data['child_id'],
      "location_star_id": ratePoint.toString(),
      "location_notes": _noteController.text,
      "location_signature": "data:image/jpeg;base64,$imageBase64"
    }, saveDataUrl, method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true,
        multipartFile: multipartFile,
        isMultiPart: true);
    Navigator.pop(context);
    if (response.status.code == 200) {
      Future.delayed(Duration(seconds: 1), () {
        reloadFileAttach(model);
      });
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context, _listFile.length);
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
  }

  reloadFileAttach(BaseViewModel model) async {
    await model.callApis(
        {'ID': widget.data['parent_id']}, reloadFileAttachUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      var systemLocale = await speech.systemLocale();
      debugPrint(systemLocale.localeId);
    }

    if (!mounted) return;
  }

  void statusListener(String status) {
    print(
        "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }

  void startListening() {
    _noteController.text = '';
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 5),
        localeId: "vi_VN",
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
    showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            border: Border.all(style: BorderStyle.none),
          ),
          child: StatefulBuilder(builder: (context, setModalState) {
            return modalBottomSheetVoice(context, setModalState);
          })),
    );
  }

  void stopListening() {
    setState(() {
      speech.stop();
      level = 0.0;
    });
  }

  void cancelListening() {
    setState(() {
      speech.cancel();
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    debugPrint(result.recognizedWords);
    setState(() {
      if (isOpenModal) {
        _noteController.text = result.recognizedWords;
      }
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getGenRow(model);
        loadData(model);
        getExtensions(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(
            context, () => Navigator.pop(context), () => {}, '', null,
            titleCustom: MarqueeWidget(
              direction: Axis.horizontal,
              child: TKText(widget.data['address'],
                  tkFont: TKFont.SFProDisplayMedium,
                  style: appBarTextStyle(
                      Utils.resizeWidthUtil(context, app_bar_font_size))),
            )),
        body: initComplete
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildChooseFile(),
                    _buildContent(model),
                  ],
                ),
              )
            : Container(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }

  Widget _buildChooseFile() => Container(
        margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
        height: Utils.resizeHeightUtil(context, 250),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: Utils.resizeWidthUtil(context, 30),
              ),
              if (_listFileInit.length == 0)
                ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _listFile.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      String fileType = _listFile[index].path.split('.').last;
                      return GestureDetector(
                        onTap: () {
                          if (fileType == 'jpg' ||
                              fileType == 'png' ||
                              fileType == 'tiff' ||
                              fileType == 'gif')
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowImageView(
                                  image: _listFile[index],
                                  type: 'file',
                                ),
                              ),
                            );
                          else
                            openFile(_listFile[index]);
                        },
                        child: Row(
                          children: <Widget>[
                            Stack(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: fileType == 'jpg' ||
                                          fileType == 'png' ||
                                          fileType == 'tiff' ||
                                          fileType == 'gif'
                                      ? Image.file(
                                          _listFile[index],
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(ic_file, color: only_color,),
                                ),
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _listFile.removeAt(index);
                                      });
                                    },
                                    child: Icon(
                                      Icons.cancel,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              width: Utils.resizeWidthUtil(context, 20),
                            ),
                          ],
                        ),
                      );
                    }),
              if (_listFileInit.length > 0)
                ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _listFileInit.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          if (_listFileInit[index].split('.').last == 'pdf') {
                            await launch(
                              '$avatarUrlAPIs${_listFileInit[index]}',
                            );
                          } else
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowImageView(
                                  image:
                                      '$avatarUrlAPIs${_listFileInit[index]}',
                                ),
                              ),
                            );
                        },
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: _listFileInit[index].split('.').last ==
                                      'pdf'
                                  ? Image.asset(ic_pdf)
                                  : Image.network(
                                      '$avatarUrlAPIs${_listFileInit[index]}'),
                            ),
                            SizedBox(
                              width: Utils.resizeWidthUtil(context, 20),
                            ),
                          ],
                        ),
                      );
                    }),
              if (_listFileInit.length == 0)
                GestureDetector(
                  onTap: () {
                    if(widget.data['permission'] == 0)
                    showCupertinoModalPopup(
                        context: context,
                        builder: (context) => _cupertinoActionSheet());
                  },
                  child: Container(
                    width: Utils.resizeWidthUtil(context, 200),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        border: Border.all(
                            color: txt_grey_color_v1.withOpacity(0.3))),
                    child: Center(
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: txt_grey_color_v1.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 30),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(BaseViewModel model) => Container(
        margin: EdgeInsets.only(
            left: Utils.resizeWidthUtil(context, 30),
            right: Utils.resizeWidthUtil(context, 30)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: Utils.resizeHeightUtil(context, 20)),
            boxTitle(context,
                genRow.length > 0 ? genRow['location_notes']['name'] : ''),
            _buildNote(),
            SizedBox(height: Utils.resizeHeightUtil(context, 20)),
            TKText(
              '${genRow.length > 0 ? genRow['location_star_id']['name'] : ''}',
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 32),
                  color: txt_grey_color_v3),
            ),
            Container(
              height: Utils.resizeHeightUtil(context, 100),
              width: double.infinity,
              child: Center(
                child: _buildRate(),
              ),
            ),
            boxTitle(context,
                genRow.length > 0 ? genRow['location_signature']['name'] : ''),
            signatureUrl == ''
                ? Stack(
                    children: <Widget>[
                      Signature(
                        controller: _controller,
                        width: MediaQuery.of(context).size.width -
                            (Utils.resizeWidthUtil(context, 30) * 2),
                        height: Utils.resizeHeightUtil(context, 300),
                        backgroundColor: white_color,
                      ),
                      enableSignature
                          ? Container()
                          : Container(
                              width: double.infinity,
                              height: Utils.resizeHeightUtil(context, 300),
                              decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8.0),
                                      topLeft: Radius.circular(8.0)),
                                  border: Border.all(
                                      color:
                                          txt_grey_color_v1.withOpacity(0.3))))
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network('$avatarUrlAPIs$signatureUrl'),
                        ),
                      ),
                    ],
                  ),
            if (signatureUrl == '')
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: txt_grey_color_v1.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0)),
                    border:
                        Border.all(color: txt_grey_color_v1.withOpacity(0.3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    IconButton(
                      icon: enableSignature
                          ? Icon(Icons.check)
                          : Icon(Icons.edit),
                      color: enableSignature ? txt_success_color : only_color,
                      onPressed: () {
                        setState(() {
                          enableSignature = !enableSignature;
                          if (enableSignature)
                            enableButton = false;
                          else
                            enableButton = true;
                        });
                      },
                    ),
                    //CLEAR CANVAS
                    IconButton(
                      icon: Icon(Icons.clear),
                      color: txt_fail_color,
                      onPressed: () {
                        setState(() => _controller.clear());
                      },
                    ),
                  ],
                ),
              ),
            SizedBox(height: Utils.resizeHeightUtil(context, 40)),
            if (signatureUrl == '' && widget.data['permission'] == 0)
              TKButton(Utils.getString(context, txt_save),
                  enable: enableButton,
                  width: double.infinity,
                  onPress: () => saveData(model)),
            SizedBox(height: Utils.resizeHeightUtil(context, 40)),
          ],
        ),
      );

  Widget _cupertinoActionSheet() {
    return CupertinoActionSheet(
      title: TKText(
        'Chọn tệp',
        textAlign: TextAlign.center,
        tkFont: TKFont.SFProDisplaySemiBold,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 32), color: blue_light),
      ),
      message: TKText(
        Utils.getString(context, txt_choose_any_action),
        textAlign: TextAlign.center,
        tkFont: TKFont.SFProDisplayMedium,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 24), color: blue_light),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: TKText(Utils.getString(context, txt_choose_image_camera),
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  color: blue_light)),
          isDefaultAction: true,
          onPressed: () {
            Utils.closeKeyboard(context);
            Navigator.pop(context);
            getImage(ImageSource.camera);
          },
        ),
        CupertinoActionSheetAction(
          child: TKText('Thư viện',
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  color: txt_fail_color)),
          isDestructiveAction: true,
          onPressed: () {
            Utils.closeKeyboard(context);
            Navigator.pop(context);
            getFile();
            //getImage(ImageSource.gallery);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: TKText(Utils.getString(context, txt_cancel),
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 30),
                color: blue_light)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildNote() {
    return TextFieldCustom(
        onSpeechPress: () {
          isOpenModal = true;
          startListening();
          Future.delayed(Duration(seconds: 5), () {
            isOpenModal = false;
            Navigator.pop(context);
          });
        },
        controller: _noteController,
        hintText: 'Ghi chú',
        expandMultiLine: true);
  }

  Widget _buildRate() => ListView.builder(
      itemCount: _listRate.length,
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (index == 0 && _listRate[index] && !_listRate[index + 1])
                _listRate[index] = false;
              else
                for (int i = 0; i < _listRate.length; i++)
                  if (i <= index)
                    _listRate[i] = true;
                  else
                    _listRate[i] = false;
              ratePoint = _listRate.where((item) => item).toList().length;
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 30)),
              child: _listRate[index]
                  ? Icon(
                      Icons.star,
                      size: 40,
                      color: only_color,
                    )
                  : Icon(
                      Icons.star_border,
                      size: 40,
                      color: txt_grey_color_v1,
                    ),
            ));
      });
}
