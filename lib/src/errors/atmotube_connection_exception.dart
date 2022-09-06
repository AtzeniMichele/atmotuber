import 'package:atmotuber/src/errors/atmotube_exception.dart';

/// [AtmotubeConnectionException] is a class that implements the
/// [AtmotubeExceptionType.notCONNECTED] exception.
class AtmotubeConnectionException extends AtmotubeException {
  /// Default [AtmotubeConnectionException] constructor.
  AtmotubeConnectionException({
    AtmotubeExceptionType? type,
    String? message,
  }) : super(type: AtmotubeExceptionType.notCONNECTED, message: message);

  @override
  String toString() {
    return 'AtmotubeException [$type]: $message';
  } // toString
} // AtmotubeConnectionException
