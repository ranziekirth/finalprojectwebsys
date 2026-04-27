// lib/screens/schedule_result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../services/scheduler_service.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/ai_suggestion_panel.dart';
import 'auto_scheduler_screen.dart';

class ScheduleResultScreen extends StatefulWidget {
  final ScheduleResult scheduleResult;
  final String semester;
  final String schoolYear;
  final List<Room> rooms;
  final List<Teacher> teachers;
  final List<Subject> subjects;

  const ScheduleResultScreen({
    Key? key,
    required this.scheduleResult,
    required this.semester,
    required this.schoolYear,
    required this.rooms,
    required this.teachers,
    required this.subjects,
  }) : super(key: key);

  @override
  State<ScheduleResultScreen> createState() => _ScheduleResultScreenState();
}

class _ScheduleResultScreenState extends State<ScheduleResultScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final FirestoreService _firestore = FirestoreService();

  late List<Booking> _bookings;
  late List<ScheduleConflict> _conflicts;
  late TabController _tabController;

  AIAnalysisResult? _aiAnalysis;
  bool _isAnalyzing = false;
  bool _isPublishing = false;
  bool _hasBeenModified = false;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(widget.scheduleResult.bookings);
    _conflicts = List.from(widget.scheduleResult.conflicts);
    _tabController = TabController(
      length: widget.scheduleResult.hasConflicts ? 3 : 2,
      vsync: this,
    );
    _runAIAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runAIAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final analysis = await _aiService.analyzeSchedule(
        currentBookings: _bookings,
        teachers: widget.teachers,
        rooms: widget.rooms,
        subjects: widget.subjects,
      );
      setState(() => _aiAnalysis = analysis);
    } catch (e) {
      debugPrint('AI analysis failed: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // ==================== EDITING ====================

  void _showEditDialog(Booking booking) {
    final room = widget.rooms.firstWhere((r) => r.id == booking.roomId);
    final subject = widget.subjects.firstWhere((s) => s.id == booking.subjectId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${subject.code}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _infoRow(Icons.meeting_room, 'Room', booking.roomName ?? 'Unknown'),
              _infoRow(Icons.person, 'Teacher', booking.teacherName ?? 'Unknown'),
              _infoRow(Icons.calendar_today, 'Day', booking.dayOfWeek.toUpperCase()),
              _infoRow(Icons.access_time, 'Time', '${booking.startTime} - ${booking.endTime}'),
              const Divider(height: 32),
              Text('Change Room:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.rooms.where((r) {
                  if (r.id == booking.roomId) return false;
                  return r.capacity >= subject.maxStudents &&
                      (r.type == subject.preferredRoomType ||
                          subject.preferredRoomType == null);
                }).map((r) {
                  return ActionChip(
                    avatar: Icon(Icons.meeting_room, size: 16, color: Colors.blue[700]),
                    label: Text('${r.name} (${r.capacity})'),
                    onPressed: () {
                      Navigator.pop(context);
                      _changeRoom(booking, r);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Change Teacher:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.teachers.where((t) {
                  if (t.id == booking.teacherId) return false;
                  final load = _calculateTeacherLoad(t.id);
                  return load + subject.requiredHoursPerWeek <= t.maxWeeklyHours;
                }).map((t) {
                  final load = _calculateTeacherLoad(t.id);
                  return ActionChip(
                    avatar: CircleAvatar(
                      radius: 10,
                      child: Text(t.name[0], style: const TextStyle(fontSize: 10)),
                    ),
                    label: Text('${t.name} (${load.toStringAsFixed(1)}h)'),
                    onPressed: () {
                      Navigator.pop(context);
                      _changeTeacher(booking, t);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _changeRoom(Booking booking, Room newRoom) {
    setState(() {
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        final old = _bookings[index];
        _bookings[index] = Booking(
          id: old.id,
          roomId: newRoom.id,
          teacherId: old.teacherId,
          subjectId: old.subjectId,
          dayOfWeek: old.dayOfWeek,
          startTime: old.startTime,
          endTime: old.endTime,
          semester: old.semester,
          schoolYear: old.schoolYear,
          isRecurring: old.isRecurring,
          roomName: newRoom.name,
          teacherName: old.teacherName,
          subjectName: old.subjectName,
          subjectCode: old.subjectCode,
        );
        _hasBeenModified = true;
        _recheckConflicts();
      }
    });
    _showSnackBar('Room changed to ${newRoom.name}', Colors.blue);
  }

  void _changeTeacher(Booking booking, Teacher newTeacher) {
    setState(() {
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        final old = _bookings[index];
        _bookings[index] = Booking(
          id: old.id,
          roomId: old.roomId,
          teacherId: newTeacher.id,
          subjectId: old.subjectId,
          dayOfWeek: old.dayOfWeek,
          startTime: old.startTime,
          endTime: old.endTime,
          semester: old.semester,
          schoolYear: old.schoolYear,
          isRecurring: old.isRecurring,
          roomName: old.roomName,
          teacherName: newTeacher.name,
          subjectName: old.subjectName,
          subjectCode: old.subjectCode,
        );
        _hasBeenModified = true;
        _recheckConflicts();
      }
    });
    _showSnackBar('Teacher changed to ${newTeacher.name}', Colors.blue);
  }

  void _recheckConflicts() {
    // Simple conflict recheck - remove resolved conflicts
    setState(() {
      _conflicts = _conflicts.where((c) {
        // Check if this conflict is still valid
        if (c.type == ConflictType.doubleBooking && c.bookingIds != null) {
          final b1 = _bookings.firstWhere((b) => b.id == c.bookingIds![0]);
          final b2 = _bookings.firstWhere((b) => b.id == c.bookingIds![1]);
          return b1.roomId == b2.roomId &&
              b1.dayOfWeek == b2.dayOfWeek &&
              b1.startTime == b2.startTime;
        }
        if (c.type == ConflictType.teacherOverlap && c.bookingIds != null) {
          final b1 = _bookings.firstWhere((b) => b.id == c.bookingIds![0]);
          final b2 = _bookings.firstWhere((b) => b.id == c.bookingIds![1]);
          return b1.teacherId == b2.teacherId &&
              b1.dayOfWeek == b2.dayOfWeek &&
              b1.startTime == b2.startTime;
        }
        return true; // Keep other conflict types
      }).toList();
    });
  }

  double _calculateTeacherLoad(String teacherId) {
    return _bookings
        .where((b) => b.teacherId == teacherId)
        .fold(0.0, (sum, b) => sum + _hours(b.startTime, b.endTime));
  }

  double _hours(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    return (int.parse(e[0]) * 60 + int.parse(e[1]) -
        int.parse(s[0]) * 60 - int.parse(s[1])) /
        60.0;
  }

  // ==================== PUBLISH ====================

  Future<void> _publish() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.publish, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Publish Schedule?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publish ${_bookings.length} classes for:'),
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today, 'Semester', widget.semester),
            _infoRow(Icons.school, 'Year', widget.schoolYear),
            if (_hasBeenModified)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have made manual modifications to this schedule.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (_conflicts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Warning: ${_conflicts.length} conflict(s) still exist. Publishing with conflicts may cause issues.',
                        style: TextStyle(color: Colors.orange[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _doPublish(user?.uid ?? 'admin');
    }
  }

  Future<void> _doPublish(String publishedBy) async {
    setState(() => _isPublishing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Publishing schedule...'),
          ],
        ),
      ),
    );

    try {
      final modifiedResult = ScheduleResult(
        bookings: _bookings,
        conflicts: _conflicts,
        generationTimeMs: widget.scheduleResult.generationTimeMs,
        totalSubjects: widget.scheduleResult.totalSubjects,
        scheduledSubjects: widget.scheduleResult.scheduledSubjects,
        teacherUtilization: widget.scheduleResult.teacherUtilization,
        roomUtilization: widget.scheduleResult.roomUtilization,
      );

      final scheduler = SchedulerService();
      await scheduler.publishSchedule(modifiedResult, publishedBy);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close result screen, back to scheduler

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 12),
                const Text('Published!'),
              ],
            ),
            content: Text(
              'Schedule for ${widget.semester} ${widget.schoolYear} published successfully with ${_bookings.length} classes.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showSnackBar('Failed to publish: $e', Colors.red);
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final hasConflicts = _conflicts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Results'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.preview), text: 'Preview'),
            if (hasConflicts) const Tab(icon: Icon(Icons.warning), text: 'Conflicts'),
            const Tab(icon: Icon(Icons.psychology), text: 'AI Analysis'),
          ],
        ),
        actions: [
          if (_hasBeenModified)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Modified',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: _isPublishing ? null : _publish,
            icon: const Icon(Icons.publish, color: Colors.white),
            label: Text(
              'Publish',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreviewTab(),
          if (hasConflicts) _buildConflictsTab(),
          _buildAIAnalysisTab(),
        ],
      ),
    );
  }

  // ==================== PREVIEW TAB ====================

  Widget _buildPreviewTab() {
    final byDay = <String, List<Booking>>{};
    for (final booking in _bookings) {
      byDay.putIfAbsent(booking.dayOfWeek, () => []).add(booking);
    }

    final sortedDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
        .where((d) => byDay.containsKey(d))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          Text(
            'Schedule by Day',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sortedDays.map((day) => _buildDayCard(day, byDay[day]!)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasConflicts = _conflicts.isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasConflicts ? Icons.warning_amber : Icons.check_circle,
                  color: hasConflicts ? Colors.orange : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasConflicts ? 'Review Required' : 'Ready to Publish',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.semester} - ${widget.schoolYear}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _stat('Classes', '${_bookings.length}'),
                _stat('Subjects', '${widget.scheduleResult.scheduledSubjects}/${widget.scheduleResult.totalSubjects}'),
                _stat(
                  'Conflicts',
                  '${_conflicts.length}',
                  color: hasConflicts ? Colors.red : Colors.green,
                ),
                _stat('Success', '${widget.scheduleResult.successRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, List<Booking> bookings) {
    bookings.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          day.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${bookings.length} classes'),
        children: bookings.map((booking) {
          final conflictIds = _conflicts
              .where((c) => c.bookingIds?.contains(booking.id) ?? false)
              .toList();

          final hasConflict = conflictIds.isNotEmpty;

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: hasConflict
                  ? Colors.red.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                booking.startTime.substring(0, 2),
                style: TextStyle(
                  color: hasConflict ? Colors.red : Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking.subjectCode} - ${booking.subjectName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasConflict ? Colors.red[700] : null,
                    ),
                  ),
                ),
                if (hasConflict)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CONFLICT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text('${booking.startTime} - ${booking.endTime}'),
            trailing: SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    booking.roomName ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    booking.teacherName ?? 'Unknown',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            onTap: () => _showEditDialog(booking),
          );
        }).toList(),
      ),
    );
  }

  // ==================== CONFLICTS TAB ====================

  Widget _buildConflictsTab() {
    if (_conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'No Conflicts!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your schedule is clean and ready to publish.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_conflicts.length} Issue(s) to Resolve',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange[900],
                        ),
                      ),
                      Text(
                        'Tap on any booking in the Preview tab to edit. Or review details below.',
                        style: TextStyle(color: Colors.orange[800], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._conflicts.map((c) => _buildConflictCard(c)),
        ],
      ),
    );
  }

  Widget _buildConflictCard(ScheduleConflict conflict) {
    final explanation = _getConflictExplanation(conflict);
    final color = _conflictColor(conflict.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(_conflictIcon(conflict.type), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _conflictTitle(conflict),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        conflict.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'What happened:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              'How to fix:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            ..._getFixSuggestions(conflict).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, color: Colors.green[600], size: 20),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getConflictExplanation(ScheduleConflict conflict) {
    switch (conflict.type) {
      case ConflictType.noEligibleTeacher:
        return 'This subject has no teacher in your selected pool who matches the requirements. '
            'Either the teacher departments don\'t match, expertise is missing, or all eligible teachers are at full capacity.';
      case ConflictType.noAvailableSlot:
        return 'The scheduler could not find any free time slot for this subject. '
            'All rooms are occupied or all teachers are busy during every available time window.';
      case ConflictType.doubleBooking:
        return 'Two different classes are scheduled in the same room at the exact same time. '
            'This happens when there aren\'t enough rooms with matching equipment/capacity.';
      case ConflictType.teacherOverlap:
        return 'A teacher is assigned to teach two different classes simultaneously. '
            'This usually means there aren\'t enough qualified teachers for the subjects.';
      case ConflictType.teacherOverload:
        final teacher = widget.teachers.firstWhere(
              (t) => t.id == conflict.teacherId,
          orElse: () => Teacher(
            id: '',
            name: 'Unknown',
            email: '',
            department: '',
            maxWeeklyHours: 0,
            expertiseSubjects: [],
          ),
        );
        return '${teacher.name} has been assigned more teaching hours than their weekly maximum '
            'of ${teacher.maxWeeklyHours} hours. This can lead to burnout and scheduling violations.';
      case ConflictType.roomOverload:
        return 'A room has been assigned more students than its capacity allows, '
            'or it is double-booked beyond its available time slots.';
    }
  }

  List<String> _getFixSuggestions(ScheduleConflict conflict) {
    switch (conflict.type) {
      case ConflictType.noEligibleTeacher:
        return [
          'Add more teachers to the selected pool who teach in the ${conflict.subjectId != null ? 'relevant department' : 'same department'}',
          'Check if any teacher\'s expertise can be updated to include this subject',
          'Reduce the number of subjects being scheduled at once',
        ];
      case ConflictType.noAvailableSlot:
        return [
          'Add more rooms to the selected pool',
          'Reduce the number of subjects or their required hours per week',
          'Try scheduling on more days of the week',
        ];
      case ConflictType.doubleBooking:
        return [
          'Tap the conflicting booking in Preview tab and change it to a different room',
          'Add more rooms of the same type to your pool',
          'Stagger the class times by moving one to an earlier/later slot',
        ];
      case ConflictType.teacherOverlap:
        return [
          'Tap the conflicting booking in Preview tab and assign a different teacher',
          'Add more qualified teachers to your pool',
          'Move one of the classes to a different time slot',
        ];
      case ConflictType.teacherOverload:
        return [
          'Tap an overloaded teacher\'s booking and reassign to another teacher',
          'Reduce the number of subjects assigned to this teacher',
          'Add more teachers who can teach these subjects',
        ];
      case ConflictType.roomOverload:
        return [
          'Move some classes to a larger room',
          'Split large classes into multiple sections',
          'Add more rooms to your pool',
        ];
    }
  }

  // ==================== AI ANALYSIS TAB ====================

  Widget _buildAIAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AISuggestionPanel(
        analysis: _aiAnalysis,
        isLoading: _isAnalyzing,
        onRefresh: _runAIAnalysis,
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _conflictColor(ConflictType type) {
    switch (type) {
      case ConflictType.noEligibleTeacher:
      case ConflictType.noAvailableSlot:
        return Colors.orange;
      case ConflictType.doubleBooking:
      case ConflictType.teacherOverlap:
        return Colors.red;
      case ConflictType.teacherOverload:
      case ConflictType.roomOverload:
        return Colors.purple;
    }
  }

  IconData _conflictIcon(ConflictType type) {
    switch (type) {
      case ConflictType.noEligibleTeacher:
        return Icons.person_off;
      case ConflictType.noAvailableSlot:
        return Icons.event_busy;
      case ConflictType.doubleBooking:
        return Icons.meeting_room;
      case ConflictType.teacherOverlap:
        return Icons.people;
      case ConflictType.teacherOverload:
        return Icons.timer_off;
      case ConflictType.roomOverload:
        return Icons.chair;
    }
  }

  String _conflictTitle(ScheduleConflict conflict) {
    switch (conflict.type) {
      case ConflictType.noEligibleTeacher:
        return 'No Eligible Teacher';
      case ConflictType.noAvailableSlot:
        return 'No Available Slot';
      case ConflictType.doubleBooking:
        return 'Room Double-Booked';
      case ConflictType.teacherOverlap:
        return 'Teacher Double-Booked';
      case ConflictType.teacherOverload:
        return 'Teacher Overloaded';
      case ConflictType.roomOverload:
        return 'Room Over capacity';
    }
  }
}