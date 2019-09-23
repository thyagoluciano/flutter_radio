import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_radio/flutter_radio.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const streamUrl =
      "http://sc1.111ttt.cn/2017/1/05/09/298092035545.mp3";

  bool isPlaying;

  @override
  void initState() {
    super.initState();
    audioStart();
    playingStatus();
  }

  Future<void> audioStart() async {
    AudioPlayerItem item=AudioPlayerItem(title: "title",url: "http://sc1.111ttt.cn/2017/1/05/09/298092035545.mp3",album: "album",id: "id",isStream: false,artist: "artist");
    await FlutterRadio.audioStart(item);
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
                  onPressed: () {
                    FlutterRadio.playOrPause(url: streamUrl);
                    playingStatus();
                  },
                ),
                FlatButton(
                  child: Icon(Icons.pause_circle_filled),
                  onPressed: () {
                    FlutterRadio.playOrPause(url: streamUrl);
                    playingStatus();
                  },
                ),
                FlatButton(
                  child: Icon(Icons.stop),
                  onPressed: () {
                    FlutterRadio.playOrPause(url: streamUrl);
                    playingStatus();
                  },
                ),
                Text(
                  'Check Playback Status: $isPlaying',
                  style: TextStyle(fontSize: 25.0),
                )
              ],
            )),
      ),
    );
  }

  Future playingStatus() async {
    bool isP = await FlutterRadio.isPlaying();
    setState(() {
      isPlaying = isP;
    });
  }
}
