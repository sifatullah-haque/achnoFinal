import 'package:flutter/material.dart';

// Helper class to manage activity icons
class ActivityIconHelper {
  // Return appropriate icon for each activity
  static IconData getIconForActivity(String activity) {
    switch (activity.toLowerCase()) {
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.electrical_services;
      case 'wood worker':
        return Icons.carpenter;
      case 'painter':
        return Icons.format_paint;
      case 'carpenter':
        return Icons.handyman;
      case 'mason':
        return Icons.construction;
      case 'gardener':
        return Icons.yard;
      case 'cleaner':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }

  // Return appropriate color for each activity
  static Color getColorForActivity(String activity) {
    switch (activity.toLowerCase()) {
      case 'plumber':
        return Colors.blue;
      case 'electrician':
        return Colors.amber;
      case 'wood worker':
        return Colors.brown;
      case 'painter':
        return Colors.deepPurple;
      case 'carpenter':
        return Colors.orange[800]!;
      case 'mason':
        return Colors.grey[700]!;
      case 'gardener':
        return Colors.green;
      case 'cleaner':
        return Colors.cyan;
      default:
        return Colors.blueGrey;
    }
  }
}
