// class AtmotubeData {
//   static List<dynamic> Status = [];
//   static List<dynamic> BME280 = [];
//   static List<dynamic> PM = [];
//   static dynamic VOC;
// }

import 'package:flutter/cupertino.dart';

@immutable
class AtmotubeData {
  final List<dynamic> Status;
  final List<dynamic> BME280;
  final List<dynamic> PM;
  final List<dynamic> VOC;

  const AtmotubeData(
      {this.Status = const [],
      this.BME280 = const [],
      this.PM = const [],
      this.VOC = const []});

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
}
