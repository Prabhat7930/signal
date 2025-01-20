// comparison_playback_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ComparisonPlaybackPage extends StatefulWidget {
  final String originalFilePath;
  final String filteredFilePath;
  final String filterDetails;

  const ComparisonPlaybackPage({
    Key? key,
    required this.originalFilePath,
    required this.filteredFilePath,
    required this.filterDetails,
  }) : super(key: key);

  @override
  State<ComparisonPlaybackPage> createState() => _ComparisonPlaybackPageState();
}

class _ComparisonPlaybackPageState extends State<ComparisonPlaybackPage> {
  final AudioPlayer _originalPlayer = AudioPlayer();
  final AudioPlayer _filteredPlayer = AudioPlayer();
  bool _isOriginalPlaying = false;
  bool _isFilteredPlaying = false;
  double _originalProgress = 0.0;
  double _filteredProgress = 0.0;
  Duration _originalDuration = Duration.zero;
    Duration _filteredDuration = Duration.zero;


  @override
  void initState() {
    super.initState();
    _setupPlayers();
  }
  

  Future<void> _setupPlayers() async {
    try {
      await _originalPlayer.setSource(DeviceFileSource(widget.originalFilePath));
      await _filteredPlayer.setSource(DeviceFileSource(widget.filteredFilePath));

       // Get the duration for each player
      _originalDuration = (await _originalPlayer.getDuration()) ?? Duration.zero;
      _filteredDuration = (await _filteredPlayer.getDuration()) ?? Duration.zero;
      
       _originalPlayer.onPositionChanged.listen((position) {
        if(mounted){
          setState(() {
              _originalProgress = position.inMilliseconds / _originalDuration.inMilliseconds;
              });
          }
      });

      _filteredPlayer.onPositionChanged.listen((position) {
        if(mounted){
        setState(() {
            _filteredProgress = position.inMilliseconds / _filteredDuration.inMilliseconds;
        });
        }
      });

      _originalPlayer.onPlayerComplete.listen((event) {
        if(mounted){
          setState(() {
            _isOriginalPlaying = false;
            _originalProgress = 0.0;
            });
        }
      });
      _filteredPlayer.onPlayerComplete.listen((event) {
         if(mounted){
          setState(() {
            _isFilteredPlaying = false;
            _filteredProgress = 0.0;
          });
        }
      });


     
      
    } catch (e) {
      debugPrint('Error setting up audio players: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up audio players: $e')));
    }
  }

  @override
  void dispose() {
    _originalPlayer.dispose();
    _filteredPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayOriginal() async {
      if (_isOriginalPlaying) {
      await _originalPlayer.pause();
    } else {
      await _originalPlayer.resume();
    }
     if (mounted) {
      setState(() {
          _isOriginalPlaying = !_isOriginalPlaying;
        });
    }

  }

  Future<void> _togglePlayFiltered() async {
    if (_isFilteredPlaying) {
      await _filteredPlayer.pause();
    } else {
      await _filteredPlayer.resume();
    }
     if (mounted) {
      setState(() {
        _isFilteredPlaying = !_isFilteredPlaying;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Comparison')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Details: ${widget.filterDetails}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Original Audio:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
              _buildAudioPlayerControls(
                playerType: 'Original',
              ),
                const SizedBox(height: 24),
                const Text(
                'Filtered Audio:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
               _buildAudioPlayerControls(
                playerType: 'Filtered',
              ),
          ],
        ),
      ),
    );
  }


   Widget _buildAudioPlayerControls({required String playerType}) {
      bool isPlaying;
      double progress;
       VoidCallback togglePlay;

      if(playerType == "Original"){
          isPlaying = _isOriginalPlaying;
          progress = _originalProgress;
           togglePlay = _togglePlayOriginal;
      }else{
         isPlaying = _isFilteredPlaying;
          progress = _filteredProgress;
           togglePlay = _togglePlayFiltered;
      }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 50,
              onPressed: togglePlay,
            ),
          ],
        ),
        Slider(
          value: progress,
          onChanged: (value) {
              // do nothing
          },
        ),
      ],
    );
  }


}