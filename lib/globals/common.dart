library multiplay_mixer.common;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

String appTitle = 'Multiplay Mixer';
bool isConnected = false;
Directory toolsDir = Directory('Users/Shared/Multiplay/Tools');
Directory cacheDir = Directory('Users/Shared/Multiplay/Cache');

final controller = ShellLinesController();
Shell shell = Shell(stdout: controller.sink, verbose: false);

String cleanPath(String path) {
  RegExp unEscapedSpaces = RegExp(r'(?<!\\) ');
  return path.replaceAll(unEscapedSpaces, '\\ ');
}

Future<String> initializeApp() async {
  toolsDir = Directory(
      '${(await getLibraryDirectory()).path}/Application Support/Multiplay/Tools');
  cacheDir = Directory(
      '${(await getLibraryDirectory()).path}/Application Support/Multiplay/Cache');
  isConnected = await checkConnection();

  if (!(await toolsDir.exists())) await toolsDir.create(recursive: true);
  if (!(await cacheDir.exists())) await cacheDir.create(recursive: true);

  shell = shell.cd(toolsDir.path);

  File ffmpeg = File('${toolsDir.path}/ffmpeg');
  if (!(await ffmpeg.exists())) {
    if (!isConnected)
      return '$appTitle needs to download dependencies in order to run. Please connect to the internet and reopen the application';
    await shell
        .run(curlUnZip('ffmpeg', 'https://evermeet.cx/ffmpeg/ffmpeg-4.4.zip'));
  }

  File ffplay = File('${toolsDir.path}/ffplay');
  if (!(await ffplay.exists())) {
    if (!isConnected)
      return '$appTitle needs to download dependencies in order to run. Please connect to the internet and reopen the application';
    await shell
        .run(curlUnZip('ffplay', 'https://evermeet.cx/ffmpeg/ffplay-4.4.zip'));
  }

  return 'status: done';
}

Future<bool> checkConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}

String curlUnZip(String appName, String url) {
  RegExp zipExp = RegExp(r"[^/]*.zip$");
  RegExpMatch? nameMatch = zipExp.firstMatch(url);
  String filename = nameMatch != null ? (nameMatch.group(0)).toString() : '';

  return '''
        curl -O $url
        unzip $filename
        rm -f $filename
        chmod +x ./$appName
      ''';
}
