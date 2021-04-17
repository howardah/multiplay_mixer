import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class Track extends StatefulWidget {
  Track({Key key, @required this.files}) : super(key: key);

  final List<XFile> files;

  @override
  _TrackState createState() => _TrackState();
}

class _TrackState extends State<Track> {
  double _gain = 0.2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(widget.files[0].name)
          ],
        ),
        Slider(value: _gain, onChanged: (double value){
          print(value);
          setState(() {
            _gain = value;
          });
        }),
      ],
    );
  }
}
