# atmotuber

![black_atmotuber_logo](https://user-images.githubusercontent.com/99322237/181071737-4d2421c1-7c7d-41b2-ab4f-aea1959fb6d9.png)


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
