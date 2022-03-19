
import 'package:gsot_timekeeping/core/enums/view_state.dart';

class ApiResponse<T> {
  ViewState status;

  T dataApiResponse;

  String message;

  ApiResponse.loading(this.message) : status = ViewState.LOADING;

  ApiResponse.completed(this.dataApiResponse, {this.message = ""})
      : status = ViewState.COMPLETE;

  ApiResponse.error(this.message) : status = ViewState.ERROR;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $dataApiResponse";
  }
}


