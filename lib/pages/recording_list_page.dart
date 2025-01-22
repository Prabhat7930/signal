import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signal/components/appbar.dart';
import 'package:signal/pages/signal_analysis_page.dart';
import 'package:signal/provider/audio_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingPath;
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String filePath) async {
    if (_currentlyPlayingPath == filePath && _isPlaying) {
      await _player.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (_currentlyPlayingPath != filePath) {
        await _player.stop();
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.resume();
      }
      if (mounted) {
        setState(() {
          _currentlyPlayingPath = filePath;
          _isPlaying = true;
        });
      }
    }
  }

  Future<void> _stopPlayback() async {
    if (_isPlaying) {
      await _player.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _navigateToSignalAnalysis(String filePath) async {
    await _stopPlayback();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignalAnalysisPage(filePath: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarComponent("Recordings"),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
            ],
          ),
        ),
        child: Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return audioProvider.recordings.isEmpty
                ? const Center(
                    child: Text(
                      'No recordings yet.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    itemCount: audioProvider.recordings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final recording = audioProvider.recordings[index];
                      final isCurrentlyPlaying =
                          _currentlyPlayingPath == recording.filePath &&
                              _isPlaying;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: IconButton(
                            icon: Icon(
                              isCurrentlyPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: isCurrentlyPlaying
                                  ? Theme.of(context).primaryColor
                                  : Colors.blueGrey,
                              size: 32,
                            ),
                            onPressed: () =>
                                _togglePlayback(recording.filePath),
                          ),
                          title: Text(
                            recording.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy - h:mm a')
                                .format(recording.createdAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                _navigateToSignalAnalysis(recording.filePath),
                          ),
                        ),
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 300),
                          );
                    },
                  );
          },
        ),
      ),
    );
  }
}
