import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class Track extends StatefulWidget {
  Track({Key key, @required this.files, this.level, this.trackName})
      : super(key: key);

  final List<XFile> files;
  final AudioPlayer player = AudioPlayer();
  final double level;
  final String trackName;

  void playStatus(String name, Duration totalTime, Duration playtime) async {
    // print('play status: $totalTime');
  }

  @override
  TrackState createState() => TrackState();
}

class TrackState extends State<Track> {
  double _gain = 0.8;
  String _title = '';
  String _currentlyPlaying = '';
  TextEditingController _controller = TextEditingController();

  void _addFiles() async {
    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav']);
    final List<XFile> newFiles =
        await openFiles(acceptedTypeGroups: [typeGroup]);
    widget.files.addAll(newFiles);
  }

  void play() async {
    XFile randomFile = (widget.files.toList()..shuffle()).first;
    await widget.player.setFilePath(randomFile.path);

    setState(() {
      _currentlyPlaying = randomFile.name;
    });

    print(_currentlyPlaying);

    bool alreadyPlayed = false;

    StreamSubscription playState =
        widget.player.playerStateStream.listen((state) async {
      StreamSubscription playtime;
      if (state.playing) {
        alreadyPlayed = true;
        playtime = widget.player.positionStream.listen((Duration time) {
          widget.playStatus(randomFile.name, widget.player.duration, time);
        });
      } else if (alreadyPlayed) {
        playtime.cancel();
        setState(() {
          _currentlyPlaying = '';
        });
      }
    });

    await widget.player.play();
    playState.cancel();
    print(_currentlyPlaying);
    // playStatus(randomFile.name);
  }

  @override
  void initState() {
    _title = widget.trackName != null ? widget.trackName : widget.files[0].name;
    _gain = widget.level != null ? (widget.level / 1.25) : 1.0;
    _controller.text = _title;
    super.initState();
  }

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
                    _title = newVal;
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
              Text(
                _currentlyPlaying,
                style: TextStyle(
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                    fontSize: 10.0),
              ),
              Spacer(),
              TextButton(
                  onPressed: () {
                    _addFiles();
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
        SizedBox(
          height: 30.0,
        )
      ],
    );
  }
}
