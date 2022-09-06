import 'package:flutter/cupertino.dart';

/// [AtmotubeData] is a class implementing the data model of the
/// user account data.

@immutable
class AtmotubeData {
  // datetime of measurement
  final DateTime? datetime;
  // status data (battery and other additional info in bits)
  final List<dynamic> status;
  // bme280 data (temperature, humidity, pressure)
  final List<dynamic> bme280;
  // pm data (pm1, pm2.5, pm10)
  final List<dynamic> pm;
  // voc data
  final List<dynamic> voc;

  /// Default [AtmotubeData] constructor.
  const AtmotubeData(
      {this.datetime,
      this.status = const [],
      this.bme280 = const [],
      this.pm = const [],
      this.voc = const []});

  /// Generates a [AtmotubeData] new object.
  AtmotubeData copyWith({
    DateTime? datetime,
    List<dynamic>? status,
    List<dynamic>? bme280,
    List<dynamic>? pm,
    List<dynamic>? voc,
  }) {
    return AtmotubeData(
      datetime: datetime ?? this.datetime,
      status: status ?? this.status,
      bme280: bme280 ?? this.bme280,
      pm: pm ?? this.pm,
      voc: voc ?? this.voc,
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
