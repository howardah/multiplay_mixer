import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class Track extends StatefulWidget {
  Track({Key? key, required this.files, this.level = 1.0, this.trackName})
      : super(key: key);

  final List<XFile> files;
  final double level;
  final String? trackName;

  void playStatus(String name, Duration totalTime, Duration playtime) async {
    // print('play status: $totalTime');
  }

  Future<Duration> longestDuration() async {
    Duration longest = Duration(seconds: 0);
    //ToDo: use ffprobe to get the duration of each track
    return longest;
  }

  @override
  TrackState createState() => TrackState();
}

class TrackState extends State<Track> {
  double _gain = 0.8;
  String _title = '';
  String _currentlyPlaying = '';
  TextEditingController _controller = TextEditingController();
  Duration _longestDuration = Duration();

  void _addFiles() async {
    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav', '.m4a']);
    final List<XFile> newFiles =
        await openFiles(acceptedTypeGroups: [typeGroup]);
    widget.files.addAll(newFiles);
    _updateLongest();
  }

  void _updateLongest() async {
    Duration ld = await widget.longestDuration();
    setState(() {
      _longestDuration = ld;
    });
  }

  String get title => _title;
  double get level => _gain;
  Duration get duration => _longestDuration;

  @override
  void initState() {
    String? initName = widget.trackName;
    _title = initName != null ? initName : widget.files[0].name;
    _gain = widget.level / 1.25;
    _controller.text = _title;
    _updateLongest();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
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
                  int index = int.parse(value.toString());
                  widget.files.removeAt(index);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 0),
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _gain,
              onChanged: (double value) {
                //TODO: handle changing audio levels during playback somehow
                // widget.player.setVolume(value * 1.25);
                setState(() {
                  _gain = value;
                });
              },
            ),
          ),
        ),
        SizedBox(
          height: 30.0,
        )
      ],
    );
  }
}
