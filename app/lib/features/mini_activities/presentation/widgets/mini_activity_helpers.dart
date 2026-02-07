import 'package:flutter/material.dart';

/// Shared helper to map Norwegian team color names to Material colors.
Color getTeamColor(String? name) {
  switch (name?.toLowerCase()) {
    case 'rød':
      return Colors.red;
    case 'blå':
      return Colors.blue;
    case 'grønn':
      return Colors.green;
    case 'gul':
      return Colors.yellow;
    case 'oransje':
      return Colors.orange;
    case 'lilla':
      return Colors.purple;
    case 'rosa':
      return Colors.pink;
    case 'hvit':
      return Colors.grey.shade300;
    case 'gamle':
      return Colors.brown;
    case 'unge':
      return Colors.lightBlue;
    default:
      return Colors.grey;
  }
}
