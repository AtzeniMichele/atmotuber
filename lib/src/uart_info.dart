/// Configuration for a serial service
class HistoryServiceConfig {
  /// UUID of the GATT service.
  final String serviceId = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";

  /// UUID of the TX characteristic.
  ///
  /// The software will write the *outgoing* data to this characteristic.
  final String txCharacteristicId = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  /// UUID of the RX characteristic.
  ///
  /// The software will subscribe to notifications for the *incoming* data.
  final String rxCharacteristicId = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  final String hstRequest = 'HST';

  final String hstReceived = 'HOK';
}
