import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signal/pages/signal_analysis_page.dart';
import 'package:signal/provider/audio_provider.dart';

class RecordListPage extends StatelessWidget {
  const RecordListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return ListView.builder(
            itemCount: audioProvider.recordings.length,
            itemBuilder: (context, index) {
              final recording = audioProvider.recordings[index];
              return ListTile(
                leading: const Icon(Icons.audio_file),
                title: Text(recording.title),
                subtitle: Text(recording.createdAt.toString()),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SignalAnalysisPage(recording: recording),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
