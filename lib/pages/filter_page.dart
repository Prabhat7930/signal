import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_filter.dart';
import 'comparison_playback_page.dart';
import 'dart:typed_data';

class FilterPage extends StatefulWidget {
  final String originalFilePath;
  final int sampleRate;

  const FilterPage({
    super.key,
    required this.originalFilePath,
    required this.sampleRate,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final TextEditingController _lowFreqController = TextEditingController();
  final TextEditingController _highFreqController = TextEditingController();
  String? _processedFilePath;
  bool _isFiltering = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> _applyBandPassFilter(double lowFreq, double highFreq) async {
    setState(() => _isFiltering = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFilePath = '${directory.path}/bandpass_$timestamp.wav';

      final filteredDoubleAudio = await AudioFilter.applyBandPassFilter(
          inputPath: widget.originalFilePath,
          outputPath: newFilePath,
          lowFreq: lowFreq,
          highFreq: highFreq,
          sampleRate: widget.sampleRate);

      return filteredDoubleAudio;
    } catch (e) {
      debugPrint('Error applying band-pass filter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying band-pass filter: $e')));
      return null;
    } finally {
      setState(() => _isFiltering = false);
    }
  }

  Future<String?> _applyBandStopFilter(double lowFreq, double highFreq) async {
    setState(() => _isFiltering = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFilePath = '${directory.path}/bandstop_$timestamp.wav';
      final audioBytes = await File(widget.originalFilePath).readAsBytes();
      final audioData =
          await compute(_decodeAudio, audioBytes.buffer.asInt16List());
      if (audioData == null) {
        throw Exception("Error Decoding the audio file");
      }
      final filteredAudio = await AudioFilter.applyBandStopFilter(
        audioData,
        widget.sampleRate,
        lowFreq,
        highFreq,
      );

      final filteredBytes = Int16List.fromList(filteredAudio
              .map((e) => (e * 32768).round().clamp(-32768, 32767).toInt())
              .toList())
          .buffer
          .asUint8List();
      await File(newFilePath).writeAsBytes(filteredBytes);
      return newFilePath;
    } catch (e) {
      debugPrint('Error applying band-stop filter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying band-stop filter: $e')));
      return null;
    } finally {
      setState(() => _isFiltering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Filters')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _lowFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lower Frequency (Hz)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _highFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Higher Frequency (Hz)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text('Apply Band-Pass Filter'),
              onPressed: _isFiltering
                  ? null
                  : () async {
                      final low = double.tryParse(_lowFreqController.text) ?? 0;
                      final high = double.tryParse(_highFreqController.text) ??
                          widget.sampleRate / 2;

                      if (low >= high) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Lower frequency must be less than higher frequency')),
                        );
                        return;
                      }

                      _processedFilePath =
                          await _applyBandPassFilter(low, high);
                      if (_processedFilePath != null) {
                        _navigateToComparisonPage(low, high, 'Band-Pass');
                      }
                    },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text('Apply Band-Stop Filter'),
              onPressed: _isFiltering
                  ? null
                  : () async {
                      final low = double.tryParse(_lowFreqController.text) ?? 0;
                      final high = double.tryParse(_highFreqController.text) ??
                          widget.sampleRate / 2;

                      if (low >= high) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Lower frequency must be less than higher frequency')),
                        );
                        return;
                      }

                      _processedFilePath =
                          await _applyBandStopFilter(low, high);
                      if (_processedFilePath != null) {
                        _navigateToComparisonPage(low, high, 'Band-Stop');
                      }
                    },
            ),
            if (_isFiltering)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToComparisonPage(double low, double high, String filterType) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonPlaybackPage(
          originalFilePath: widget.originalFilePath,
          filteredFilePath: _processedFilePath!,
          filterDetails: '$filterType Filter ($low Hz - $high Hz)',
        ),
      ),
    );
  }
}

// Helper function for background decoding
List<int>? _decodeAudio(List<int> bytes) {
  try {
    final buffer = Int16List.fromList(bytes);
    return buffer.toList();
  } catch (e) {
    return null;
  }
}
