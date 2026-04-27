// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/booking_provider.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sidebar.dart';
import '../widgets/room_grid.dart';
import '../widgets/timeline_view.dart';
import '../widgets/statistics_card.dart';
import '../screens/semester_schedule_screen.dart';
import '../screens/room_schedule_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Room Schedule',
    'Semester Schedule',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().init();
      context.read<BookingProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/admin-login'),
          ),
        ],
      ),
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        isAdminMode: false,
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin-login'),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            label: const Text(
              'Admin Mode',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              isAdminMode: false,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              isAdminMode: false,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _titles[_selectedIndex],
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          _buildSearchField(),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin-login'),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Admin Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search rooms, teachers, or subjects...',
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent();
      case 1:
        return const RoomScheduleScreen();
      case 2:
        return const SemesterScheduleScreen();
      default:
        return const DashboardContent();
    }
  }
}

// ==================== DASHBOARD CONTENT ====================

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context),
          const SizedBox(height: 24),
          _buildLiveStatisticsRow(context),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Real-Time Room Availability'),
          const SizedBox(height: 16),
          const LiveRoomAvailabilityGrid(),
          const SizedBox(height: 32),
          _buildSectionTitle(context, "Today's Active Sessions"),
          const SizedBox(height: 16),
          const TodayScheduleView(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withRed(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Room Scheduler',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View real-time room status, schedules, and availability. Admin mode available for scheduling.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (ResponsiveLayout.isDesktop(context))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                size: 64,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStatisticsRow(BuildContext context) {
    return Consumer2<RoomProvider, BookingProvider>(
      builder: (context, roomProvider, bookingProvider, child) {
        final rooms = roomProvider.rooms;
        final bookings = bookingProvider.bookings;

        final availableRooms = rooms.where((r) => r.currentStatus == RoomStatus.available).length;
        final occupiedRooms = rooms.where((r) => r.currentStatus == RoomStatus.occupied).length;
        final maintenanceRooms = rooms.where((r) => r.currentStatus == RoomStatus.maintenance).length;

        // Calculate active classes (bookings happening right now)
        final now = DateTime.now();
        final currentDay = _getDayName(now.weekday);
        final currentTime = TimeOfDay.fromDateTime(now);

        final activeClasses = bookings.where((b) {
          if (b.dayOfWeek != currentDay) return false;
          final start = _parseTime(b.startTime);
          final end = _parseTime(b.endTime);
          return _isTimeBetween(currentTime, start, end);
        }).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 4 :
            constraints.maxWidth > 800 ? 2 : 1;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                StatisticsCard(
                  title: 'Available Rooms',
                  value: availableRooms.toString(),
                  subtitle: 'Out of ${rooms.length} total',
                  icon: Icons.meeting_room,
                  color: Colors.green,
                  trend: occupiedRooms > 0 ? '$occupiedRooms in use' : 'All free',
                ),
                StatisticsCard(
                  title: 'Active Classes',
                  value: activeClasses.toString(),
                  subtitle: 'Currently in session',
                  icon: Icons.class_,
                  color: Colors.blue,
                  trend: 'Happening now',
                ),
                StatisticsCard(
                  title: 'Total Rooms',
                  value: rooms.length.toString(),
                  subtitle: '$maintenanceRooms under maintenance',
                  icon: Icons.apartment,
                  color: Colors.orange,
                  trend: rooms.isEmpty ? 'Loading...' : 'System active',
                ),
                StatisticsCard(
                  title: 'Today\'s Bookings',
                  value: bookings.where((b) => b.dayOfWeek == currentDay).length.toString(),
                  subtitle: 'Scheduled for $currentDay',
                  icon: Icons.today,
                  color: Colors.purple,
                  trend: 'View in Room Schedule',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

// ==================== LIVE ROOM GRID ====================

class LiveRoomAvailabilityGrid extends StatelessWidget {
  const LiveRoomAvailabilityGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        if (roomProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roomProvider.rooms.isEmpty) {
          return _buildEmptyState();
        }

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
              itemCount: roomProvider.rooms.length,
              itemBuilder: (context, index) => LiveRoomCard(room: roomProvider.rooms[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No rooms configured yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin needs to add rooms in Admin Mode',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class LiveRoomCard extends StatelessWidget {
  final Room room;

  const LiveRoomCard({Key? key, required this.room}) : super(key: key);

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
      elevation: 2,
      child: InkWell(
        onTap: () => _showRoomDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 8, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getStatusIcon(), size: 12, color: statusColor),
                              const SizedBox(width: 2),
                              Text(
                                room.currentStatus.name.substring(0, 3).toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${room.capacity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          room.type.name.substring(0, 3),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                            Flexible(
                              child: Text(
                                room.currentStatus == RoomStatus.available
                                    ? 'Available Now'
                                    : room.currentStatus == RoomStatus.occupied
                                    ? 'Currently Occupied'
                                    : room.currentStatus == RoomStatus.maintenance
                                    ? 'Under Maintenance'
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
                    if (room.equipment.isNotEmpty)
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: room.equipment.take(3).map((eq) {
                          return Chip(
                            label: Text(
                              eq.length > 8 ? '${eq.substring(0, 8)}...' : eq,
                              style: const TextStyle(fontSize: 8),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
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
            Text('Floor: ${room.floor}'),
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

// ==================== TODAY'S SCHEDULE VIEW ====================

class TodayScheduleView extends StatelessWidget {
  const TodayScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, RoomProvider>(
      builder: (context, bookingProvider, roomProvider, child) {
        if (bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final currentDay = _getDayName(now.weekday);
        final currentTime = TimeOfDay.fromDateTime(now);

        // Get today's bookings sorted by time
        final todayBookings = bookingProvider.bookings
            .where((b) => b.dayOfWeek == currentDay)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (todayBookings.isEmpty) {
          return _buildEmptyTodayState(currentDay);
        }

        return Column(
          children: todayBookings.map((booking) {
            final room = roomProvider.getRoomById(booking.roomId);
            final isActive = _isCurrentlyActive(booking, currentTime);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isActive ? 2 : 0,
              color: isActive ? Colors.blue[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? Colors.blue[300]! : Colors.grey[200]!,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue[100]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.play_circle_filled : Icons.schedule,
                    color: isActive ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
                title: Text(
                  booking.subjectName ?? 'Unknown Subject',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${booking.startTime} - ${booking.endTime}'),
                    Text(
                      '${room?.name ?? booking.roomName ?? 'Unknown Room'} • ${booking.teacherName ?? 'Unknown Teacher'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                trailing: isActive
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                    : Text(
                  _getTimeStatus(booking, currentTime),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyTodayState(String day) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No sessions scheduled for ${day.substring(0, 1).toUpperCase()}${day.substring(1)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the Semester Schedule for full details',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
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

  bool _isCurrentlyActive(Booking booking, TimeOfDay currentTime) {
    final start = _parseTime(booking.startTime);
    final end = _parseTime(booking.endTime);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  String _getTimeStatus(Booking booking, TimeOfDay currentTime) {
    final start = _parseTime(booking.startTime);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = start.hour * 60 + start.minute;

    if (currentMinutes < startMinutes) {
      final diff = startMinutes - currentMinutes;
      final hours = diff ~/ 60;
      final mins = diff % 60;
      if (hours > 0) {
        return 'Starts in ${hours}h ${mins}m';
      }
      return 'Starts in ${mins}m';
    }
    return 'Ended';
  }
}