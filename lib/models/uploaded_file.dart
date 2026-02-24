enum UploadStatus { pending, uploading, completed, error }

class UploadedFile {
  final String name;
  final String path;
  final int size;
  final UploadStatus status;
  final double progress;
  final String? downloadUrl;
  final String? serviceName;
  final String? errorMessage;

  const UploadedFile({
    required this.name,
    required this.path,
    required this.size,
    required this.status,
    this.progress = 0.0,
    this.downloadUrl,
    this.serviceName,
    this.errorMessage,
  });

  UploadedFile copyWith({
    UploadStatus? status,
    double? progress,
    String? downloadUrl,
    String? serviceName,
    String? errorMessage,
  }) {
    return UploadedFile(
      name: name,
      path: path,
      size: size,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      serviceName: serviceName ?? this.serviceName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
