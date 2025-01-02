class AudioRecordingModel {
  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;

  AudioRecordingModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioRecordingModel.fromJson(Map<String, dynamic> json) {
    return AudioRecordingModel(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
