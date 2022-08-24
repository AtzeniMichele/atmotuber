import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

/// [DataConversion] is a class implementing the data byte conversion of the
/// atmotube data.
class DataConversion {
  /// [getConversion] convert a certain range of byte from a wider list of byte data coming from atmotube.
  dynamic getConversion(List<int> byteList, int rangeStart, int rangeStop,
      {bool reversed = true}) {
    dynamic data;
    final List<int> dataRange;

    // some byte lists need to be reversed
    if (reversed) {
      dataRange = byteList
          .getRange(rangeStart, rangeStop + 1)
          .toList()
          .reversed
          .toList();
    } else {
      dataRange = byteList.getRange(rangeStart, rangeStop + 1).toList();
    }

    int byteLen = dataRange.length;
    if (byteLen * 8 == 24) {
      dataRange.insert(0, 0);
    }

    var byteData = Uint8List.fromList(dataRange.toList()).buffer.asByteData(0);

    // conversion based on byte length
    switch (byteLen * 8) {
      case 8:
        {
          data = byteData.getUint8(0);
        }
        break;
      case 16:
        {
          data = byteData.getUint16(0);
        }
        break;
      case 24:
        {
          data = byteData.getUint32(0);
        }
        break;
      case 32:
        {
          data = byteData.getUint32(0);
        }
        break;
      default:
        {
          //print('invalid data');
        }
        break;
    } // switch
    return data;
  } // getConversion

  /// [getBits] extracts a certain range of bits from a a byte data coming from atmotube (used for Status data).
  List<dynamic> getBits(int byte) {
    List binaryInfo =
        byte.toRadixString(2).split('').map((data) => int.parse(data)).toList();
    if (binaryInfo.length < 8) {
      var zeros = List<int>.filled(8 - binaryInfo.length, 0);
      binaryInfo.insertAll(0, zeros);
    }
    return binaryInfo;
  } // getBits

  Uint8List int32BigEndianBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

  /// [timestampEncoder] encode in a list of bytes a timestamp.
  Uint8List timestampEncoder() {
    int prova = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timestamp = int32BigEndianBytes(prova);
    //print(timestamp);
    return timestamp;
  } // timestampEncoder

  /// [timestampDecoder] decode a list of bytes in a timestamp.
  DateTime timestampDecoder(Iterable<int> timebyte) {
    final decodedTime =
        Uint8List.fromList(timebyte.toList()).buffer.asByteData(0).getUint32(0);

    DateTime datetimeTime =
        DateTime.fromMillisecondsSinceEpoch(decodedTime * 1000);

    return datetimeTime;
  }

  /// [commandEncoder] encode in a list of bytes a history command made of a string and a timestamp.
  Uint8List commandEncoder(value) {
    final encoder = utf8.encoder;
    final result = encoder.convert(value);
    return result;
  }
}
