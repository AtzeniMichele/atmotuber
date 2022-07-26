# atmotuber

![atmotuber_logo](https://user-images.githubusercontent.com/99322237/181044838-d9f3ab77-6ac7-4ab0-8bf1-f24a3e9eb7f7.png)


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
<<<<<<< HEAD
=======

>>>>>>> 09565e07300cf7a32cc0e1e8671de6e3c5d7ded3
