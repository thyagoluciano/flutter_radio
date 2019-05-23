# flutter_radio

A Flutter audio plugin for Android to play remote audio files using ExoPlayer

[![pub package](https://img.shields.io/badge/pub-0.1.7-blue.svg)](https://pub.dartlang.org/packages/flutter_radio)

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


## Contributors ✨

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/Dekkee">
        <img src="https://avatars.githubusercontent.com/u/8166473?v=3" width="100px;" alt="Alexander Tihoniuk"/>
        <br />
        <sub><b>Alexander Tihoniuk</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://kentcdodds.com">
        <img src="https://avatars.githubusercontent.com/u/26438532?v=3" width="100px;" alt="Yeikel200"/>
        <br />
        <sub><b>Yeikel200</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://kentcdodds.com">
        <img src="https://avatars.githubusercontent.com/u/2340826?v=3" width="100px;" alt="Asheesh Srivastava"/>
        <br />
        <sub><b>Asheesh Srivastava</b></sub>
      </a>
    </td>
  </tr>
</table>