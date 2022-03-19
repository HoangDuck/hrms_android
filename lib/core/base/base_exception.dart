class BaseException implements Exception {
  final _message;
  final _prefix;

  BaseException([this._message, this._prefix]);

  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends BaseException {
  FetchDataException([String message])
      : super(message, "Error During Communication: ");
}

class BadRequestException extends BaseException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends BaseException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends BaseException {
  InvalidInputException([String message]) : super(message, "Invalid Input: ");
}
