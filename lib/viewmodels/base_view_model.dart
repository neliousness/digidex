import 'package:flutter/cupertino.dart';

class BaseViewModel extends ChangeNotifier {
  late dynamic _value = '';

  dynamic get value => _value;

  set value(dynamic value) {
    _value = value;
  }

  void postValue(dynamic object) {
    _value = object;
    notifyListeners();
  }
}
