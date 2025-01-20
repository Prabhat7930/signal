import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_filter.dart';
import 'recording_playback_page.dart';
import 'comparison_playback_page.dart';


class SignalAnalysisPage extends StatefulWidget {
  final String filePath;

  const SignalAnalysisPage({Key? key, required this.filePath}) : super(key: key);

  @override
  State<SignalAnalysisPage> createState() => _SignalAnalysisPageState();
}

class _SignalAnalysisPageState extends State<SignalAnalysisPage> {
  bool isLoading = true;
  int currentGraphIndex = 0;
  List<FlSpot> amplitudeData = [];
  List<FlSpot> frequencyMagnitudeData = [];
  final int sampleRate = 44100;
  double minY = 0;
  double maxY = 0;

  @override
  void initState() {
    super.initState();
    analyzeAudio();
  }

  Future<void> analyzeAudio() async {
    setState(() => isLoading = true);
    try {
      // Read audio file and convert to samples
      final file = File(widget.filePath);
      final bytes = await file.readAsBytes();
      
      // Convert bytes to audio samples (simplified for example)
      final audioData = List.generate(
        bytes.length ~/ 2, 
        (i) => bytes[i * 2] / 128.0
      );

      // Generate amplitude data
      amplitudeData = List.generate(
        audioData.length,
        (i) => FlSpot(i / sampleRate, audioData[i])
      );

      // Compute FFT for frequency data
      final fftData = AudioFilter.computeFFT(audioData);
      final fftMagnitude = fftData.map((complex) => 
        sqrt(complex.real * complex.real + complex.imag * complex.imag)
      ).toList();

      // Generate frequency magnitude data
      frequencyMagnitudeData = List.generate(
        fftMagnitude.length ~/ 2,
        (i) => FlSpot(
          i * sampleRate / fftMagnitude.length,
          fftMagnitude[i]
        )
      );

      // Calculate min and max Y values for scaling
      minY = amplitudeData.map((spot) => spot.y).reduce(min);
      maxY = amplitudeData.map((spot) => spot.y).reduce(max);

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error analyzing audio: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signal Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.landscape
              ? _buildLandscapeLayout()
              : _buildPortraitLayout();
        },
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildGraph(),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGraphControls(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: _buildGraph(),
        ),
        _buildGraphControls(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildGraph() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentData = currentGraphIndex == 0 
        ? amplitudeData 
        : frequencyMagnitudeData;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: currentData,
              isCurved: true,
              color: currentGraphIndex == 0 ? Colors.blue : Colors.green,
              dotData: FlDotData(show: currentGraphIndex == 0),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minY: currentGraphIndex == 0 ? minY : 0,
          maxY: currentGraphIndex == 0 ? maxY : null,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
              axisNameWidget: Text(
                currentGraphIndex == 0 ? 'Amplitude' : 'Magnitude',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (currentGraphIndex == 0) {
                    return Text(
                      '${(value).toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 10),
                    );
                  } else {
                    return Text(
                      '${(value / 1000).toStringAsFixed(1)}kHz',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                },
                reservedSize: 30,
              ),
              axisNameWidget: Text(
                currentGraphIndex == 0 ? 'Time (s)' : 'Frequency (Hz)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => currentGraphIndex = (currentGraphIndex - 1).clamp(0, 1));
              },
            ),
            Expanded(
              child: Text(
                currentGraphIndex == 0 
                  ? 'Amplitude vs Time' 
                  : 'Frequency vs Magnitude',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() => currentGraphIndex = (currentGraphIndex + 1) % 2);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text('Apply Filters'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilterPage(
                      originalFilePath: widget.filePath,
                      sampleRate: sampleRate,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.playlist_play),
              label: const Text('View Recordings'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordingPlaybackPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterPage extends StatefulWidget {
  final String originalFilePath;
  final int sampleRate;

  const FilterPage({
    Key? key,
    required this.originalFilePath,
    required this.sampleRate,
  }) : super(key: key);

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final TextEditingController lowFreqController = TextEditingController();
  final TextEditingController highFreqController = TextEditingController();
  bool isProcessing = false;

  @override
  void dispose() {
    lowFreqController.dispose();
    highFreqController.dispose();
    super.dispose();
  }

  Future<void> applyFilter() async {
    final low = double.tryParse(lowFreqController.text);
    final high = double.tryParse(highFreqController.text);
    
    if (low == null || high == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid frequencies')),
      );
      return;
    }
    
    if (low >= high) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lower frequency must be less than higher frequency'),
        ),
      );
      return;
    }

    setState(() => isProcessing = true);
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/filtered_$timestamp.wav';
      
      final filteredPath = await AudioFilter.applyBandPassFilter(
        inputPath: widget.originalFilePath,
        outputPath: outputPath,
        lowFreq: low,
        highFreq: high,
        sampleRate: widget.sampleRate,
      );

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComparisonPlaybackPage(
            originalFilePath: widget.originalFilePath,
            filteredFilePath: filteredPath,
            filterDetails: 'Band-Pass Filter ($low Hz - $high Hz)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying filter: $e')),
      );
    } finally {
      setState(() => isProcessing = false);
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
              controller: lowFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lower Frequency (Hz)',
                border: OutlineInputBorder(),
                helperText: 'Minimum frequency to keep',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: highFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Higher Frequency (Hz)',
                border: OutlineInputBorder(),
                helperText: 'Maximum frequency to keep',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.filter_alt),
              label: Text(isProcessing ? 'Processing...' : 'Apply Band-Pass Filter'),
              onPressed: isProcessing ? null : applyFilter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}