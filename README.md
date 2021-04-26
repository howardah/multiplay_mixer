# multiplay-mixer
 
Definitely a work in progress, this is currently something of a scratchpad for getting together a draft of an application which can handle the “Mixing & Mastering” of a (near) infinitely variable file format (a matroska \[.mka] file organized/authored with a specific structure) in which I plan to prepare and release my next project. There is also a repository for a [player application](https://github.com/howardah/multiplay) which is housing ideas about playing the file format.

Feel free to send PRs or write me with thoughts if you’re interested and/or have ideas about the project.

```
flutter pub get
flutter build macos
```

## Priority problems

* ffmpeg, ffplay, and ffprobe all need to be downloaded in order to run the application. It would be far better if they could be bundled into the app. I have figured out how to bundle them but can’t seem to, using the flutter API, figure out how to programmatically locate the app itself in order to make use of the bundled CLI apps.
* Volume control during playback. Because playing the audio now happens in a single process_run shell, I'm not sure of the best way to make that happen. I want it to happen in a single process so that compression, eq, and other effects can be added and accurately monitored but I also think it would be good to be able to mix while listening.