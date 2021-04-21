import 'package:flutter/cupertino.dart';
import 'package:multiplay/components/track.dart';

class TrackInstance {
  final Track track;
  final GlobalKey<TrackState> trackKey;
  TrackInstance({this.track, this.trackKey});
}