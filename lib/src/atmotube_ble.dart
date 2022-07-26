import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:atmotuber/src/model.dart';
import 'package:atmotuber/src/device_info.dart';
import 'package:atmotuber/src/uart_info.dart';
import 'package:atmotuber/src/utils.dart';
import 'package:atmotuber/src/errors/AtmotubeConnectionException.dart';
import 'package:atmotuber/src/errors/AtmotubeNotNearException.dart';

/// [Atmotuber] is a class that wraps all the methods that can be used for interacting with an ATMOTUBE  Pro device

class Atmotuber {
  // init
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice? device;
  bool shouldStop = false;
  final dataType = ['status', 'bme', 'pm', 'voc'];
  var atmotubeData = const AtmotubeData();
  var atmotubeDataHist = const AtmotubeData();
  static BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;

  /// [_handleBluetoothDeviceState] a private method that set device connection state
  void _handleBluetoothDeviceState(BluetoothDeviceState deviceState) {
    _deviceState = deviceState;
  } // _handleBluetoothDeviceState

  /// [getDeviceState] a  method that handles device connection state
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
  } // getDeviceState

  /// [searchAtmotube] a method that handles device connection action
  Future<BluetoothDevice?> searchAtmotube() async {
    // before all, disconnect any atmotube connected
    await dropConnection();
    _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);

    // scan for atmotube
    dynamic scan = await flutterBlue.startScan(timeout: Duration(seconds: 4));

    for (dynamic s in scan) {
      // looking for non null devices
      if (s.advertisementData.serviceUuids.isNotEmpty) {
        // looking for atmotube Pro
        if (s.advertisementData.serviceUuids.last ==
            DeviceServiceConfig().deviceService) {
          device = s.device;
        }
      }
    }
    if (device == null) {
      throw AtmotubeNotNearException(message: 'ATMOTUBE is not near to you!');
    }
    _handleBluetoothDeviceState(BluetoothDeviceState.connecting);
    // atmotube connection
    await device!.connect();
    _handleBluetoothDeviceState(BluetoothDeviceState.connected);
    // setup for later timer.periodic call
    shouldStop = false;
    return device;
  } // searchAtmotube

  /// [dropConnection] a method that handles device disconnection action
  Future<void> dropConnection() async {
    var connected = await flutterBlue.connectedDevices;
    for (var element in connected) {
      if (element.name == DeviceServiceConfig().deviceName) {
        await element.disconnect();
        _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);
        shouldStop = true;
      }
    }
  } // dropConnection

  /// [getAtmotubeService] a method that handles device ble services
  Future<BluetoothService> getAtmotubeService() async {
    var services = await device!.discoverServices();
    var service = services.firstWhere((element) =>
        element.uuid.toString() ==
        DeviceServiceConfig().deviceService.toLowerCase());
    return service;
  } // getAtmotubeService

  /// [getUartAtmotubeService] a method that handles device ble UART services
  Future<BluetoothService> getUartAtmotubeService() async {
    var services = await device!.discoverServices();
    var service = services.firstWhere((element) =>
        element.uuid.toString() ==
        HistoryServiceConfig().serviceId.toLowerCase());
    return service;
  } // getUartAtmotubeService

  /// [getCharacteristics] a method that handles device ble characterstics
  Future<List<BluetoothCharacteristic>> getCharacteristics(
      BluetoothService service) async {
    List<BluetoothCharacteristic> characteristics = service.characteristics;
    return characteristics;
  } // getCharacterstics

  /// [getValues] a wrapper method that handles device real-time data conversions for specified ranges of the byte list
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
  } // getValues

  /// [getData] A Stream method that handles device real-time data from different type of ble characterstics and write into an AtmotubeData object
  Stream<AtmotubeData> getData(
      List<BluetoothCharacteristic> characteristics) async* {
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
            // status data (battery)
            data1 = await getValues(c, [0], [0]);
            var val = await c.read();
            // status data (status bits)
            data2 = DataConversion().getBits(val[1]);
          }
          break;
        case 'bme':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().bmeCharacteristic);
            // bme data (temperature, humidity, pressure)
            data3 = await getValues(c, [0, 1, 2], [0, 1, 5]);
            // pressure data from mbar * 100 to mbar
            data3[2] = data3[2] / 100;
          }
          break;
        case 'pm':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().pmCharacteristic);
            // pm data (pm1, pm2.5, pm10)
            data4 = await getValues(c, [0, 3, 6], [2, 5, 8]);
            data4 = data4.map((e) => e / 100).toList();
          }
          break;
        case 'voc':
          {
            BluetoothCharacteristic c = characteristics.firstWhere((element) =>
                element.uuid.toString() ==
                DeviceServiceConfig().vocCharacteristics);
            // voc data
            data5 = await getValues(c, [0], [1]);
            data5 = data5.map((e) => e / 1000).toList(); // from ppb to ppm
          }
          break;
        default:
          {
            print('something is wrong');
          }
      }
      // update values of a streammable atmotubeData object
      atmotubeData = atmotubeData.copyWith(
          Status: [data1, data2], BME280: data3, PM: data4, VOC: data5);
      yield atmotubeData;
    }
  } // getData

  /// [wrapper] A wrapper method that handles device real-time data collection
  Future<void> wrapper({required Function callback}) async {
    // check if an atmotube is already connected and ready for the data collection
    if (_deviceState == BluetoothDeviceState.disconnected) {
      throw AtmotubeConnectionException(
          message: 'Please first connect ATMOTUBE Pro');
    }
    BluetoothService service = await getAtmotubeService();
    List<BluetoothCharacteristic> characteristics =
        await getCharacteristics(service);

    // recursively update atmotubeData object and listen to its changes (N.B: it needs Atmotube in continous mode for more precise data collection).
    // TODO: better solution
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
        // when atmotube is disconnected, no more data collection. Close the periodic function call
        timer.cancel();
      }
    });
  } // wrapper

  /// [hist_wrapper] A wrapper method that handles device history data collection
  Future<void> hist_wrapper({required Function callback}) async {
    // TODO: add timestamp for each point of values

    // check if an atmotube is already connected and ready for the data collection
    if (_deviceState == BluetoothDeviceState.disconnected) {
      throw AtmotubeConnectionException(
          message: 'Please first connect ATMOTUBE Pro');
    }
    BluetoothService service = await getUartAtmotubeService();
    List<BluetoothCharacteristic> characteristics =
        await getCharacteristics(service);

    // get history of atmotube not already synced
    getHist(characteristics);
    // stream object creation
    Stream<AtmotubeData> hist_data = getAtmotubeHistObject();
    //listener
    hist_data.listen((event) {
      callback(event);
    });
  } // hist_wrapper

  /// [getAtmotubeHistObject] A method that creates a Stream from an AtmotubeData object
  Stream<AtmotubeData> getAtmotubeHistObject() async* {
    yield atmotubeDataHist;
  } // getAtmotubeHistObject

  /// [getHist] A method that handles device history data via UART communication (sending commands via tx channel and listening via rx channel)
  void getHist(List<BluetoothCharacteristic> characteristics) {
    BluetoothCharacteristic rx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().rxCharacteristicId);
    BluetoothCharacteristic tx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().txCharacteristicId);

    // history request command definition
    Uint8List timestamp = DataConversion().timestampEncoder();
    Uint8List command = DataConversion().commandEncoder('HST');
    final txCommand =
        Uint8List.fromList([command, timestamp].expand((x) => x).toList());

    rx.setNotifyValue(true);
    // history request
    tx.write(txCommand, withoutResponse: true);

    //init
    int previous_packet_number = 0;
    int packet_total = 0;
    int packet_dim = 0;

    //listener
    rx.value.listen((event) {
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

            //timestamp of the starting HD packet
            DateTime packet_time = DataConversion().timestampDecoder(timebyte);

            // number of HD packets
            packet_total = event.elementAt(7);

            // dimension of HD packets
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

            // extract only the data
            List<int> data = event.getRange(4, event.length).toList();

            // number of packets sent computed as the difference between the previous and actual number packet
            int diff = packet_number - previous_packet_number;
            previous_packet_number = packet_number;

            for (int i in Iterable<int>.generate(diff).toList()) {
              // get a specific packet of length specified in HT response (so far, ever 16)
              List<int> subset =
                  data.getRange(i * packet_dim, (i * packet_dim) + 15).toList();

              //print(subset.length);

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

              // update an AtmotubeData object with history values
              atmotubeDataHist = atmotubeDataHist.copyWith(
                  BME280: [temp, humidity, pressure],
                  PM: [pm1, pm2, pm10, 0],
                  VOC: [voc]);
            }

            // send the HOK command for keeping up device sending history packets
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
              // update for loop in HD case
              previous_packet_number = packet_number;
            }
          }
          break;
        default:
          {
            print('no command found!');
          }
      } // switch
    }); // listen
  } // getHist
} // Atmotuber
