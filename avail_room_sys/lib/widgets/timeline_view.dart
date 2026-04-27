// widgets/timeline_view.dart
import 'package:flutter/material.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeSlots = [
      TimeSlotData(time: '7:00 AM - 8:30 AM', subject: 'Mathematics 101', room: 'Room 101', teacher: 'Prof. Anderson', status: 'ongoing'),
      TimeSlotData(time: '8:30 AM - 10:00 AM', subject: 'Physics Lab', room: 'Lab A', teacher: 'Prof. Smith', status: 'ongoing'),
      TimeSlotData(time: '10:00 AM - 11:30 AM', subject: 'Computer Science', room: 'Room 203', teacher: 'Prof. Johnson', status: 'upcoming'),
      TimeSlotData(time: '11:30 AM - 1:00 PM', subject: 'Chemistry', room: 'Lab B', teacher: 'Prof. Williams', status: 'upcoming'),
      TimeSlotData(time: '1:00 PM - 2:30 PM', subject: 'English Literature', room: 'Room 305', teacher: 'Prof. Brown', status: 'upcoming'),
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: timeSlots.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final slot = timeSlots[index];
          return TimelineItem(
            data: slot,
            isFirst: index == 0,
            isLast: index == timeSlots.length - 1,
          );
        },
      ),
    );
  }
}

class TimeSlotData {
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final String status;

  TimeSlotData({
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.status,
  });
}

class TimelineItem extends StatelessWidget {
  final TimeSlotData data;
  final bool isFirst;
  final bool isLast;

  const TimelineItem({
    Key? key,
    required this.data,
    required this.isFirst,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOngoing = data.status == 'ongoing';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.time.split(' - ')[0],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOngoing ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                Text(
                  data.time.split(' - ')[1],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 20, color: Colors.grey[300]),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOngoing ? Theme.of(context).colorScheme.primary : Colors.grey[400],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (isOngoing ? Theme.of(context).colorScheme.primary : Colors.grey[400])!.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 8, bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOngoing ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOngoing ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.subject,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        data.room,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        data.teacher,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}