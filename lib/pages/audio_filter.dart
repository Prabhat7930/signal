import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';

class AudioFilter {
  static Future<String> applyBandPassFilter({
    required String inputPath,
    required String outputPath,
    required double lowFreq,
    required double highFreq,
    required int sampleRate,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    // Convert bytes to audio samples
    final samples = _bytesToSamples(bytes);

    // Apply FFT
    final fftData = computeFFT(samples);

    // Apply band-pass filter in frequency domain
    final filteredFFT = _applyBandPass(
      fftData,
      lowFreq,
      highFreq,
      sampleRate,
    );

    // Inverse FFT
    final filteredSamples = _computeInverseFFT(filteredFFT);

    // Convert samples back to bytes
    final outputBytes = _samplesToBytes(filteredSamples);

    // Save filtered audio
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(outputBytes);

    return outputPath;
  }

 static Future<List<double>> applyBandStopFilter(
      List<int> samples,
      int sampleRate,
      double lowFreq,
      double highFreq,
  ) async {
    // Convert samples to double
    final doubleSamples = samples.map((e) => e.toDouble() / 32768).toList();
    // Apply FFT
    final fftData = computeFFT(doubleSamples);

    // Apply band-stop filter in frequency domain
    final filteredFFT = _applyBandStop(
      fftData,
      lowFreq,
      highFreq,
      sampleRate,
    );

    // Inverse FFT
    final filteredSamples = _computeInverseFFT(filteredFFT);

    return filteredSamples;
  }


  static List<double> _bytesToSamples(List<int> bytes) {
    final samples = <double>[];
    for (var i = 44; i < bytes.length; i += 2) {
      // Skip 44-byte WAV header
      final sample = bytes[i] | (bytes[i + 1] << 8);
      samples.add(sample / 32768.0); // Convert to float between -1 and 1
    }
    return samples;
  }

  static List<int> _samplesToBytes(List<double> samples) {
    final bytes = <int>[];

    // Add WAV header (44 bytes)
    bytes.addAll(_createWavHeader(samples.length));

    // Add sample data
    for (var sample in samples) {
      final intSample = (sample * 32768).round().clamp(-32768, 32767);
      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return bytes;
  }

  static List<int> _createWavHeader(int samplesLength) {
     final header = ByteData(44);
    final int fileSize =
        samplesLength * 2 + 36; // File size minus 8 bytes for header

    // RIFF chunk descriptor
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF" in ASCII
    header.setUint32(4, fileSize, Endian.little); // File size minus 8 bytes
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE" in ASCII

    // "fmt " sub-chunk
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt " in ASCII
    header.setUint32(16, 16, Endian.little); // Sub-chunk size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // Audio format (1 for PCM)
    header.setUint16(22, 1, Endian.little); // Number of channels
    header.setUint32(24, 44100, Endian.little); // Sample rate
    header.setUint32(28, 88200, Endian.little); // Byte rate
    header.setUint16(32, 2, Endian.little); // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample

    // "data" sub-chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data" in ASCII
    header.setUint32(40, samplesLength * 2, Endian.little); // Data size

    return header.buffer.asUint8List();
  }

  // In audio_filter.dart, add these public methods:

  static List<Complex> computeFFT(List<double> samples) {
    final n = _nextPowerOf2(samples.length);
    final paddedSamples = List<double>.from(samples)
      ..addAll(List<double>.filled(n - samples.length, 0));

    final fft = List<Complex>.generate(
      n,
      (i) => Complex(paddedSamples[i], 0),
    );

    _fft(fft, false);
    return fft;
  }

  static List<double> computeMagnitudes(List<Complex> fftData) {
    return fftData
        .map((complex) => math
            .sqrt(complex.real * complex.real + complex.imag * complex.imag))
        .toList();
  }

  static List<double> readAudioFile(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    return _bytesToSamples(bytes);
  }

  static List<double> _computeInverseFFT(List<Complex> fftData) {
    final n = fftData.length;
    final ifft = List<Complex>.from(fftData);

    _fft(ifft, true);

    return List<double>.generate(
      n,
      (i) => ifft[i].real / n,
    );
  }

    static List<Complex> _applyBandStop(
    List<Complex> fftData,
    double lowFreq,
    double highFreq,
    int sampleRate,
  ) {
    final n = fftData.length;
    final result = List<Complex>.from(fftData);

    for (var i = 0; i < n; i++) {
      final freq = i * sampleRate / n;
      if (freq >= lowFreq && freq <= highFreq) {
        result[i] = Complex(0, 0);
      }
    }
    return result;
  }


  static List<Complex> _applyBandPass(
    List<Complex> fftData,
    double lowFreq,
    double highFreq,
    int sampleRate,
  ) {
    final n = fftData.length;
    final result = List<Complex>.from(fftData);

    for (var i = 0; i < n; i++) {
      final freq = i * sampleRate / n;
      if (freq < lowFreq || freq > highFreq) {
        result[i] = Complex(0, 0);
      }
    }

    return result;
  }

  static void _fft(List<Complex> data, bool inverse) {
    final n = data.length;
    if (n <= 1) return;

    final even = List<Complex>.generate(n ~/ 2, (i) => data[2 * i]);
    final odd = List<Complex>.generate(n ~/ 2, (i) => data[2 * i + 1]);

    _fft(even, inverse);
    _fft(odd, inverse);

    final angle = 2 * math.pi / n * (inverse ? -1 : 1);
    var w = Complex(1, 0);
    final wn = Complex(math.cos(angle), math.sin(angle));

    for (var k = 0; k < n ~/ 2; k++) {
      final t = w * odd[k];
      data[k] = even[k] + t;
      data[k + n ~/ 2] = even[k] - t;
      w *= wn;
    }
  }

  static int _nextPowerOf2(int n) {
    var power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }
}

class Complex {
  final double real;
  final double imag;

  Complex(this.real, this.imag);

  Complex operator +(Complex other) => Complex(
        real + other.real,
        imag + other.imag,
      );

  Complex operator -(Complex other) => Complex(
        real - other.real,
        imag - other.imag,
      );

  Complex operator *(Complex other) => Complex(
        real * other.real - imag * other.imag,
        real * other.imag + imag * other.real,
      );
}