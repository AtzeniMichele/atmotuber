import 'package:flutter/cupertino.dart';

/// [AtmotubeData] is a class implementing the data model of the
/// user account data.

@immutable
class AtmotubeData {
  // status data (battery and other additional info in bits)
  final List<dynamic> Status;
  // bme280 data (temperature, humidity, pressure)
  final List<dynamic> BME280;
  // pm data (pm1, pm2.5, pm10)
  final List<dynamic> PM;
  // voc data
  final List<dynamic> VOC;

  /// Default [AtmotubeData] constructor.
  const AtmotubeData(
      {this.Status = const [],
      this.BME280 = const [],
      this.PM = const [],
      this.VOC = const []});

  /// Generates a [AtmotubeData] new object.
  AtmotubeData copyWith({
    List<dynamic>? Status,
    List<dynamic>? BME280,
    List<dynamic>? PM,
    List<dynamic>? VOC,
  }) {
    return AtmotubeData(
      Status: Status ?? this.Status,
      BME280: BME280 ?? this.BME280,
      PM: PM ?? this.PM,
      VOC: VOC ?? this.VOC,
    );
  }

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;

  //   return other is AtmotubeData &&
  //       other.Status == Status &&
  //       other.BME280 == BME280 &&
  //       other.PM == PM &&
  //       other.VOC == VOC;
  // }

  // @override
  // int get hashCode =>
  //     Status.hashCode ^ BME280.hashCode ^ PM.hashCode ^ VOC.hashCode;

} // AtmotubeData
