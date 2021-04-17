import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:process_run/shell.dart';
import 'package:file_selector/file_selector.dart';

import 'package:multiplay/components/track.dart';
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
      title: 'Flutter Demo',
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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });

    _playASound();
  }

  void _playASound() async {
    final AudioPlayer player = AudioPlayer();
    final AudioPlayer player2 = AudioPlayer();
    var shell = Shell();

    final typeGroup = XTypeGroup(label: 'audio', extensions: ['.mp3', '.wav']);
    final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);

    // await shell.run('''
    //
    // # Display some text
    // echo Hello
    //
    // # Display dart version
    // dart --version
    //
    // # Display pub version
    // pub --version
    //
    // ''');

    // await player.setAsset('assets/audio/op_bgclar1.mp3');
    await player.setFilePath(files[0].path);
    setState(() {
      _trackGroup.add(Track(files: files));
    });

    print('tell me more');
    // player2.play();
    // await player.play();

    // setState(() {
    //
    // _text = file.path;
    //
    // });
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ..._trackGroup,
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_text | $_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
