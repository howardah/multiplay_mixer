import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:multiplay_mixer/globals/common.dart';
import 'package:multiplay_mixer/models/mixer_state.dart';
import 'package:multiplay_mixer/models/track_models.dart';
import 'package:multiplay_mixer/tools/write_to_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:file_selector/file_selector.dart';

import 'package:multiplay_mixer/components/track.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:io';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => Mixer(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // print(context.watch<Mixer>().tracks.length);

    initializeApp();
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
        primarySwatch: Colors.teal,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
          border: InputBorder.none,
          fillColor: Colors.white60,
          filled: true,
        ),
        iconTheme: IconThemeData(),
      ),
      home: MyHomePage(title: 'Multiplay - Mixer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TrackInstance> _trackGroup = [];
  String _status = '';
  bool _playing = false;

  void _addTrack() async {
    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav', '.m4a']);
    final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.length <= 0) return;
    GlobalKey<TrackState> _keyChild = GlobalKey();

    Provider.of<Mixer>(context, listen: false).addTrack(TrackInstance(
        track: Track(
          key: _keyChild,
          files: files,
        ),
        trackKey: _keyChild));
  }

  void _importTracks() async {
    final typeGroup =
        XTypeGroup(label: 'multiplay', extensions: ['.multiplay']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    String project_name = file.name.replaceAll(RegExp(r".multiplay$"), '');

    Directory tempDir = await getTemporaryDirectory();
    Directory destinationDir =
        await Directory('${tempDir.path}/Import-$project_name-${Uuid().v1()}')
            .create();

    try {
      await ZipFile.extractToDirectory(
          zipFile: File(file.path),
          destinationDir: destinationDir,
          onExtracting: (zipEntry, progress) {
            // print('progress: ${progress.toStringAsFixed(1)}%');
            // print('name: ${zipEntry.name}');
            // print('isDirectory: ${zipEntry.isDirectory}');
            // print(
            //     'modificationDate: ${zipEntry.modificationDate.toLocal().toIso8601String()}');
            // print('uncompressedSize: ${zipEntry.uncompressedSize}');
            // print('compressedSize: ${zipEntry.compressedSize}');
            // print('compressionMethod: ${zipEntry.compressionMethod}');
            // print('crc: ${zipEntry.crc}');
            return ExtractOperation.extract;
          });
    } catch (e) {
      print(e);
    }

    File jsonFile = File('${destinationDir.path}/preferences.json');
    if (!await jsonFile.exists()) return;

    Map<String, dynamic> preferences =
        await jsonDecode(await jsonFile.readAsString());
    print(preferences);

    List<TrackInstance> trackGroup = [];

    for (String key in preferences.keys) {
      if (key == "tracks") {
        List<dynamic> tracks = preferences[key];
        for (Map track in tracks) {
          List<XFile> fileList = [];
          Directory trackDir =
              Directory('${destinationDir.path}/${track["name"]}');
          if (await trackDir.exists()) {
            List<FileSystemEntity> files = trackDir.listSync();
            files.forEach((file) {
              if (file.runtimeType.toString() == "_File") {
                XFile audioFile = XFile(file.path);
                print(audioFile.name);
                fileList.add(audioFile);
              }
            });

            if (fileList.isEmpty) continue;

            GlobalKey<TrackState> trackKey = GlobalKey();
            double trackLevel = track["level"] is double ? track["level"] : 1.0;
            trackGroup.add(
              TrackInstance(
                  track: Track(
                    key: trackKey,
                    files: fileList,
                    level: trackLevel,
                    trackName: track["name"],
                  ),
                  trackKey: trackKey),
            );
          }
        }
      }
    }

    trackGroup.forEach((element) {
      print(element.track.trackName);
      print(element.track.files);
      print(element.trackKey);
    });
    // print(trackGroup);

    setState(() {
      _trackGroup = trackGroup;
    });
  }

  void _saveProject() async {
    final path = await getSavePath(suggestedName: "my_trackz.multiplay");
    if (path == null) return;

    final Map<String, dynamic> preferences = {'tracks': []};

    Directory tempDir = await getTemporaryDirectory();
    Directory sourceDir =
        await Directory('${tempDir.path}/Export-${Uuid().v1()}').create();

    final List<File> files = [];
    for (TrackInstance track in _trackGroup) {
      List<XFile> xFiles = track.track.files;
      double? level = track.trackKey.currentState?.level;
      preferences['tracks'].add(
          {"name": track.track.trackName, "level": (level != null ? level : 1.0)});

      for (XFile file in xFiles) {
        File toCopy = File(file.path);
        Directory subDir =
            Directory('${sourceDir.path}/${track.track.trackName}');
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

    setState(() {
      _status = "Zipping!";
    });
    try {
      await ZipFile.createFromFiles(
          sourceDir: sourceDir, files: files, zipFile: zipFile);
    } catch (e) {
      print(e);
    }
    setState(() {
      _status = "";
    });

    print('deleting!');
    await sourceDir.delete(recursive: true);
  }

  void _exportTracks() async {
    final path = await getSavePath(suggestedName: "project_name.mka");
    if (path == null) return;
    final File outFile = File(path);

    Directory tempDir = await getTemporaryDirectory();
    Directory sourceDir =
        await Directory('${tempDir.path}/Export-${Uuid().v1()}').create();

    setState(() {
      _status = "Exporting!";
    });

    String shellCommand = await Provider.of<Mixer>(context, listen: false)
        .exportString(outFile, sourceDir);
    await shell.run(shellCommand);

    print('deleting!');
    setState(() {
      _status = "";
    });

    await sourceDir.delete(recursive: true);
  }

  void _shellFunction() async {
    // var ffmpeg = await Cachin('assets/ffmpeg');
    var controller = ShellLinesController();
    var shell = Shell(stdout: controller.sink, verbose: false);

    var shellStream = controller.stream.listen((event) {
      print(event);
    });

    shell = shell.cd(toolsDir.path);

    ByteData exportBytes =
        await rootBundle.load('assets/audio/export_mega.mka');
    await writeToFile(exportBytes, '${cacheDir.path}/export_mega.mka');
    File audioFile = File('${cacheDir.path}/export_mega.mka');
    // await audioFile.create();

    await shell.run(
        './ffmpeg -i "${audioFile.path}" -filter_complex "[m:piano:1] [m:clar:2] amerge" -vn -ar 44100 -ac 2 -b:a 192k "${cacheDir.path}/output.mp3"');

    shellStream.cancel();
  }

  void _reOrder(oldIndex, newIndex) {
    int trackLength = _trackGroup.length;
    int index = newIndex >= trackLength ? (trackLength - 1) : newIndex;
    TrackInstance moving = _trackGroup.removeAt(oldIndex);
    _trackGroup.insert(index, moving);
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
                      horizontal: 10.0, vertical: 25.0),
                  child: () {
                    if (context.watch<Mixer>().tracks.length == 0) {
                      return SizedBox(
                        height: 390.0,
                        child: Center(
                          child: Text(
                            'Press the plus button to add a track!',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    }
                    return ReorderableListView.builder(
                      onReorder:
                          Provider.of<Mixer>(context, listen: false).moveTrack,
                      itemCount: context.watch<Mixer>().tracks.length,
                      itemBuilder: (context, index) {
                        TrackInstance ti = context.watch<Mixer>().tracks[index];
                        // return ti.track;
                        return Row(
                          key: ValueKey(ti),
                          children: [
                            SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 150),
                                child: ti.track),
                            SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    Provider.of<Mixer>(context, listen: false).removeTrack(index);
                                  });
                                },
                                icon: Icon(Icons.cancel),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }(),
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
            onPressed: _saveProject,
            tooltip: 'Save File',
            child: Icon(Icons.save_rounded),
          ),
          SizedBox(
            width: 15.0,
          ),
          FloatingActionButton(
            onPressed: _exportTracks,
            tooltip: 'Export',
            child: Icon(Icons.save_alt_rounded),
          ),
          SizedBox(
            width: 15.0,
          ),
          Text(_status),
          Spacer(),
          FloatingActionButton(
            onPressed: _shellFunction,
            tooltip: 'Shell Attempt',
            child: Icon(Icons.code),
          ),
          SizedBox(
            width: 15.0,
          ),
          FloatingActionButton(
            onPressed: () {
              Provider.of<Mixer>(context, listen: false).play();
              setState(() {
                _playing = true;
              });
            },
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
