import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:file_selector/file_selector.dart';

import 'package:multiplay/components/track.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:uuid/uuid.dart';

// import 'package:file_selector';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplay - Mixer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
          border: InputBorder.none,
          fillColor: Colors.white60,
          filled: true,
        ),
      ),
      home: MyHomePage(title: 'Multiplay - Mixer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _text = 'filepath';
  List<Track> _trackGroup = [];

  void _playTracks() {
    _trackGroup.forEach((element) {
      element.play();
    });
  }

  void _addTrack() async {
    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav']);
    final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.length <= 0) return;
    setState(() {
      _trackGroup.add(Track(files: files));
    });
  }

  void _importTracks() async {
    final typeGroup = XTypeGroup(label: 'multiplay', extensions: ['.multiplay']);
    final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);

  }

  void _exportTracks() async {
    final path = await getSavePath(suggestedName: "my_trackz.multiplay");
    if (path == null) return;

    final Map<String, dynamic> preferences = {'tracks': []};

    Directory tempDir = await getTemporaryDirectory();
    Directory sourceDir = await Directory('${tempDir.path}/Export-${Uuid().v1()}').create();

    final List<File> files = [];
    for (Track track in _trackGroup) {
      List<XFile> xFiles = track.files;
      preferences['tracks']
          .add({"name": track.trackName, "level": track.player.volume});

      for (XFile file in xFiles) {
        File toCopy = File(file.path);
        Directory subDir = Directory('${sourceDir.path}/${track.trackName}');
        if (!await subDir.exists()) await subDir.create();
        File copied = await toCopy.copy('${subDir.path}/${file.name}');
        files.add(copied);
      }
    }

    String json = jsonEncode(preferences);
    File jsonFile = await File('${sourceDir.path}/preferences.json').create();
    await jsonFile.writeAsString(json);

    files.add(jsonFile);

    final zipFile = File(path);

    try {
      await ZipFile.createFromFiles(
          sourceDir: sourceDir, files: files, zipFile: zipFile);
    } catch (e) {
      print(e);
    }

    print('deleting!');
    await sourceDir.delete(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: Color.fromRGBO(0, 0, 0, 0.08)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0.0, vertical: 25.0),
                  child: ListView(
                    children: <Widget>[
                      ..._trackGroup,
                      ...() {
                        List<Widget> notice = [];
                        if (_trackGroup.length == 0)
                          notice.add(
                            SizedBox(
                              height: 390.0,
                              child: Center(
                                child: Text(
                                  'Press the plus button to add a track!',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          );

                        return notice;
                      }()
                    ],
                  ),
                ),
                height: 440.0,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        children: [
          SizedBox(
            width: 30.0,
          ),
          FloatingActionButton(
            onPressed: _importTracks,
            tooltip: 'Open File',
            child: Icon(Icons.folder_open_rounded),
          ),
          SizedBox(
            width: 15.0,
          ),
          FloatingActionButton(
            onPressed: _exportTracks,
            tooltip: 'Export',
            child: Icon(Icons.save_alt_rounded),
          ),
          Spacer(),
          FloatingActionButton(
            onPressed: _playTracks,
            tooltip: 'Play',
            child: Icon(Icons.play_arrow),
          ),
          SizedBox(
            width: 15.0,
          ),
          FloatingActionButton(
            onPressed: _addTrack,
            tooltip: 'Add Track',
            child: Icon(Icons.add),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
