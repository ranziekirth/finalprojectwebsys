// lib/screens/semester_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/booking_provider.dart';
import '../providers/room_provider.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../services/firestore_service.dart';

class SemesterScheduleScreen extends StatefulWidget {
  const SemesterScheduleScreen({Key? key}) : super(key: key);

  @override
  State<SemesterScheduleScreen> createState() => _SemesterScheduleScreenState();
}

class _SemesterScheduleScreenState extends State<SemesterScheduleScreen> {
  String _selectedSemester = 'First Semester';
  String _selectedSchoolYear = '2024-2025';
  String _filterDay = 'All';
  String? _filterRoomId;
  String? _filterTeacherId;
  bool _showFilters = false;

  final List<String> _days = [
    'All', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, RoomProvider>(
      builder: (context, bookingProvider, roomProvider, child) {
        if (bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter bookings
        var filteredBookings = bookingProvider.bookings;
        if (_filterDay != 'All') {
          filteredBookings = filteredBookings.where((b) => b.dayOfWeek == _filterDay).toList();
        }
        if (_filterRoomId != null) {
          filteredBookings = filteredBookings.where((b) => b.roomId == _filterRoomId).toList();
        }
        if (_filterTeacherId != null) {
          filteredBookings = filteredBookings.where((b) => b.teacherId == _filterTeacherId).toList();
        }

        // Sort by day then time
        filteredBookings.sort((a, b) {
          final dayCompare = _dayIndex(a.dayOfWeek).compareTo(_dayIndex(b.dayOfWeek));
          if (dayCompare != 0) return dayCompare;
          return a.startTime.compareTo(b.startTime);
        });

        return Column(
          children: [
            // Header with semester info
            _buildHeader(context, bookingProvider),

            // Filters
            if (_showFilters) _buildFilterPanel(context, roomProvider),

            // Schedule Content
            Expanded(
              child: filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : _buildScheduleList(context, filteredBookings, roomProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BookingProvider bookingProvider) {
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester Schedule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bookingProvider.selectedSemester} • ${bookingProvider.selectedSchoolYear}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: 'Toggle Filters',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Semester selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['First Semester', 'Second Semester', 'Summer'].map((s) =>
                      DropdownMenuItem(value: s, child: Text(s))
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSemester = value);
                      context.read<BookingProvider>().setSemester(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSchoolYear,
                  decoration: InputDecoration(
                    labelText: 'School Year',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['2024-2025', '2025-2026', '2026-2027'].map((y) =>
                      DropdownMenuItem(value: y, child: Text(y))
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSchoolYear = value);
                      context.read<BookingProvider>().setSchoolYear(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, RoomProvider roomProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterDay,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: _days.map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d == 'All' ? 'All Days' : d.substring(0, 1).toUpperCase() + d.substring(1)),
                  )).toList(),
                  onChanged: (value) => setState(() => _filterDay = value ?? 'All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filterRoomId,
                  decoration: InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Rooms')),
                    ...roomProvider.rooms.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name),
                    )),
                  ],
                  onChanged: (value) => setState(() => _filterRoomId = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _filterDay = 'All';
                _filterRoomId = null;
                _filterTeacherId = null;
              }),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context, List<Booking> bookings, RoomProvider roomProvider) {
    // Group by day
    final grouped = <String, List<Booking>>{};
    for (final booking in bookings) {
      grouped.putIfAbsent(booking.dayOfWeek, () => []).add(booking);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayBookings = grouped[day]!;
        final displayDay = day.substring(0, 1).toUpperCase() + day.substring(1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin:  EdgeInsets.only(bottom: 8, top: index > 0 ? 16 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayDay,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...dayBookings.map((booking) => _buildScheduleCard(context, booking, roomProvider)),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, Booking booking, RoomProvider roomProvider) {
    final room = roomProvider.getRoomById(booking.roomId);
    final isToday = booking.dayOfWeek == _getTodayName();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isToday ? 2 : 0,
      color: isToday ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? Colors.blue[300]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Time Column
            Container(
              width: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    booking.startTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.endTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.subjectName ?? 'Unknown Subject',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        booking.teacherName ?? 'Unknown Teacher',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        room?.name ?? booking.roomName ?? 'Unknown Room',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${room?.capacity ?? '?'} seats',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No schedule published yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin needs to publish a schedule first',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  int _dayIndex(String day) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days.indexOf(day.toLowerCase());
  }

  String _getTodayName() {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[DateTime.now().weekday - 1];
  }
}