import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

class DataConversion {
  dynamic getConversion(List<int> byteList, int rangeStart, int rangeStop,
      {bool reversed = true}) {
    dynamic data;
    final List<int> data_range;

    if (reversed) {
      data_range = byteList
          .getRange(rangeStart, rangeStop + 1)
          .toList()
          .reversed
          .toList();
    } else {
      data_range = byteList.getRange(rangeStart, rangeStop + 1).toList();
    }

    int byteLen = data_range.length;
    if (byteLen * 8 == 24) {
      data_range.insert(0, 0);
    }

    var byte_data =
        Uint8List.fromList(data_range.toList()).buffer.asByteData(0);

    switch (byteLen * 8) {
      case 8:
        {
          data = byte_data.getUint8(0);
        }
        break;
      case 16:
        {
          data = byte_data.getUint16(0);
        }
        break;
      case 24:
        {
          data = byte_data.getUint32(0);
        }
        break;
      case 32:
        {
          data = byte_data.getUint32(0);
        }
        break;
      default:
        {
          print('invalid data');
        }
        break;
    }
    return data;
  }

  List<dynamic> getBits(int byte) {
    List binaryInfo =
        byte.toRadixString(2).split('').map((data) => int.parse(data)).toList();
    if (binaryInfo.length < 8) {
      var zeros = List<int>.filled(8 - binaryInfo.length, 0);
      binaryInfo.insertAll(0, zeros);
    }
    return binaryInfo;
  }

  Uint8List int32BigEndianBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

  Uint8List timestampEncoder() {
    int prova = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
    final timestamp = int32BigEndianBytes(prova);
    print(timestamp);
    return timestamp;
  }

  DateTime timestampDecoder(Iterable<int> timebyte) {
    final decoded_time =
        Uint8List.fromList(timebyte.toList()).buffer.asByteData(0).getUint32(0);

    DateTime datetime_time =
        DateTime.fromMillisecondsSinceEpoch(decoded_time * 1000);

    return datetime_time;
  }

  Uint8List commandEncoder(value) {
    final Encoder = utf8.encoder;
    final result = Encoder.convert(value);
    return result;
  }
}
