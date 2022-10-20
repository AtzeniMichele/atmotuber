import 'package:async/async.dart';
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
  var atmotubeData = const AtmotubeData();
  var atmotubeDataHist = const AtmotubeData();
  StreamController<AtmotubeData> satm = StreamController();
  StreamController<AtmotubeData> hatm = StreamController();
  static BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<Map<String, List<int>>>? subscription;
  StreamSubscription<List<int>>? subscription2;

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
                  DeviceServiceConfig().deviceService.toLowerCase() ||
              s.advertisementData.serviceUuids.last ==
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
      await handleStreams();
    } //if

    // setup for later timer.periodic call
    shouldStop = false;
    return device;
  } // searchAtmotube

  Future<void> handleStreams() async {
    // BluetoothService service = await getAtmotubeService();
    // List<BluetoothCharacteristic> characteristics =
    //     await getCharacteristics(service);
    // BluetoothService uartService = await getUartAtmotubeService();
    // List<BluetoothCharacteristic> uartCharacteristics =
    //     await getCharacteristics(uartService);

    device!.state.listen((event) {
      if (event == BluetoothDeviceState.disconnected) {
        // for (BluetoothCharacteristic c in characteristics) {
        //   c.setNotifyValue(false);
        // }
        // for (BluetoothCharacteristic u in uartCharacteristics) {
        //   u.setNotifyValue(false);
        // }
        subscription?.cancel();
        subscription2?.cancel();
      }
    });
  } //hadleStreams

  /// [dropConnection] a method that handles device disconnection action
  Future<void> dropConnection() async {
    // close the streams when atmotube no longer connected
    handleStreams();
    satm.close();
    satm = StreamController();
    hatm.close();
    hatm = StreamController();

    //look for atmotube among connected devices
    var connected = await flutterBlue.connectedDevices;
    for (var element in connected) {
      if (element.name == DeviceServiceConfig().deviceName) {
        element.state.listen((event) {
          //(event);
        });
        await element.disconnect();
        _handleBluetoothDeviceState(BluetoothDeviceState.disconnected);
        shouldStop = true;
      }
    }
  } // dropConnection

  /// [cancelStreamRealTime] is a method to stop listening the Atomutber Stream objects
  Future<void> cancelStreamRealTime() async {
    satm.close();
    satm = StreamController();
  } //cancelStreamRealTime

  /// [cancelStreamHistory] is a method to stop listening the Atomutber Stream objects
  Future<void> cancelStreamHistory() async {
    hatm.close();
    hatm = StreamController();
  } //cancelStreamHistory

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
  List<dynamic> getValues(
      List<int> list, List<int> startRanges, List<int> stopRanges) {
    List values = [];
    if (startRanges.length == stopRanges.length) {
      final indexes =
          startRanges.mapIndexed((index, element) => index).toList();
      for (int i in indexes) {
        values.add(DataConversion()
            .getConversion(list, startRanges[i], stopRanges[i]));
      }
    }
    return values;
  } // getValues

  /// [getData] A Stream method that handles device real-time data from different type of ble characterstics and write into an AtmotubeData object
  void getData(Map<String, List<int>> mapData) {
    List<dynamic> data = atmotubeData.status;
    List<dynamic> data3 = atmotubeData.bme280;
    List<dynamic> data4 = atmotubeData.pm;
    List<dynamic> data5 = atmotubeData.voc;
    switch (mapData.entries.first.key) {
      case 'status':
        {
          // status data (battery)
          List<dynamic> data1 =
              getValues(mapData.entries.first.value, [1], [1]);
          // status data (status bits)
          List<dynamic> data2 =
              DataConversion().getBits(mapData.entries.first.value[0]);
          atmotubeData = atmotubeData.copyWith(
              datetime: DateTime.now(),
              status: [data1, data2],
              bme280: data3,
              pm: data4,
              voc: data5);
          satm.add(atmotubeData);
        }
        break;
      case 'bme':
        {
          // bme data (humidity, temperature, pressure)
          data3 = getValues(mapData.entries.first.value, [0, 1, 2], [0, 1, 5]);
          // pressure data from mbar * 100 to mbar
          data3[2] = data3[2] / 100;
          atmotubeData = atmotubeData.copyWith(
              datetime: DateTime.now(),
              status: data,
              bme280: data3,
              pm: data4,
              voc: data5);
          satm.add(atmotubeData);
        }
        break;
      case 'pm':
        {
          // pm data (pm1, pm2.5, pm10)
          data4 = getValues(mapData.entries.first.value, [0, 3, 6], [2, 5, 8]);
          data4 = data4.map((e) => e / 100).toList();
          // filter for non interested measurements
          if (data4.first > 1000) {
            data4 = ['Nan', 'Nan', 'NaN', 'NaN'];
          }
          atmotubeData = atmotubeData.copyWith(
              datetime: DateTime.now(),
              status: data,
              bme280: data3,
              pm: data4,
              voc: data5);
          satm.add(atmotubeData);
        }
        break;
      case 'voc':
        {
          // voc data
          data5 = getValues(mapData.entries.first.value, [0], [1]);
          data5 = data5.map((e) => e / 1000).toList(); // from ppb to ppm
          atmotubeData = atmotubeData.copyWith(
              datetime: DateTime.now(),
              status: data,
              bme280: data3,
              pm: data4,
              voc: data5);
          satm.add(atmotubeData);
        }
        break;
      default:
        {
          //print('something is wrong');
        }
        break;
    }
    // update values of a streammable atmotubeData object
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

    // status stream subscription
    BluetoothCharacteristic statusCharacteristics = characteristics.firstWhere(
        (element) =>
            element.uuid.toString() ==
            DeviceServiceConfig().statusCharacteristic);
    await statusCharacteristics.setNotifyValue(true);
    Stream<Map<String, List<int>>> status =
        statusCharacteristics.value.map((event) => {"status": event});
    // bme stream subscription
    BluetoothCharacteristic bmeCharacteristics = characteristics.firstWhere(
        (element) =>
            element.uuid.toString() == DeviceServiceConfig().bmeCharacteristic);
    await bmeCharacteristics.setNotifyValue(true);
    Stream<Map<String, List<int>>> bme =
        bmeCharacteristics.value.map((event) => {"bme": event});
    // pm stream subscription
    BluetoothCharacteristic pmCharacteristics = characteristics.firstWhere(
        (element) =>
            element.uuid.toString() == DeviceServiceConfig().pmCharacteristic);
    await pmCharacteristics.setNotifyValue(true);
    Stream<Map<String, List<int>>> pm =
        pmCharacteristics.value.map((event) => {"pm": event});

    // voc stream subscription
    BluetoothCharacteristic vocCharacteristics = characteristics.firstWhere(
        (element) =>
            element.uuid.toString() ==
            DeviceServiceConfig().vocCharacteristics);
    await vocCharacteristics.setNotifyValue(true);
    Stream<Map<String, List<int>>> voc =
        vocCharacteristics.value.map((event) => {"voc": event});

    //  update atmotubeData object and listen to its changes.
    subscription = StreamGroup.merge([status, bme, pm, voc]).listen((event) {
      //print(event);
      if (event.entries.first.value.isNotEmpty) {
        //print("${event.entries.first.value}");
        getData(event);
      }
    });
    satm.stream.listen((event) {
      //print(event.voc);
      callback(event);
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
    //listener
    hatm.stream.listen(
      (event) {
        callback(event);
      },
    );
  } // histwrapper

  // /// [getAtmotubeHistObject] A method that creates a Stream from an AtmotubeData object
  // Stream<AtmotubeData> getAtmotubeHistObject() async* {
  //   yield atmotubeDataHist;
  // } // getAtmotubeHistObject

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

    Timer? timeout;

    //init
    int previousPacketNumber = 0;
    int packetTotal = 0;
    int packetDim = 0;
    int j = 0;
    List<DateTime> datetimeList = [];
    List<DateTime> datetimeRange = [];
    //listener
    subscription2 = rx.value.listen((event) {
      //setup timer for end of history if no communication for 10 seconds
      if (timeout != null) timeout!.cancel();
      timeout = Timer(const Duration(seconds: 10), () async {
        await rx.setNotifyValue(false);
        subscription2?.cancel();
        cancelStreamHistory();
        //print('History done');
      });

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
            //print('sent history packet number: {$packetNumber}');
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
              //print(datetimeRange[i]);
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

              // print('temperature is: {$temp}');
              // print('humidity is: {$humidity}');
              // print('voc is: {$voc}');
              // print('pressure is: {$pressure}');
              // print('pm1 is: {$pm1}');
              // print('pm2 is: {$pm2}');
              // print('pm10 is: {$pm10}');

              // update an AtmotubeData object with history values
              atmotubeDataHist = atmotubeDataHist.copyWith(
                  datetime: datetimeRange[i],
                  bme280: [temp, humidity, pressure],
                  pm: [pm1, pm2, pm10, 0],
                  voc: [voc]);
              hatm.add(atmotubeDataHist);
            }

            // send the HOK command for keeping up device sending history packets
            if (packetNumber == packetTotal) {
              previousPacketNumber = 0;
              datetimeList = [];
              j = 0;
              Uint8List confirmTimestamp = DataConversion().timestampEncoder();
              Uint8List confirmCommand = DataConversion().commandEncoder('HOK');
              // Uint8List zero = DataConversion().int32BigEndianBytes(0);
              final txAcknowledge = Uint8List.fromList([
                confirmCommand,
                /*zero,*/
                confirmTimestamp
              ].expand((x) => x).toList());
              // print(txAcknowledge);
              //print('new packet arriving');
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
        case 'None':
          {}
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
