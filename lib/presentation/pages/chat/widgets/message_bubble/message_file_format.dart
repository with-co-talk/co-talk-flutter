import 'package:flutter/material.dart';

/// Returns an appropriate icon for the given file content type.
IconData fileIconForContentType(String? contentType) {
  if (contentType == null) return Icons.insert_drive_file;
  if (contentType.startsWith('image/')) return Icons.image;
  if (contentType.startsWith('video/')) return Icons.videocam;
  if (contentType.startsWith('audio/')) return Icons.audiotrack;
  if (contentType.contains('pdf')) return Icons.picture_as_pdf;
  if (contentType.contains('word') || contentType.contains('document')) {
    return Icons.description;
  }
  if (contentType.contains('sheet') || contentType.contains('excel')) {
    return Icons.table_chart;
  }
  if (contentType.contains('presentation') || contentType.contains('powerpoint')) {
    return Icons.slideshow;
  }
  if (contentType.contains('zip') || contentType.contains('rar') || contentType.contains('tar')) {
    return Icons.folder_zip;
  }
  return Icons.insert_drive_file;
}

/// Formats a byte count into a human readable string (B / KB / MB / GB).
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
