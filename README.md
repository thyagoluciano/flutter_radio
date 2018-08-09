# flutter_radio

A Flutter audio plugin for Android to play remote audio files using ExoPlayer

## Installation

First, add flutter_radio as a dependency in your pubspec.yaml file.

## Example

```
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_radio/flutter_radio.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {

  String url = "https://ia802708.us.archive.org/3/items/count_monte_cristo_0711_librivox/count_of_monte_cristo_001_dumas.mp3";

  @override
  void initState() {
    super.initState();
    audioStart();
  }

  Future<void> audioStart() async {
    await FlutterRadio.audioStart();
    print('Audio Start OK');
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Audio Plugin Android'),
        ),
        body: new Center(
          child: Column(
            children: <Widget>[
              FlatButton(
                child: Icon(Icons.play_circle_filled),
                onPressed: () => FlutterRadio.play(url: url),
              ),
              FlatButton(
                child: Icon(Icons.pause_circle_filled),
                onPressed: () => FlutterRadio.pause(),
              )
            ],
          )
        ),
      ),
    );
  }
}
```