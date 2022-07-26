import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:atmotuber/src/model.dart';
import 'package:atmotuber/src/device_info.dart';
import 'package:atmotuber/src/uart_info.dart';
import 'package:atmotuber/src/utils.dart';
import 'package:atmotuber/src/errors/AtmotubeException.dart';
import 'package:collection/src/list_extensions.dart';

// TODO: add timestamp for each point of values

class Atmotuber {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice? device;
  bool shouldStop = false;

  final dataType = ['status', 'bme', 'pm', 'voc'];
  var atmotubeData = const AtmotubeData();
  var atmotubeDataHist = const AtmotubeData();

  static BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;

  void _handleBluetoothDeviceState(BluetoothDeviceState deviceState) {
    _deviceState = deviceState;
  }

  String getDeviceState() {
    if (_deviceState == BluetoothDeviceState.connected) {
      return 'connected';
    } else if (_deviceState == BluetoothDeviceState.disconnected) {
      return 'disconnected';
    } else if (_deviceState == BluetoothDeviceState.disconnecting) {
      return 'disconnecting';
    } else if (_deviceState == BluetoothDeviceState.connecting) {
      return 'connecting';
    } else {
      return 'error';
    }
  }

  Future<BluetoothDevice?> searchAtmotube() async {
    await dropConnection();
    _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);
    dynamic scan = await flutterBlue.startScan(timeout: Duration(seconds: 4));

    for (dynamic s in scan) {
      if (s.advertisementData.serviceUuids.isNotEmpty) {
        if (s.advertisementData.serviceUuids.last ==
            DeviceServiceConfig().deviceService) {
          device = s.device;
          if (device == null) {
            throw AtmotubeException(
                message: 'ATMOTUBE is not near to you!',
                type: AtmotubeExceptionType.NOT_NEAR);
          }
        }
      }
    }
    _handleBluetoothDeviceState(BluetoothDeviceState.connecting);
    await device!.connect();
    _handleBluetoothDeviceState(BluetoothDeviceState.connected);
    shouldStop = false;
    return device;
  }

  Future<void> dropConnection() async {
    var connected = await flutterBlue.connectedDevices;
    for (var element in connected) {
      if (element.name == DeviceServiceConfig().deviceName) {
        await element.disconnect();
        _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);
        shouldStop = true;
      }
    }
  }

  Future<BluetoothService> getAtmotubeService() async {
    var services = await device!.discoverServices();
    var service = services.firstWhere((element) =>
        element.uuid.toString() ==
        DeviceServiceConfig().deviceService.toLowerCase());
    return service;
  }

  Future<BluetoothService> getUartAtmotubeService() async {
    var services = await device!.discoverServices();
    var service = services.firstWhere((element) =>
        element.uuid.toString() ==
        HistoryServiceConfig().serviceId.toLowerCase());
    return service;
  }

  Future<List<BluetoothCharacteristic>> getCharacteristics(
      BluetoothService service) async {
    List<BluetoothCharacteristic> characteristics = service.characteristics;
    return characteristics;
  }

  Future<List<dynamic>> getValues(BluetoothCharacteristic c,
      List<int> startRanges, List<int> stopRanges) async {
    List values = [];
    if (startRanges.length == stopRanges.length) {
      final indexes =
          startRanges.mapIndexed((index, element) => index).toList();

      List<int> list = await c.read();

      for (int i in indexes) {
        values.add(DataConversion()
            .getConversion(list, startRanges[i], stopRanges[i]));
      }
    }
    return values;
  }

  Stream<AtmotubeData> getData(
      List<BluetoothCharacteristic> characteristics) async* {
    // int index = DeviceServiceConfig()
    //     .chars
    //     .indexWhere((element) => element == c.uuid.toString());

    // String type = dataType[index];

    var data1;
    var data2;
    var data3;
    var data4;
    var data5;

    for (String type in dataType) {
      switch (type) {
        case 'status':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().statusCharacteristic);
            data1 = await getValues(c, [0], [0]);
            var val = await c.read();
            data2 = DataConversion().getBits(val[1]);
            //atmotubeData = atmotubeData.copyWith(Status: [data1, data2]);
          }
          break;
        case 'bme':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().bmeCharacteristic);
            data3 = await getValues(c, [0, 1, 2], [0, 1, 5]);
            data3[2] = data3[2] / 100; // from mbar * 100 to mbar
            //atmotubeData = atmotubeData.copyWith(BME280: data);
          }
          break;
        case 'pm':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().pmCharacteristic);
            data4 = await getValues(c, [0, 3, 6], [2, 5, 8]);
            data4 = data4.map((e) => e / 100).toList();
            //atmotubeData = atmotubeData.copyWith(PM: data);
          }
          break;
        case 'voc':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().vocCharacteristics);
            data5 = await getValues(c, [0], [1]);
            data5 = data5.map((e) => e / 1000).toList(); // from ppb to ppm
            //atmotubeData = atmotubeData.copyWith(VOC: data);
          }
          break;
        default:
          {
            print('something is wrong');
          }
      }
      atmotubeData = atmotubeData.copyWith(
          Status: [data1, data2], BME280: data3, PM: data4, VOC: data5);
      yield atmotubeData;
    }
  }

  Future<void> wrapper({required Function callback}) async {
    if (_deviceState == BluetoothDeviceState.disconnected) {
      throw AtmotubeException(
          message: 'Please first connect ATMOTUBE Pro',
          type: AtmotubeExceptionType.NOT_CONNECTED);
    }
    BluetoothService service = await getAtmotubeService();
    List<BluetoothCharacteristic> characteristics =
        await getCharacteristics(service);

    // section 1
    BluetoothCharacteristic c = characteristics.firstWhere((element) =>
        element.uuid.toString() == DeviceServiceConfig().pmCharacteristic);

    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!shouldStop) {
        Stream<AtmotubeData> data = getData(characteristics);
        data.listen((event) {
          // print(event.Status);
          // print(event.BME280);
          // print(event.PM);
          // print(event.VOC);
          callback(event);
        });
      } else {
        timer.cancel();
      }
    });
    //}
  }

  Future<void> hist_wrapper({required Function callback}) async {
    if (_deviceState == BluetoothDeviceState.disconnected) {
      throw AtmotubeException(
          message: 'Please first connect ATMOTUBE Pro',
          type: AtmotubeExceptionType.NOT_CONNECTED);
    }
    BluetoothService service = await getUartAtmotubeService();
    List<BluetoothCharacteristic> characteristics =
        await getCharacteristics(service);
    getHist(characteristics);
    Stream<AtmotubeData> hist_data = getAtmotubeHistObject();
    hist_data.listen((event) {
      callback(event);
    });
  }

  Stream<AtmotubeData> getAtmotubeHistObject() async* {
    yield atmotubeDataHist;
  }

  void getHist(List<BluetoothCharacteristic> characteristics) {
    BluetoothCharacteristic rx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().rxCharacteristicId);
    BluetoothCharacteristic tx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().txCharacteristicId);

    Uint8List timestamp = DataConversion().timestampEncoder();
    Uint8List command = DataConversion().commandEncoder('HST');

    final txCommand =
        Uint8List.fromList([command, timestamp].expand((x) => x).toList());

    rx.setNotifyValue(true);
    tx.write(txCommand, withoutResponse: true);

    int previous_packet_number = 0;
    int packet_total = 0;
    int packet_dim = 0;

    var stream = rx.value.asBroadcastStream();

    stream.listen((event) {
      final response = utf8.decoder.convert(event.getRange(0, 2).toList());
      print('The device response is {$response}');

      switch (response) {
        case 'HO':
          {
            print('device received a history request');
          }
          break;
        case 'HT':
          {
            Iterable<int> timebyte = event.getRange(3, 7).toList();
            DateTime packet_time = DataConversion().timestampDecoder(timebyte);

            packet_total = event.elementAt(7);

            int packet_dim = event.elementAt(8);

            print('time of the first history packet: {$packet_time}');
            print('total number of history packets: {$packet_total}');
            print('dimension of history packets: {$packet_dim}');
          }
          break;
        case 'HD':
          {
            int packet_number = event.elementAt(3);
            print('sent history packet number: {$packet_number}');
            //print(event);

            List<int> data = event.getRange(4, event.length).toList();

            int diff = packet_number - previous_packet_number;
            previous_packet_number = packet_number;

            for (int i in Iterable<int>.generate(diff).toList()) {
              List<int> subset = data.getRange(i * 16, (i * 16) + 15).toList();

              print(subset.length);

              int temp = DataConversion().getConversion(subset, 0, 0); // %
              int humidity = DataConversion().getConversion(subset, 1, 1); // %
              double voc = DataConversion().getConversion(subset, 2, 3) /
                  1000; // from ppb to ppm
              double pressure = DataConversion().getConversion(subset, 4, 7) /
                  100; // from mbar * 100 to mbar
              int pm1 =
                  DataConversion().getConversion(subset, 8, 9); // microg / m3
              int pm2 =
                  DataConversion().getConversion(subset, 10, 11); // microg / m3
              int pm10 =
                  DataConversion().getConversion(subset, 12, 13); // microg / m3

              // print('temperature is: {$temp}');
              // print('humidity is: {$humidity}');
              // print('voc is: {$voc}');
              // print('pressure is: {$pressure}');
              // print('pm1 is: {$pm1}');
              // print('pm2 is: {$pm2}');
              // print('pm10 is: {$pm10}');

              atmotubeDataHist = atmotubeDataHist.copyWith(
                  BME280: [temp, humidity, pressure],
                  PM: [pm1, pm2, pm10, 0],
                  VOC: [voc]);
            }

            if (packet_number == packet_total) {
              previous_packet_number = 0;
              Uint8List confirm_timestamp = DataConversion().timestampEncoder();
              Uint8List confirm_command =
                  DataConversion().commandEncoder('HOK');
              final txAcknowledge = Uint8List.fromList([
                confirm_command,
                confirm_timestamp
              ].expand((x) => x).toList());
              print('new packet arriving');
              tx.write(txAcknowledge, withoutResponse: true);
            } else {
              previous_packet_number = packet_number;
            }
          }
          break;
        default:
          {
            print('no command found!');
          }
      }
    });
  }
}
