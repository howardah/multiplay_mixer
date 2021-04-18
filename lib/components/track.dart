import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class Track extends StatefulWidget {
  Track({Key key, @required this.files}) : super(key: key);

  final List<XFile> files;
  final AudioPlayer player = AudioPlayer();
  String trackName = '';

  void addFiles() async {
    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav']);
    final List<XFile> newFiles =
        await openFiles(acceptedTypeGroups: [typeGroup]);
    files.addAll(newFiles);
  }

  void play() async {
    XFile randomFile = (files.toList()..shuffle()).first;
    await player.setFilePath(randomFile.path);

    StreamSubscription playState =
        player.playerStateStream.listen((state) async {
      StreamSubscription playtime;
      bool alreadyPlayed = false;
      if (state.playing) {
        alreadyPlayed = true;
        playtime = player.positionStream.listen((Duration time) {
          playStatus(randomFile.name, player.duration, time);
        });
      } else if(alreadyPlayed) {
        playtime.cancel();
      }
    });

    List<XFile> getFiles() {
      return files;
    }

    await player.play();
    playState.cancel();
    // playStatus(randomFile.name);
  }

  void playStatus(String name, Duration totalTime, Duration playtime) async {
    // print('$name: $playtime/$totalTime');
  }

  @override
  _TrackState createState() => _TrackState();
}

class _TrackState extends State<Track> {
  double _gain = 0.8;
  String _title = '';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.trackName = widget.files[0].name;
    _controller.text = widget.files[0].name;
  }

  // void setTitle(String title) {
  //   setState(() {
  //     this._title = title;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 0.0),
          child: Row(
            children: [
              SizedBox(
                child: TextField(
                  controller: _controller,
                  onChanged: (String newVal) {
                    widget.trackName = newVal;
                    print(newVal);
                  },
                ),
                width: 250.0,
              ),
              SizedBox(
                width: 10.0,
              ),
              PopupMenuButton(
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  ...() {
                    List<PopupMenuEntry> currentFiles = [];
                    widget.files.asMap().forEach((index, element) {
                      currentFiles.add(
                        PopupMenuItem(
                          value: index,
                          child: Row(
                            children: [
                              Text(element.name),
                              Spacer(),
                              Icon(Icons.cancel)
                            ],
                          ),
                        ),
                      );
                    });
                    return currentFiles;
                  }(),
                ],
                onSelected: (value) {
                  widget.files.removeAt(value);
                },
                onCanceled: () {
                  print('Yeah, okay');
                },
                padding: EdgeInsets.zero,
                tooltip: "Edit Track Contents",
              ),
              Text(_title),
              Spacer(),
              TextButton(
                  onPressed: () {
                    widget.addFiles();
                  },
                  child: Text('add files')),
            ],
          ),
        ),
        Slider(
            value: _gain,
            onChanged: (double value) {
              widget.player.setVolume(value * 1.25);
              setState(() {
                _gain = value;
              });
            }),
        SizedBox(height: 30.0,)
      ],
    );
  }
}
