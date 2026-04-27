// lib/screens/room_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/booking_provider.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';

class RoomScheduleScreen extends StatefulWidget {
  const RoomScheduleScreen({Key? key}) : super(key: key);

  @override
  State<RoomScheduleScreen> createState() => _RoomScheduleScreenState();
}

class _RoomScheduleScreenState extends State<RoomScheduleScreen> {
  String _selectedDay = 'monday';
  String _searchQuery = '';
  RoomType? _filterType;

  final List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<RoomProvider, BookingProvider>(
      builder: (context, roomProvider, bookingProvider, child) {
        if (roomProvider.isLoading || bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter rooms based on search and type
        var filteredRooms = roomProvider.rooms;
        if (_searchQuery.isNotEmpty) {
          filteredRooms = filteredRooms.where((r) =>
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.building.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        if (_filterType != null) {
          filteredRooms = filteredRooms.where((r) => r.type == _filterType).toList();
        }

        return Column(
          children: [
            // Filters Bar
            _buildFiltersBar(context),

            // Day Selector
            _buildDaySelector(context),

            // Room Schedule List
            Expanded(
              child: filteredRooms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  final roomBookings = bookingProvider.getBookingsForRoom(room.id)
                      .where((b) => b.dayOfWeek == _selectedDay)
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  return RoomScheduleCard(
                    room: room,
                    bookings: roomBookings,
                    day: _selectedDay,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<RoomType?>(
            value: _filterType,
            hint: const Text('All Types'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...RoomType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.name.substring(0, 1).toUpperCase() + type.name.substring(1)),
              )),
            ],
            onChanged: (value) => setState(() => _filterType = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == _selectedDay;
          final displayDay = day.substring(0, 1).toUpperCase() + day.substring(1, 3);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(displayDay),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedDay = day);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No rooms found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ROOM SCHEDULE CARD ====================

class RoomScheduleCard extends StatelessWidget {
  final Room room;
  final List<Booking> bookings;
  final String day;

  const RoomScheduleCard({
    Key? key,
    required this.room,
    required this.bookings,
    required this.day,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isAvailable = room.currentStatus == RoomStatus.available;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${room.building} • Floor ${room.floor} • ${room.type.name} • Capacity: ${room.capacity}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            room.currentStatus.name.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          if (bookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'No bookings scheduled for ${day.substring(0, 1).toUpperCase()}${day.substring(1)}',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            )
          else
            ...bookings.map((booking) => _buildBookingTile(context, booking)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBookingTile(BuildContext context, Booking booking) {
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    final currentTime = TimeOfDay.fromDateTime(now);
    final start = _parseTime(booking.startTime);
    final end = _parseTime(booking.endTime);

    final isActive = day == currentDay && _isTimeBetween(currentTime, start, end);
    final isPast = day == currentDay && (currentTime.hour * 60 + currentTime.minute) > (end.hour * 60 + end.minute);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : (isPast ? Colors.grey[50] : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue[300]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 40,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                booking.startTime,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                booking.endTime,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        title: Text(
          booking.subjectName ?? 'Unknown Subject',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isPast ? Colors.grey[500] : Colors.black,
            decoration: isPast ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${booking.teacherName ?? 'Unknown Teacher'} • ${booking.subjectCode ?? ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: isActive
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'NOW',
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        )
            : isPast
            ? Icon(Icons.check_circle, size: 16, color: Colors.grey[400])
            : Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}