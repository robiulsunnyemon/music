

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  AudioPlayerScreenState createState() => AudioPlayerScreenState();
}

class AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final VolumeController volumeController=VolumeController.instance;


  bool isPlaying = false;
  double fixedVolume = 0.8; // Fixed volume level (0.0 - 1.0)
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initVolumeControl();
    // Register hardware key event handler
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    audioPlayer.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _resetToFixedVolume();
        return true; // Prevent default behavior
      }
    }
    return false;
  }

  Future<void> _initAudio() async {
    // Player state listeners
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => isPlaying = state == PlayerState.playing);
      }
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => duration = newDuration);
      }
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => position = newPosition);
      }
    });
  }

  Future<void> _initVolumeControl() async {

    // Set initial fixed volume
    await audioPlayer.setVolume(fixedVolume);
    await volumeController.setVolume(fixedVolume);

    // Listen for system volume changes
    volumeController.addListener((volume) {
      if (volume != fixedVolume) {
        _resetToFixedVolume();
      }
    });
  }

  Future<void> _resetToFixedVolume() async {
    await audioPlayer.setVolume(fixedVolume);
    await volumeController.setVolume(fixedVolume);
  }

  Future<void> playAudio() async {
    try {
      await audioPlayer.play(AssetSource('audio/audio.mp3'));
      await _resetToFixedVolume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    await audioPlayer.pause();
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Volume MP3 Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble(),
              onChanged: (value) async {
                await audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(position)),
                  Text(formatTime(duration - position)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  iconSize: 48,
                  onPressed: playAudio,
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  iconSize: 48,
                  onPressed: pauseAudio,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  iconSize: 48,
                  onPressed: stopAudio,
                ),
              ],
            ),
            Text(
              isPlaying ? 'Playing' : 'Paused',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Volume: ${(fixedVolume * 100).toInt()}% (Fixed)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }
}