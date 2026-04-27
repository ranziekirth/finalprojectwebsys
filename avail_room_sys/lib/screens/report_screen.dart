//lib/screens/report_screen..dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/booking_model.dart';
import '../models/conflict_model.dart';
import '../providers/room_provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/booking_provider.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSemester = 'First Semester';
  String _selectedSchoolYear = '2024-2025';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRoomScheduleTab(),
              _buildTeacherLoadTab(),
              _buildConflictsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────── HEADER & FILTERS ───────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports & Analytics',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Insights into rooms, teachers, and schedules',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: Colors.grey[50],
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('Filter:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700], fontSize: 13)),
          const SizedBox(width: 16),
          _buildFilterDropdown<String>(
            value: _selectedSemester,
            items: ['First Semester', 'Second Semester', 'Summer'],
            onChanged: (v) => setState(() => _selectedSemester = v!),
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown<String>(
            value: _selectedSchoolYear,
            items: ['2023-2024', '2024-2025', '2025-2026'],
            onChanged: (v) => setState(() => _selectedSchoolYear = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Overview', iconMargin: EdgeInsets.only(bottom: 4)),
          Tab(icon: Icon(Icons.meeting_room_outlined, size: 16), text: 'By Room', iconMargin: EdgeInsets.only(bottom: 4)),
          Tab(icon: Icon(Icons.people_outlined, size: 16), text: 'Teacher Load', iconMargin: EdgeInsets.only(bottom: 4)),
          Tab(icon: Icon(Icons.warning_amber_outlined, size: 16), text: 'Conflicts', iconMargin: EdgeInsets.only(bottom: 4)),
        ],
      ),
    );
  }

  // ─────────────────── TAB 1: OVERVIEW ───────────────────

  Widget _buildOverviewTab() {
    return Consumer3<RoomProvider, TeacherProvider, BookingProvider>(
      builder: (context, roomProv, teacherProv, bookingProv, _) {
        final rooms = roomProv.rooms;
        final teachers = teacherProv.teachers;
        final bookings = bookingProv.bookings;

        final availableRooms = rooms.where((r) => r.currentStatus == RoomStatus.available).length;
        final overloadedTeachers = teachers.where((t) => t.isOverloaded()).length;

        // Day distribution
        final dayDist = <String, int>{};
        for (final b in bookings) {
          dayDist[b.dayOfWeek] = (dayDist[b.dayOfWeek] ?? 0) + 1;
        }
        final maxDay = dayDist.values.isEmpty ? 1 : dayDist.values.reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat cards
              LayoutBuilder(
                builder: (ctx, cstr) {
                  final cols = cstr.maxWidth > 900 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Total Rooms', '${rooms.length}', '$availableRooms available', Icons.meeting_room, Colors.blue),
                      _buildStatCard('Total Teachers', '${teachers.length}', '$overloadedTeachers overloaded', Icons.people, Colors.green),
                      _buildStatCard('Scheduled Classes', '${bookings.length}', 'This semester', Icons.class_, Colors.orange),
                      _buildStatCard('Conflicts', overloadedTeachers > 0 ? '$overloadedTeachers' : '0', overloadedTeachers > 0 ? 'Need attention' : 'All clear', Icons.warning_amber, overloadedTeachers > 0 ? Colors.red : Colors.teal),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Classes by day
              Text('Classes by Day of Week',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: dayDist.isEmpty
                      ? _buildEmptyStateInline('No schedule data yet.\nGenerate and publish a schedule first.')
                      : Column(
                    children: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
                        .where((d) => dayDist.containsKey(d))
                        .map((day) {
                      final count = dayDist[day] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                day[0].toUpperCase() + day.substring(1),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: maxDay > 0 ? count / maxDay : 0,
                                  minHeight: 22,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation(
                                      Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 28,
                              child: Text('$count',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Published schedules history
              Text('Published Schedule History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPublishedHistory(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String sub, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getPublishedSchedulesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildEmptyStateInline('No schedules published yet.\nUse the Auto-Scheduler to generate and publish.'),
            ),
          );
        }
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = list[i];
              final rawDate = item['publishedAt'];
              String dateStr = 'Unknown date';
              if (rawDate != null) {
                try {
                  final dt = rawDate.toDate != null ? rawDate.toDate() : DateTime.tryParse(rawDate.toString());
                  if (dt != null) dateStr = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
                } catch (_) {}
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.publish, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                title: Text(
                  '${item['semester'] ?? ''} ${item['schoolYear'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Published $dateStr • ${item['totalBookings'] ?? 0} classes • ${item['conflictCount'] ?? 0} conflicts',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Active', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────── TAB 2: BY ROOM ───────────────────

  Widget _buildRoomScheduleTab() {
    return Consumer2<RoomProvider, BookingProvider>(
      builder: (context, roomProv, bookingProv, _) {
        if (roomProv.isLoading) return const Center(child: CircularProgressIndicator());

        final rooms = roomProv.rooms;
        final bookings = bookingProv.bookings;

        if (rooms.isEmpty) {
          return _buildFullEmptyState(Icons.meeting_room_outlined, 'No rooms found', 'Add rooms first in Room Management.');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rooms.map((room) {
              final rb = bookings.where((b) => b.roomId == room.id).toList();
              return _buildRoomReportCard(room, rb);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRoomReportCard(Room room, List<Booking> bookings) {
    final totalHours = _calcHours(bookings);
    const totalWeeklyHours = 11 * 5 * 1.5; // 11 slots/day * 5 days * 1.5h
    final utilization = (totalHours / totalWeeklyHours * 100).clamp(0.0, 100.0);
    final utilColor = _utilizationColor(utilization);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: utilColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.meeting_room, color: utilColor, size: 22),
        ),
        title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${room.building} • ${bookings.length} class${bookings.length == 1 ? '' : 'es'} • ${totalHours.toStringAsFixed(1)} hrs/wk'),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${utilization.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: utilColor, fontSize: 15)),
              Text('util.', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: utilization / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(utilColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${utilization.toStringAsFixed(1)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: utilColor, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                if (bookings.isEmpty)
                  Text('No classes scheduled in this room.', style: TextStyle(color: Colors.grey[500]))
                else ...[
                  Text('Scheduled Classes:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...bookings.map((b) => _buildBookingRow(b)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingRow(Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              b.dayOfWeek.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${b.subjectCode ?? 'N/A'} — ${b.subjectName ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text('${b.dayOfWeek} ${b.startTime}–${b.endTime}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(b.teacherName ?? 'Unknown',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  // ─────────────────── TAB 3: TEACHER LOAD ───────────────────

  Widget _buildTeacherLoadTab() {
    return Consumer2<TeacherProvider, BookingProvider>(
      builder: (context, teacherProv, bookingProv, _) {
        if (teacherProv.isLoading) return const Center(child: CircularProgressIndicator());

        final teachers = teacherProv.teachers;
        final bookings = bookingProv.bookings;

        if (teachers.isEmpty) {
          return _buildFullEmptyState(Icons.people_outline, 'No teachers found', 'Add teachers in Teacher Management.');
        }

        // Sort: overloaded → high load → low load
        final sorted = List<Teacher>.from(teachers)
          ..sort((a, b) {
            final aHours = _teacherHours(a.id, bookings);
            final bHours = _teacherHours(b.id, bookings);
            return (bHours / b.maxWeeklyHours).compareTo(aHours / a.maxWeeklyHours);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: sorted.map((t) {
              final tb = bookings.where((b) => b.teacherId == t.id).toList();
              return _buildTeacherReportCard(t, tb);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTeacherReportCard(Teacher teacher, List<Booking> bookings) {
    final actual = _calcHours(bookings);
    final utilization = (actual / teacher.maxWeeklyHours * 100).clamp(0.0, 120.0);
    final isOverloaded = actual > teacher.maxWeeklyHours;
    final color = isOverloaded ? Colors.red : (utilization >= 70 ? Colors.orange : Colors.green);
    final uniqueSubjects = bookings.map((b) => b.subjectName ?? '').where((s) => s.isNotEmpty).toSet().toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverloaded ? BorderSide(color: Colors.red.withOpacity(0.4), width: 1.5) : BorderSide.none,
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(teacher.name,
                  style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
            if (isOverloaded) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                child: const Text('OVERLOADED',
                    style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Text(
            '${teacher.department} • ${actual.toStringAsFixed(1)} / ${teacher.maxWeeklyHours} hrs/wk',
            style: const TextStyle(fontSize: 12)),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${utilization.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              Text('load', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${actual.toStringAsFixed(1)} / ${teacher.maxWeeklyHours} hrs',
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text('${utilization.toStringAsFixed(1)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (utilization / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                if (uniqueSubjects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Subjects (${uniqueSubjects.length}):',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: uniqueSubjects
                        .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                        .toList(),
                  ),
                ],
                if (bookings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Sessions (${bookings.length}):',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...bookings.take(6).map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildBookingRow(b),
                  )),
                  if (bookings.length > 6)
                    Text('  ... and ${bookings.length - 6} more sessions',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── TAB 4: CONFLICTS ───────────────────

  Widget _buildConflictsTab() {
    return StreamBuilder<List<Conflict>>(
      stream: FirestoreService().getConflictsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conflicts = snap.data ?? [];

        if (conflicts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
                const SizedBox(height: 16),
                Text(
                  'No Conflicts Found!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The current schedule has no detected conflicts.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final unresolved = conflicts.where((c) => c.status != ConflictStatus.resolved).toList();
        final resolved = conflicts.where((c) => c.status == ConflictStatus.resolved).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: unresolved.isEmpty ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (unresolved.isEmpty ? Colors.green : Colors.red).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      unresolved.isEmpty ? Icons.check_circle : Icons.warning,
                      color: unresolved.isEmpty ? Colors.green : Colors.red[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        unresolved.isEmpty
                            ? 'All conflicts have been resolved!'
                            : '${unresolved.length} unresolved conflict${unresolved.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: unresolved.isEmpty ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (resolved.isNotEmpty)
                      Text('${resolved.length} resolved',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              if (unresolved.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Unresolved Conflicts',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...unresolved.map((c) => _buildConflictCard(c, isResolved: false)),
              ],
              if (resolved.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Resolved Conflicts',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                ...resolved.map((c) => _buildConflictCard(c, isResolved: true)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConflictCard(Conflict conflict, {required bool isResolved}) {
    final color = isResolved ? Colors.grey : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isResolved ? Colors.grey[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                isResolved ? Icons.check : Icons.warning_amber,
                color: isResolved ? Colors.grey : Colors.orange[700],
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conflict.type.name
                        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
                        .trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isResolved ? Colors.grey[600] : Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(conflict.description,
                      style: TextStyle(
                          fontSize: 13,
                          color: isResolved ? Colors.grey[500] : Colors.orange[800])),
                  if (isResolved && conflict.resolution != null) ...[
                    const SizedBox(height: 6),
                    Text('Resolution: ${conflict.resolution}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            if (!isResolved)
              TextButton(
                onPressed: () => _showResolveDialog(conflict),
                child: const Text('Resolve'),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HELPERS ───────────────────

  double _calcHours(List<Booking> bookings) {
    return bookings.fold(0, (sum, b) {
      try {
        final s = b.startTime.split(':');
        final e = b.endTime.split(':');
        final sMin = int.parse(s[0]) * 60 + int.parse(s[1]);
        final eMin = int.parse(e[0]) * 60 + int.parse(e[1]);
        return sum + (eMin - sMin) / 60.0;
      } catch (_) {
        return sum;
      }
    });
  }

  double _teacherHours(String teacherId, List<Booking> bookings) {
    return _calcHours(bookings.where((b) => b.teacherId == teacherId).toList());
  }

  Color _utilizationColor(double pct) {
    if (pct >= 80) return Colors.red;
    if (pct >= 50) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEmptyStateInline(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message,
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ),
    );
  }

  Widget _buildFullEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  void _showResolveDialog(Conflict conflict) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conflict.description, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Resolution notes',
                hintText: 'Describe how this was resolved...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirestoreService().resolveConflict(conflict.id, controller.text, 'admin');
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conflict resolved!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              subtitle: const Text('Compatible with Excel & Sheets'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV export — coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Print-ready room schedule'),
              onTap: () async {
                Navigator.pop(ctx);

                final bookingProv = context.read<BookingProvider>();
                final roomProv = context.read<RoomProvider>();
                final teacherProv = context.read<TeacherProvider>();

                // Filter bookings by selected semester/year
                final filteredBookings = bookingProv.bookings
                    .where((b) =>
                b.semester == _selectedSemester &&
                    b.schoolYear == _selectedSchoolYear)
                    .toList();

                if (filteredBookings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No schedule data to export for the selected period.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await PdfService.exportSemesterSchedule(
                  context: context,
                  bookings: filteredBookings,
                  rooms: roomProv.rooms,
                  teachers: teacherProv.teachers,
                  semester: _selectedSemester,
                  schoolYear: _selectedSchoolYear,
                  schoolName: 'Your School Name', // ← Change this
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}