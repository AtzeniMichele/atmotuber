/// An enumerator defining the possible types of [AtmotubeException].
enum AtmotubeExceptionType {
  /// It occurs when the Atmotube Pro is not near and not found
  notNEAR,

  /// It occurs when the Atmotube Pro is not connected and some actions are triggered
  notCONNECTED,

  /// Default error type.
  isDEFAULT,
} // AtmotubeExceptionType

/// [AtmotubeException] is an abstract class defining an [Exception] that
/// can be thrown by atmotuber.
abstract class AtmotubeException implements Exception {
  /// The [AtmotubeException] method.
  String? message;

  /// The type of the [AtmotubeException].
  AtmotubeExceptionType type;

  /// Default [AtmotubeException] constructor.
  AtmotubeException(
      {this.message = '', this.type = AtmotubeExceptionType.isDEFAULT});

  /// Returns the string representation of this object.
  @override
  String toString();
} // AtmotubeException
