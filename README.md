# atmotuber

A Flutter package to deal with Atmotube BLE communication and make data available within your app. 

## usage 
To use the package:
- add the dependency to your pubspec.yaml file

```yaml
dependencies:
  flutter:
      sdk: flutter
  atmotuber:
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
