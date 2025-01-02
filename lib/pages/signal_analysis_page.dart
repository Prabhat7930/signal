import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signal/models/audio_recording_model.dart';

class SignalAnalysisPage extends StatefulWidget {
  final AudioRecordingModel recording;

  const SignalAnalysisPage({super.key, required this.recording});

  @override
  State<SignalAnalysisPage> createState() => _SignalAnalysisPageState();
}

class _SignalAnalysisPageState extends State<SignalAnalysisPage> {
  bool isLoading = true;
  List<FlSpot> amplitudeData = [];
  List<List<FlSpot>> spectrogramData = [];
  List<FlSpot> frequencyMagnitudeData = [];
  final int sampleRate = 44100;

  // Zoom control variables
  double _amplitudeZoom = 1.0;
  double _frequencyTimeZoom = 1.0;
  double _frequencyMagnitudeZoom = 1.0;

  @override
  void initState() {
    super.initState();
    analyzeAudio();
  }

  Future<void> analyzeAudio() async {
    try {
      final file = File(widget.recording.filePath);
      final bytes = await file.readAsBytes();

      final audioData = <double>[];
      for (int i = 44; i < bytes.length; i += 2) {
        final sample = ByteData.view(bytes.buffer).getInt16(i, Endian.little);
        audioData.add(sample / 32768.0);
      }

      // STFT parameters
      const chunkSize = 2048;
      const hopSize = 512; // Overlap between windows
      final stft = STFT(chunkSize, Window.hanning(chunkSize));
      final spectrogram = <Float64List>[];

      stft.run(audioData, (Float64x2List freq) {
        spectrogram.add(freq.discardConjugates().magnitudes());
      });

      // Process amplitude data
      for (int i = 0; i < audioData.length; i += 100) {
        amplitudeData.add(FlSpot(
          i / sampleRate,
          audioData[i],
        ));
      }

      // Process spectrogram data for frequency vs time visualization
      final timeStep = hopSize / sampleRate;
      for (int timeIdx = 0; timeIdx < spectrogram.length; timeIdx++) {
        final timePoint = timeIdx * timeStep;
        final frame = spectrogram[timeIdx];

        List<FlSpot> timeSlice = [];
        for (int freqIdx = 0; freqIdx < frame.length; freqIdx++) {
          final frequency = freqIdx * sampleRate / chunkSize;
          if (frequency < sampleRate / 2) {
            timeSlice.add(FlSpot(timePoint, frequency));
          }
        }
        spectrogramData.add(timeSlice);
      }

      // Process frequency vs magnitude data (using middle frame for stable representation)
      final middleFrame = spectrogram[spectrogram.length ~/ 2];
      for (int i = 0; i < middleFrame.length; i++) {
        final frequency = i * sampleRate / chunkSize;
        if (frequency < sampleRate / 2) {
          frequencyMagnitudeData.add(FlSpot(
            frequency,
            middleFrame[i],
          ));
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error analyzing audio: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildZoomableChart(Widget chart, double height, double zoom,
      Function(double) onZoomChanged) {
    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        onZoomChanged(zoom * details.scale);
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: height,
          width: 1000 * zoom,
          child: chart,
        ),
      ),
    );
  }

  Widget _buildGraphContainer(String title, Widget chart) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: chart,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signal Analysis')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildGraphContainer(
                    'Amplitude over Time',
                    _buildZoomableChart(
                      LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: amplitudeData,
                              isCurved: true,
                              color: Colors.blue,
                            ),
                          ],
                          titlesData: const FlTitlesData(
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text('Time (seconds)'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 0.5,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              axisNameWidget: Text('Amplitude'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 0.2,
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                      400,
                      _amplitudeZoom,
                      (zoom) => setState(() => _amplitudeZoom = zoom),
                    ),
                  ),
                  _buildGraphContainer(
                    'Frequency vs Time',
                    _buildZoomableChart(
                      LineChart(
                        LineChartData(
                          lineBarsData: spectrogramData
                              .map(
                                (timeSlice) => LineChartBarData(
                                  spots: timeSlice,
                                  isCurved: false,
                                  color: Colors.red.withOpacity(0.5),
                                  dotData: const FlDotData(show: false),
                                ),
                              )
                              .toList(),
                          titlesData: const FlTitlesData(
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text('Time (seconds)'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 0.5,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              axisNameWidget: Text('Frequency (Hz)'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                interval: 2000,
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                      400,
                      _frequencyTimeZoom,
                      (zoom) => setState(() => _frequencyTimeZoom = zoom),
                    ),
                  ),
                  _buildGraphContainer(
                    'Frequency vs Magnitude',
                    _buildZoomableChart(
                      LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: frequencyMagnitudeData,
                              isCurved: true,
                              color: Colors.green,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          titlesData: const FlTitlesData(
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text('Frequency (Hz)'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 2000,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              axisNameWidget: Text('Magnitude'),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 0.1,
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                      400,
                      _frequencyMagnitudeZoom,
                      (zoom) => setState(() => _frequencyMagnitudeZoom = zoom),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
