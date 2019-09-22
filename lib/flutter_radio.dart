import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

typedef void PlayChange(bool isPlay);
class FlutterRadio {
  static const MethodChannel _channel = const MethodChannel('flutter_radio');
  static StreamController<PlayStatus> _playerController;
  /// Value ranges from 0 to 120
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;

  static bool _isPlaying = false;

  static PlayChange playChange;

  static Future<void> audioStart([AudioPlayerItem item]) async {
    if (item != null) {
      await setMeta(item);
    }
    await _channel.invokeMethod('audioStart');
  }

  static Future<void> playOrPause({@required String url}) async {
    try {
      if (FlutterRadio._isPlaying) {
        FlutterRadio.pause(url: url);
      } else {
        FlutterRadio.play(url: url);
      }
    } catch (err) {
      throw Exception(err);
    }
  }

  static Future<void> play({@required String url}) async {
    try {
      String result =
          await _channel.invokeMethod('play', <String, dynamic>{
        'url': url,
      });
      print('result: $result');

      _setPlayerCallback();

      if (FlutterRadio._isPlaying) {
        throw Exception('Player is already playing.');
      }
      FlutterRadio._isPlaying = true;

      return result;
    } catch (err) {
      throw Exception(err);
    }
  }

  static Future<void> pause({@required String url}) async {
    if (!FlutterRadio._isPlaying) {
      throw Exception('Player already stopped.');
    }
    FlutterRadio._isPlaying = false;

    final Map<String, dynamic> params = <String, dynamic>{'url': url};
    String result = await _channel.invokeMethod('pause', params);
    _removePlayerCallback();
    return result;
  }

  static Future<void> stop() async {
    if (!FlutterRadio._isPlaying) {
      throw Exception('Player already stopped.');
    }
    FlutterRadio._isPlaying = false;

    String result = await _channel.invokeMethod('stop');
    _removePlayerCallback();
    return result;
  }

  static Future<bool> isPlaying() async {
    return Future.value(_isPlaying);
  }

  static Future<void> _setPlayerCallback() async {
    if (_playerController == null) {
      _playerController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateProgress":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _playerController.add(new PlayStatus.fromJSON(result));
          break;
        case "controlPlayChanged":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          String statuts = result["status"];
          if(playChange != null){
            playChange(statuts == "0" ? false : true);
          }
          break;  
        default:
          throw new ArgumentError('Unknown method ${call.method}');
      }
    });
  }

  static Future<void> _removePlayerCallback() async {
    if (_playerController != null) {
      _playerController
        ..add(null)
        ..close();
      _playerController = null;
    }
  }

  static Future<String> setMeta(AudioPlayerItem item) async {
    String result = await _channel.invokeMethod('setMeta', <String, dynamic>{
        'meta': item.toMap(),
      });
    _removePlayerCallback();
    return result;
  }

  static Future<String> setVolume(double volume) async {
    String result = '';
    if (volume < 0.0 || volume > 1.0) {
      result = 'Value of volume should be between 0.0 and 1.0.';
      return result;
    }

    result = await _channel
        .invokeMethod('setVolume', <String, dynamic>{
      'volume': volume,
    });
    return result;
  }
}

class PlayStatus {
  final double duration;
  double currentPosition;

  PlayStatus.fromJSON(Map<String, dynamic> json)
      : duration = double.parse(json['duration']),
        currentPosition = double.parse(json['current_position']);

  @override
  String toString() {
    return 'duration: $duration, '
        'currentPosition: $currentPosition';
  }
}

class AudioPlayerItem{
  String id;
  String url;
  String thumbUrl;
  String title;
  Duration duration;
  double progress;
  String album;
  bool local;
  String artist;
  String defaultImage;

  AudioPlayerItem({
    this.id,
    this.url,
    this.thumbUrl,
    this.title,
    this.duration,
    this.progress,
    this.album,
    this.local,
    this.artist,
    this.defaultImage,
  });

  Map<String, dynamic> toMap(){
    return {
      'id': this.id,
      'url': this.url,
      'thumb': this.thumbUrl,
      'title': this.title,
      'duration': this.duration != null ?this.duration.inSeconds : 0,
      'progress': this.progress ?? 0,
      'album': this.album,
      'local': this.local,
      'artist': this.artist,
      'defaultImage': this.defaultImage
    };
  }

}
