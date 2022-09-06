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
import 'package:atmotuber/src/errors/atmotube_connection_exception.dart';
import 'package:atmotuber/src/errors/atmotube_not_near_exception.dart';

/// [Atmotuber] is a class that wraps all the methods that can be used for interacting with an ATMOTUBE  Pro device

class Atmotuber {
  // init
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
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
    // await dropConnection();
    // _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);

    // check if an atmotube is already connected:
    var connected = await flutterBlue.connectedDevices;
    for (var element in connected) {
      if (element.name == DeviceServiceConfig().deviceName) {
        device = element;
        _handleBluetoothDeviceState(BluetoothDeviceState.connected);
      } //if
    } //for

    if (_deviceState == BluetoothDeviceState.disconnected) {
      // scan for atmotube
      dynamic scan =
          await flutterBlue.startScan(timeout: const Duration(seconds: 4));

      for (dynamic s in scan) {
        // looking for non null devices
        if (s.advertisementData.serviceUuids.isNotEmpty) {
          // looking for atmotube Pro
          if (s.advertisementData.serviceUuids.last ==
              DeviceServiceConfig().deviceService.toLowerCase()) {
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
    } //if

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
    List<dynamic> data1 = atmotubeData.status;
    List<dynamic> data2 = atmotubeData.status;
    List<dynamic> data3 = atmotubeData.bme280;
    List<dynamic> data4 = atmotubeData.pm;
    List<dynamic> data5 = atmotubeData.voc;

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
            // bme data (humidity, temperature, pressure)
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
            // filter for non interested measurements
            if (data4.first > 1000) {
              data4 = ['Nan', 'Nan', 'NaN', 'NaN'];
            }
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
            //print('something is wrong');
          }
      }
      // update values of a streammable atmotubeData object
      atmotubeData = atmotubeData.copyWith(
          datetime: DateTime.now(),
          status: [data1, data2],
          bme280: data3,
          pm: data4,
          voc: data5);
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

    Timer.periodic(const Duration(seconds: 5), (timer) {
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

  /// [histwrapper] A wrapper method that handles device history data collection
  Future<void> histwrapper({required Function callback}) async {
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
    Stream<AtmotubeData> histData = getAtmotubeHistObject();
    //listener
    histData.listen((event) {
      callback(event);
    });
  } // histwrapper

  /// [getAtmotubeHistObject] A method that creates a Stream from an AtmotubeData object
  Stream<AtmotubeData> getAtmotubeHistObject() async* {
    yield atmotubeDataHist;
  } // getAtmotubeHistObject

  /// [getHist] A method that handles device history data via UART communication (sending commands via tx channel and listening via rx channel)
  void getHist(List<BluetoothCharacteristic> characteristics) async {
    BluetoothCharacteristic rx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().rxCharacteristicId);
    BluetoothCharacteristic tx = characteristics.firstWhere((element) =>
        element.uuid.toString() == HistoryServiceConfig().txCharacteristicId);

    // history request command definition
    Uint8List timestamp = DataConversion().timestampEncoder();
    Uint8List command = DataConversion().commandEncoder('HST');
    final txCommand =
        Uint8List.fromList([command, timestamp].expand((x) => x).toList());

    // history request
    await rx.setNotifyValue(true);
    await tx.write(txCommand, withoutResponse: true);

    //init
    int previousPacketNumber = 0;
    int packetTotal = 0;
    int packetDim = 0;
    int j = 0;
    List<DateTime> datetimeList = [];
    List<DateTime> datetimeRange = [];
    //listener
    rx.value.listen((event) {
      final response = event.isEmpty
          ? 'None'
          : utf8.decoder.convert(event.getRange(0, 2).toList());
      //print('The device response is {$response}');

      switch (response) {
        case 'HO':
          {
            //print('device received a history request');
          }
          break;
        case 'HT':
          {
            //timestamp of the starting HD packet
            Iterable<int> timebyte = event.getRange(3, 7).toList();
            DateTime packetTime = DataConversion().timestampDecoder(timebyte);

            // number of HD packets
            packetTotal = event.elementAt(7);

            // dimension of HD packets
            packetDim = event.elementAt(8);

            // prova
            final timestamp = packetTime.millisecondsSinceEpoch;
            // supposing always 5 min mode
            // note: history seems to not follow this structure. Every 1 minute a value? Check csv value: yes every one minute
            var list =
                List<int>.generate(packetTotal, (i) => timestamp + 60000 * i);
            for (int i = 0; i < packetTotal; i++) {
              datetimeList.add(DateTime.fromMillisecondsSinceEpoch(list[i]));
            }
            // print(datetimeList);

            // print('time of the first history packet: {$packetTime}');
            // print('total number of history packets: {$packetTotal}');
            // print('dimension of history packets: {$packetDim}');
          }
          break;
        case 'HD':
          {
            // if device responds with an HD packet before an HT one, this is not from the actual request
            if (packetTotal == 0 && packetDim == 0) {
              break;
            }
            int packetNumber = event.elementAt(3);
            print('sent history packet number: {$packetNumber}');
            //print(event);

            // extract only the data
            List<int> data = event.getRange(4, event.length).toList();

            // number of packets sent computed as the difference between the previous and actual number packet
            int diff = packetNumber - previousPacketNumber;
            previousPacketNumber = packetNumber;

            // extract the timestamps of a certain packet (e.g from 1 to 15, from 16 to 30 etc) => which corresponds to indeces (0-14, 15-29)
            datetimeRange =
                datetimeList.getRange(j * 15, packetNumber).toList();

            for (int i in Iterable<int>.generate(diff).toList()) {
              print(datetimeRange[i]);
              // get a specific packet of length specified in HT response (so far, ever 16)
              List<int> subset =
                  data.getRange(i * packetDim, (i * packetDim) + 15).toList();

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

              print('temperature is: {$temp}');
              print('humidity is: {$humidity}');
              print('voc is: {$voc}');
              print('pressure is: {$pressure}');
              print('pm1 is: {$pm1}');
              print('pm2 is: {$pm2}');
              print('pm10 is: {$pm10}');

              // update an AtmotubeData object with history values
              atmotubeDataHist = atmotubeDataHist.copyWith(
                  datetime: datetimeRange[i],
                  bme280: [temp, humidity, pressure],
                  pm: [pm1, pm2, pm10, 0],
                  voc: [voc]);
            }

            // send the HOK command for keeping up device sending history packets
            if (packetNumber == packetTotal) {
              previousPacketNumber = 0;
              datetimeList = [];
              j = 0;
              Uint8List confirmTimestamp = DataConversion().timestampEncoder();
              Uint8List confirmCommand = DataConversion().commandEncoder('HOK');
              final txAcknowledge = Uint8List.fromList(
                  [confirmCommand, confirmTimestamp].expand((x) => x).toList());
              // print(txAcknowledge);
              // print('new packet arriving');
              // Future.delayed(const Duration(seconds: 1), () {
              tx.write(txAcknowledge, withoutResponse: true);
              // });
            } else {
              // update for loop in HD case
              previousPacketNumber = packetNumber;
              j = j + 1;
            }
          }
          break;
        default:
          {
            //print('no command found!')
          }
          break;
      } // switch
    }); // listen
  } // getHist
} // Atmotuber
