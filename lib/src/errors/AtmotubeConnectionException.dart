import 'package:atmotuber/src/errors/AtmotubeException.dart';

/// [AtmotubeConnectionException] is a class that implements the
/// [AtmotubeExceptionType.NOT_CONNECTED] exception.
class AtmotubeConnectionException extends AtmotubeException {
  /// Default [AtmotubeConnectionException] constructor.
  AtmotubeConnectionException({
    AtmotubeExceptionType? type,
    String? message,
  }) : super(type: AtmotubeExceptionType.NOT_CONNECTED, message: message);

  @override
  String toString() {
    return 'AtmotubeException [$type]: $message';
  } // toString
} // AtmotubeConnectionException