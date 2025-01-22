import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class RecordingPlaybackPage extends StatefulWidget {
  const RecordingPlaybackPage({super.key});

  @override
  State<RecordingPlaybackPage> createState() => _RecordingPlaybackPageState();
}

class _RecordingPlaybackPageState extends State<RecordingPlaybackPage> {
  List<FileSystemEntity> recordings = [];
  final AudioPlayer _player = AudioPlayer();
  String? currentlyPlayingPath;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    loadRecordings();
    _player.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        currentlyPlayingPath = null;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> loadRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .where((entity) => entity.path.endsWith('.wav'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    setState(() {
      recordings = files;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _togglePlayback(String filePath) async {
    if (currentlyPlayingPath == filePath && isPlaying) {
      await _player.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      if (currentlyPlayingPath != filePath) {
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.resume();
      }
      setState(() {
        currentlyPlayingPath = filePath;
        isPlaying = true;
      });
    }
  }

  Future<void> _deleteRecording(String filePath) async {
    if (currentlyPlayingPath == filePath) {
      await _player.stop();
      setState(() {
        currentlyPlayingPath = null;
        isPlaying = false;
      });
    }

    await File(filePath).delete();
    await loadRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadRecordings,
          ),
        ],
      ),
      body: recordings.isEmpty
          ? const Center(
              child: Text(
                'No recordings found',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final file = recordings[index];
                final stats = file.statSync();
                final fileName = file.path.split('/').last;
                final isCurrentlyPlaying = file.path == currentlyPlayingPath;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isCurrentlyPlaying && isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: isCurrentlyPlaying
                          ? Theme.of(context).primaryColor
                          : null,
                      size: 32,
                    ),
                    title: Text(fileName),
                    subtitle: Text(
                      '${_formatDateTime(stats.modified)}\n'
                      '${_formatFileSize(stats.size)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Recording'),
                            content: const Text(
                                'Are you sure you want to delete this recording?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteRecording(file.path);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () => _togglePlayback(file.path),
                  ),
                );
              },
            ),
    );
  }
}
