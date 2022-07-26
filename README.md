# atmotuber

![atmotuber_logo](https://user-images.githubusercontent.com/99322237/181044838-d9f3ab77-6ac7-4ab0-8bf1-f24a3e9eb7f7.png)

A Flutter package to deal with Atmotube Bluetooth API directly via BLE connection and make data ready to use within your app. 

## usage 
To use the package:
- add the dependency to your pubspec.yaml file

```yaml
dependencies:
  flutter:
      sdk: flutter
  atmotuber:
```
- (ios only) go to ios/Runner/Info.plist and add the following

 ```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need BLE permission</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need BLE permission</string>
```
- (adroid only) go to android/app/src/main/AndroidManifest.xml

 ```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
```

To connect to Atmotube Pro: 

```dart
// init
Atmotuber atm = Atmotuber();
// connect
await atm.searchAtmotube();
```
To read real-time data: 

```dart
await atm.wrapper(callback: (streams) {
    dataGot.value = streams;
    }
```
To read history data: 

```dart
await atm.hist_wrapper(callback: (streams) {
    history.value = streams;
    }
```
To disconnect from Atmotube Pro: 

```dart
// disconnect
await atm.dropConnection(); 
```