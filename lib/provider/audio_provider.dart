import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:signal/models/audio_recording_model.dart';

class AudioProvider extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  List<AudioRecordingModel> recordings = [];
  bool isRecording = false;
  static const String _storageKey = 'audio_recordings';
  late SharedPreferences _prefs;

  AudioProvider() {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    _prefs = await SharedPreferences.getInstance();
    await loadRecordings();
  }

  Future<void> loadRecordings() async {
    try {
      final recordingsJson = _prefs.getStringList(_storageKey) ?? [];
      recordings = recordingsJson
          .map((json) => AudioRecordingModel.fromJson(jsonDecode(json)))
          .where((recording) {
        // Verify if the file still exists
        final file = File(recording.filePath);
        return file.existsSync();
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }
  }

  Future<void> _saveRecordingsMetadata() async {
    try {
      final recordingsJson = recordings
          .map((recording) => jsonEncode(recording.toJson()))
          .toList();
      await _prefs.setStringList(_storageKey, recordingsJson);
    } catch (e) {
      debugPrint('Error saving recordings metadata: $e');
    }
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return '${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final filePath = await _getRecordingPath();

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final recording = AudioRecordingModel(
          id: DateTime.now().toString(),
          title: 'Recording ${recordings.length + 1}',
          filePath: path,
          createdAt: DateTime.now(),
        );
        recordings.add(recording);
        await _saveRecordingsMetadata();
        isRecording = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> deleteRecording(AudioRecordingModel recording) async {
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      recordings.removeWhere((r) => r.id == recording.id);
      await _saveRecordingsMetadata();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
