import 'package:atmotuber/atmotuber.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  return runApp(
    MaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Atmotuber atm2 = Atmotuber();
  //List<dynamic> values = [];
  List<String> names = ['status', 'BME280', 'PM', 'VOC'];
  ValueNotifier<AtmotubeData> dataGot = ValueNotifier(AtmotubeData());
  late String _status;

  Future<void> connectDevice() async {
    //await atmotuber.searchAtmotube();
    await atm2.searchAtmotube();
    //await atm2.wrapper();
  }

  void initialization() async {
    await connectDevice();
    //debugPrint('device is connected');
    //Future.delayed(const Duration(seconds: 2), dataTaker);
  }

  Future<void> dataTaker() async {
    await atm2.wrapper(callback: (streams) {
      dataGot.value = streams;
    });
  }

  Future<void> dataHist() async {
    await atm2.hist_wrapper();
  }

  @override
  void initState() {
    //initialization();
    _status = 'disconnected';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              child: Text(
                'Connect ATMOTUBE',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: () async {
                await connectDevice();
                _status = atm2.getDeviceState();
                if (_status == 'connected') {
                  final snackBar = SnackBar(
                    content: const Text('Connected!'),
                    backgroundColor: Colors.green,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } else if (_status == 'disconnected') {
                  final snackBar = SnackBar(
                    content: const Text('Not Connected!'),
                    backgroundColor: Colors.red,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              child: Text(
                'Disconnect ATMOTUBE',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: () async {
                await atm2.dropConnection();
                _status = atm2.getDeviceState();
                if (_status == 'disconnected') {
                  final snackBar = SnackBar(
                    content: const Text('Not Connected anymore!'),
                    backgroundColor: Colors.red,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              child: Text(
                'get data',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: dataTaker,
            ),
          ),
          Center(
            child: ElevatedButton(
              child: Text(
                'get history',
                style: TextStyle(fontSize: 20.0),
              ),
              onPressed: dataHist,
            ),
          ),
          Center(
            child: ValueListenableBuilder(
              valueListenable: dataGot,
              builder: (context, AtmotubeData data, child) {
                List list = [data.Status, data.BME280, data.PM, data.VOC];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //data.Status.isEmpty
                    //? Text(_status) //const CircularProgressIndicator()
                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: <Widget>[
                            ListTile(
                              title: Text('${names[index]}'),
                              subtitle: Text('${list[index]}'),
                            ),
                            Divider(height: 2.0)
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
