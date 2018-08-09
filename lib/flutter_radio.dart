import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterRadio {
  static const MethodChannel _channel = const MethodChannel('flutter_radio');

  static Future<void> audioStart() async {
    await _channel.invokeMethod('audioStart');
  }

  static Future<void> play({@required String url}) async {
    final Map<String, dynamic> params = <String, dynamic> {
      'url': url
    };

    await _channel.invokeMethod('play', params);
  }

  static Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }
}

