// lib/widgets/publish_button.dart
import 'package:flutter/material.dart';
import '../services/scheduler_service.dart';
import '../models/booking_model.dart';

class PublishButton extends StatelessWidget {
  final ScheduleResult? scheduleResult;
  final String semester;
  final String schoolYear;
  final VoidCallback? onPublished;
  final bool isCompact;

  const PublishButton({
    Key? key,
    this.scheduleResult,
    required this.semester,
    required this.schoolYear,
    this.onPublished,
    this.isCompact = false,
  }) : super(key: key);

  bool get canPublish =>
      scheduleResult != null &&
          scheduleResult!.bookings.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return FloatingActionButton.extended(
        onPressed: canPublish ? () => _showPublishDialog(context) : null,
        icon: Icon(
          canPublish ? Icons.publish : Icons.lock,
          color: Colors.white,
        ),
        label: Text(
          canPublish ? 'Publish' : 'No Schedule',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: canPublish ? Colors.green : Colors.grey,
      );
    }
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: canPublish ? () => _showPublishDialog(context) : null,
        icon: Icon(
          canPublish ? Icons.publish_rounded : Icons.lock_outline,
          color: Colors.white,
        ),
        label: Text(
          canPublish ? 'Publish Schedule' : 'Generate First',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canPublish ? Colors.green[600] : Colors.grey[400],
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _showPublishDialog(BuildContext context) async {
    if (scheduleResult == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Schedule?'),
        content: Text(
          'Publish ${scheduleResult!.bookings.length} classes for $semester $schoolYear?\n\n'
              'This will replace any existing schedule for this semester.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Publishing is handled by the parent screen
      onPublished?.call();
    }
  }
}