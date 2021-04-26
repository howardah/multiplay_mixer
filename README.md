# multiplay-mixer
 
Definitely a work in progress, this is currently something of a scratchpad for getting together a draft of an application which can handle the “Mixing & Mastering” of a variable audio file format. The idea is that you could record additional audio layers for a song which such that when you play back a random subsection of those layers then you have a slightly different piece every time. I'm currently using a matroska audio file \[.mka], which can support any number of layers and attachments, and providing it all of my audio and a .json file with “instructions” for file selection and eventually some sort of effects chain. There is also a repository for a [player application](https://github.com/howardah/multiplay) which is housing ideas about playing the file format.

Feel free to send PRs or write me with thoughts if you’re interested and/or have ideas about the project.

## Build

```
flutter pub get
flutter build macos
```

## Priority problems / to-do list

* ffmpeg, ffplay, and ffprobe all need to be downloaded in order to run the application. It would be far better if they could be bundled into the app. I have figured out how to bundle them but can’t seem to, using the flutter API, figure out how to programmatically locate the app itself in order to make use of the bundled CLI apps.
* Volume control during playback. Because playing the audio now happens in a single process_run shell, I'm not sure of the best way to make that happen. I want it to happen in a single process so that compression, eq, and other effects can be added and accurately monitored but I also think it would be good to be able to mix while listening.
* The goal is to do this with larger projects / full songs to get high variation (10 groups of 10 would yield 100 Billion combinations). Large files mean large filesizes. So I want to spend some solid time exporting the best codecs and settings optimize filesizes.
* The UI is a mess, but there especially needs to be more information about what’s happening in the application. Level meters, progress bars (for playback & exports), and menu items all need to happen.
* Saving / opening a file is not great. It’s just grouping the files and zipping them up to save, and unzipping them to open. (plus I’ve changed everything since I wrote the save and open functions, so they’re likely broken right now). Ideally I could save a project in a way that would be able to save and open quickly.
* It would be good to move the application state up and out of the ‘Track’ components so that I can add new views (especially effects chain views) without losing anything by navigating away from the Tracks.