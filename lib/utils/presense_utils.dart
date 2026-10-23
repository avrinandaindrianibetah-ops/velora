
import 'package:flutter/material.dart';
import '../models/course.dart';

enum PresenceResult {
  online,
  offline,
}

String ymd(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year$month$day';
}

String recordId(String uid, Course course) {
  return '${uid}_${course.code}_${ymd(DateTime.now())}';
}

void showVSnack(
  BuildContext context,
  String message,
  Color color,
  IconData icon,
) {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
