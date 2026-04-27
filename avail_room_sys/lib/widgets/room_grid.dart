// lib/widgets/room_grid.dart
import 'package:flutter/material.dart';
import '../models/room_model.dart';

class RoomAvailabilityGrid extends StatelessWidget {
  const RoomAvailabilityGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data - updated to match new Room model
    final rooms = [
      Room(
        id: '1',
        name: 'Room 101',
        building: 'Science Building',
        floor: '1',  // ADDED: Required parameter
        capacity: 40,
        type: RoomType.lecture,
        equipment: ['Projector', 'AC', 'Whiteboard'],
        currentStatus: RoomStatus.available,
        // REMOVED: nextAvailable, currentSubject, currentTeacher
      ),
      Room(
        id: '2',
        name: 'Lab A',
        building: 'Science Building',
        floor: '2',  // ADDED
        capacity: 25,
        type: RoomType.laboratory,
        equipment: ['Computers', 'Projector', 'AC'],
        currentStatus: RoomStatus.occupied,
        // REMOVED: nextAvailable, currentSubject, currentTeacher
      ),
      Room(
        id: '3',
        name: 'Room 203',
        building: 'Main Building',
        floor: '2',  // ADDED
        capacity: 50,
        type: RoomType.lecture,
        equipment: ['Projector', 'AC', 'Mic'],
        currentStatus: RoomStatus.available,
        // REMOVED
      ),
      Room(
        id: '4',
        name: 'Conference Room',
        building: 'Admin Building',
        floor: '1',  // ADDED
        capacity: 15,
        type: RoomType.meeting,
        equipment: ['TV', 'Video Conf', 'AC'],
        currentStatus: RoomStatus.maintenance,
        // REMOVED
      ),
      Room(
        id: '5',
        name: 'Lab B',
        building: 'Science Building',
        floor: '3',  // ADDED
        capacity: 30,
        type: RoomType.laboratory,
        equipment: ['Chemistry Equipment', 'Fume Hood', 'AC'],
        currentStatus: RoomStatus.occupied,
        // REMOVED
      ),
      Room(
        id: '6',
        name: 'Room 305',
        building: 'Main Building',
        floor: '3',  // ADDED
        capacity: 45,
        type: RoomType.lecture,
        equipment: ['Projector', 'AC'],
        currentStatus: RoomStatus.available,
        // REMOVED
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1400 ? 4 :
        constraints.maxWidth > 1000 ? 3 :
        constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) => RoomCard(room: rooms[index]),
        );
      },
    );
  }
}

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({Key? key, required this.room}) : super(key: key);

  Color _getStatusColor() {
    switch (room.currentStatus) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.red;
      case RoomStatus.maintenance:
        return Colors.orange;
      case RoomStatus.reserved:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (room.currentStatus) {
      case RoomStatus.available:
        return Icons.check_circle;
      case RoomStatus.occupied:
        return Icons.lock;
      case RoomStatus.maintenance:
        return Icons.build;
      case RoomStatus.reserved:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRoomDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 8, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12), // Reduced from 16
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED: Constrain the row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(  // ADD Expanded here
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(  // Reduced from titleLarge
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${room.building} • Floor ${room.floor}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        // FIXED: Constrain status chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8), // Reduced
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,  // ADD this
                            children: [
                              Icon(_getStatusIcon(), size: 12, color: statusColor), // Reduced from 14
                              const SizedBox(width: 2),
                              Text(
                                room.currentStatus.name.substring(0, 3).toUpperCase(), // Shorten text
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9, // Reduced from 10
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // FIXED: Compact row
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[600]), // Reduced
                        const SizedBox(width: 2),
                        Text(
                          '${room.capacity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          room.type.name.substring(0, 3), // Shorten
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // FIXED: Flexible status container
                    Flexible(  // ADD Flexible
                      child: Container(
                        padding: const EdgeInsets.all(6), // Reduced
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(), size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(  // ADD Flexible
                              child: Text(
                                room.currentStatus == RoomStatus.available
                                    ? 'Available'
                                    : room.currentStatus == RoomStatus.occupied
                                    ? 'Occupied'
                                    : room.currentStatus == RoomStatus.maintenance
                                    ? 'Maintenance'
                                    : 'Reserved',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // FIXED: Constrain equipment chips
                    if (room.equipment.isNotEmpty)
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: room.equipment.take(3).map((eq) {  // Limit to 3 items
                          return Chip(
                            label: Text(
                              eq.length > 8 ? '${eq.substring(0, 8)}...' : eq, // Truncate long names
                              style: const TextStyle(fontSize: 8),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact, // ADD this
                            backgroundColor: Colors.grey[100],
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Building: ${room.building}'),
            Text('Floor: ${room.floor}'),  // UPDATED
            Text('Capacity: ${room.capacity}'),
            Text('Type: ${room.type.name}'),
            Text('Status: ${room.currentStatus.name}'),
            const SizedBox(height: 8),
            const Text('Equipment:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...room.equipment.map((e) => Text('• $e')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}