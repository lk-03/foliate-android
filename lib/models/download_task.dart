import 'dart:convert';

/// Status lifecycle for book downloads.
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled;

  String toMap() => name;

  static DownloadStatus fromMap(String? value) {
    if (value == null) return DownloadStatus.queued;
    return DownloadStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DownloadStatus.queued,
    );
  }
}

/// Represents a tracked download task from Open Libraries or external sources.
class DownloadTask {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String downloadUrl;
  final int? fileSizeBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final double progress;
  final double speedBytesPerSecond;
  final int? startedAt;
  final int? completedAt;
  final String? localFilePath;
  final String? error;

  const DownloadTask({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.downloadUrl,
    this.fileSizeBytes,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.speedBytesPerSecond = 0.0,
    this.startedAt,
    this.completedAt,
    this.localFilePath,
    this.error,
  });

  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.queued;

  bool get isPaused => status == DownloadStatus.paused;

  bool get isCompleted => status == DownloadStatus.completed;

  bool get isFailed => status == DownloadStatus.failed;

  bool get isCancelled => status == DownloadStatus.cancelled;

  bool get isTerminal => isCompleted || isFailed || isCancelled;

  String get formattedProgress => '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

  String get formattedDownloadedSize => _formatBytes(downloadedBytes);

  String get formattedTotalSize =>
      fileSizeBytes != null ? _formatBytes(fileSizeBytes!) : 'Unknown size';

  String get formattedSpeed {
    if (speedBytesPerSecond <= 0) return '';
    return '${_formatBytes(speedBytesPerSecond.round())}/s';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DownloadTask copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? downloadUrl,
    int? fileSizeBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    double? progress,
    double? speedBytesPerSecond,
    int? startedAt,
    int? completedAt,
    String? localFilePath,
    String? error,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      localFilePath: localFilePath ?? this.localFilePath,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'downloadUrl': downloadUrl,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.toMap(),
      'progress': progress,
      'speedBytesPerSecond': speedBytesPerSecond,
      if (startedAt != null) 'startedAt': startedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (localFilePath != null) 'localFilePath': localFilePath,
      if (error != null) 'error': error,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String? ?? 'Unknown Author',
      coverUrl: map['coverUrl'] as String?,
      downloadUrl: map['downloadUrl'] as String,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.fromMap(map['status'] as String?),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      speedBytesPerSecond: (map['speedBytesPerSecond'] as num?)?.toDouble() ?? 0.0,
      startedAt: map['startedAt'] as int?,
      completedAt: map['completedAt'] as int?,
      localFilePath: map['localFilePath'] as String?,
      error: map['error'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DownloadTask.fromJson(String source) =>
      DownloadTask.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
