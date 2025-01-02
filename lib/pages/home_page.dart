import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signal/provider/audio_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Center(
        child: Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  audioProvider.isRecording ? Icons.mic : Icons.mic_none,
                  size: 50,
                  color: audioProvider.isRecording ? Colors.red : Colors.grey,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (audioProvider.isRecording) {
                      audioProvider.stopRecording();
                    } else {
                      audioProvider.startRecording();
                    }
                  },
                  child: Text(audioProvider.isRecording
                      ? 'Stop Recording'
                      : 'Start Recording'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/recordings');
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View Recordings'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
