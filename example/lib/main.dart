// ignore_for_file: unnecessary_const

import 'package:atmotuber/atmotuber.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:flutter_blue/flutter_blue.dart';
// import 'package:async/async.dart';

void main() {
  return runApp(
    const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Atmotuber atm2 = Atmotuber();
  //List<dynamic> values = [];
  List<String> names = ['status', 'BME280', 'PM', 'VOC'];
  ValueNotifier<AtmotubeData> dataGot = ValueNotifier(const AtmotubeData());
  ValueNotifier<AtmotubeData> history = ValueNotifier(const AtmotubeData());
  late String _status;

  Future<void> connectDevice() async {
    //await atmotuber.searchAtmotube();
    await atm2.searchAtmotube();
    //await atm2.wrapper();
  }

  // void initialization() async {
  //   await connectDevice();
  //   //debugPrint('device is connected');
  //   //Future.delayed(const Duration(seconds: 2), dataTaker);
  // }

  Future<void> dataTaker() async {
    await atm2.wrapper(callback: (streams) {
      dataGot.value = streams;
    });
  }

  Future<void> dataHist() async {
    await atm2.histwrapper(callback: (histStreams) {
      history.value = histStreams;
      //print(history.value.bme280);
      //print(history.value.pm);
      //print(history.value.voc);
    });
  }

  @override
  void initState() {
    //initialization();
    _status = 'disconnected';
    super.initState();
  }

  void showsnack(SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              child: const Text(
                'Connect ATMOTUBE',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: () async {
                await connectDevice();
                _status = atm2.getDeviceState();
                if (_status == 'connected') {
                  const snackBar = SnackBar(
                    content: const Text('Connected!'),
                    backgroundColor: Colors.green,
                  );
                  showsnack(snackBar);
                } else if (_status == 'disconnected') {
                  const snackBar = SnackBar(
                    content: const Text('Not Connected!'),
                    backgroundColor: Colors.red,
                  );
                  showsnack(snackBar);
                }
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              child: const Text(
                'Disconnect ATMOTUBE',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: () async {
                await atm2.dropConnection();
                _status = atm2.getDeviceState();
                if (_status == 'disconnected') {
                  const snackBar = SnackBar(
                    content: const Text('Not Connected anymore!'),
                    backgroundColor: Colors.red,
                  );
                  showsnack(snackBar);
                }
              },
            ),
          ),
          // Center(
          //   child: ElevatedButton(
          //     child: const Text(
          //       ' ATMOTUBE',
          //       style: TextStyle(fontSize: 20.0),
          //     ),
          //     onPressed: () async {
          //       final service = await atm2.getAtmotubeService();
          //       final chars = await atm2.getCharacteristics(service);
          //       BluetoothCharacteristic c = chars.firstWhere((element) =>
          //           element.uuid.toString() ==
          //           DeviceServiceConfig().vocCharacteristics);
          //       c.setNotifyValue(true);
          //       var s = c.value.map((event) {
          //         return (c.uuid.toString() + '-' + event.toString());
          //       });
          //       AtmotubeData atm = AtmotubeData();
          //       BluetoothCharacteristic c1 = chars.firstWhere((element) =>
          //           element.uuid.toString() ==
          //           DeviceServiceConfig().bmeCharacteristic);
          //       c1.setNotifyValue(true);
          //       var s1 = c1.value.map((event) {
          //         return (c1.uuid.toString() + '-' + event.toString());
          //       });
          //       StreamController<AtmotubeData> satm = StreamController()
          //         ..add(AtmotubeData());
          //       StreamGroup.merge([s, s1]).listen((event) {
          //         List<String> e = event.split('-');
          //         if (e[0] == DeviceServiceConfig().vocCharacteristics) {
          //           satm.add(atm.copyWith(voc: [1]));
          //         }
          //       });
          //       satm.stream.listen((event) {
          //         print(event);
          //       });
          //     },
          //   ),
          // ),
          Center(
            child: ElevatedButton(
              onPressed: dataTaker,
              child: const Text(
                'get data',
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: dataHist,
              child: const Text(
                'get history',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const SizedBox(
            height: 30,
            width: 360,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Real-time data',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400)),
            ),
          ),
          Center(
            child: ValueListenableBuilder(
              valueListenable: dataGot,
              builder: (context, AtmotubeData data, child) {
                List list = [data.status, data.bme280, data.pm, data.voc];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: <Widget>[
                            ListTile(
                              title: Text(names[index]),
                              subtitle: Text(list[index].toString()),
                            ),
                            const Divider(height: 2.0)
                          ],
                        );
                      },
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
