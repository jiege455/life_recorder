import 'dart:async';

class AppEvents {
  static final AppEvents _instance = AppEvents._internal();
  factory AppEvents() => _instance;
  AppEvents._internal();

  final _recordChangedController = StreamController<void>.broadcast();

  Stream<void> get recordChanged => _recordChangedController.stream;

  void notifyRecordChanged() {
    _recordChangedController.add(null);
  }

  void dispose() {
    _recordChangedController.close();
  }
}
