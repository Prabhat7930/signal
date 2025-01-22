import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signal/components/appbar.dart';
import 'package:signal/provider/audio_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarComponent("Signal Processing"),
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
        child: Center(
          child: Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: audioProvider.isRecording
                          ? Colors.red.shade100
                          : Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        audioProvider.isRecording ? Icons.mic : Icons.mic_none,
                        key: ValueKey<bool>(audioProvider.isRecording),
                        size: 60,
                        color: audioProvider.isRecording
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  )
                      .animate(
                        onPlay: (controller) => audioProvider.isRecording
                            ? controller.repeat()
                            : controller.stop(),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 40),
                  Animate(
                    child: ElevatedButton(
                      onPressed: () {
                        if (audioProvider.isRecording) {
                          audioProvider.stopRecording();
                        } else {
                          audioProvider.startRecording();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: audioProvider.isRecording
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        audioProvider.isRecording
                            ? 'Stop Recording'
                            : 'Start Recording',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut)
                      .fadeIn(duration: const Duration(milliseconds: 500)),
                  const SizedBox(height: 20),
                  Animate(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/recordings');
                      },
                      icon: const Icon(Icons.list, color: Colors.white),
                      label: const Text(
                        'View Recordings',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                    ),
                  )
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut)
                      .fadeIn(duration: const Duration(milliseconds: 500)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
