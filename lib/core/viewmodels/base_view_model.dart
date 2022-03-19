import 'package:gsot_timekeeping/core/base/base_model.dart';
import 'package:gsot_timekeeping/core/base/base_service.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:http/http.dart' as http;

class BaseViewModel extends BaseModel with BaseService {
  saveFirstTime() {
    SecureStorage().saveIsFirstTime();
  }

  callApis(dynamic data, String url, String method,
      {bool isNeedAuthenticated = false,
      bool shouldSkipAuth = true,
      bool isLoginSocial = false,
      List<Map<String, dynamic>> params,
      bool isMultiPart = false,
      List<http.MultipartFile> multipartFile,
      bool isShowError = false}) async {
    if (isNeedAuthenticated) {
      var reqTime = DateTime.now().millisecondsSinceEpoch;
      var arraysUrl = url.split("/");
      var _user = await SecureStorage().getCustomString(SecureStorage.USERNAME);
      var tokenData = Utils.encryptHMAC(
          Utils.convertJson(data, arraysUrl[arraysUrl.length - 1], reqTime.toString(), userName: _user ?? 'noname'),
          secCode);
      if (isMultiPart)
        data = {
          ...data,
          ...{"token": tokenData},
          ...{"reqtime": reqTime.toString()}
        };
      else
        data = {"data": data, "token": tokenData, "reqtime": reqTime.toString()};
    }
    if (isLoginSocial) {
      if (params != null && params.length > 0) {
        for (dynamic i in params) {
          url = url.replaceAll(i['key'], i['value']);
        }
      }
    }
    var dataResponse = method == method_post
        ? !isMultiPart
            ? await post(url, data: data, shouldSkipAuth: shouldSkipAuth)
            : postMultiPart(url, data: data, shouldSkipAuth: shouldSkipAuth, multipartFile: multipartFile)
        : await get(url, shouldSkipAuth: shouldSkipAuth);
    return dataResponse;
  }
}
