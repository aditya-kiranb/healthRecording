import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RecordingScreen(),
    );
  }
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderReady = false;
  String? _filePath;
  final PlayerController _playerController = PlayerController();

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    await _recorder.openRecorder();
    _isRecorderReady = true;
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
  }

  void _startRecording() async {
    if (!_isRecorderReady) return;

    _filePath = '${Directory.systemTemp.path}/recording.wav';
    await _recorder.startRecorder(toFile: _filePath!);

    _recorder.onProgress!.listen((event) {
      if (event.decibels != null) {
        print("Decibels: ${event.decibels}"); // Debug log
      }
    });

    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() async {
    if (!_isRecorderReady) return;

    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    // Load the recorded file into the PlayerController
    if (_filePath != null) {
      await _playerController.preparePlayer(
          path: _filePath!); // Use named parameter
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Waveform Recorder')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _filePath != null
                  ? AudioFileWaveforms(
                      size: Size(MediaQuery.of(context).size.width, 200),
                      playerController: _playerController,
                      waveformType: WaveformType.fitWidth,
                    )
                  : const Text("No recording available"),
            ),
          ),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
        ],
      ),
    );
  }
}
