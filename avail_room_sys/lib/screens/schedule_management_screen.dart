// lib/screens/schedule_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart'; // ← ADD THIS
import '../theme/app_theme.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final FirestoreService _firestore = FirestoreService();

  // Data
  List<Booking> _allBookings = [];
  List<Room> _rooms = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];

  // Filters
  String? _selectedDay;
  String? _selectedRoomId;
  String? _selectedTeacherId;
  String? _selectedStatus;
  String _searchQuery = '';

  // UI State
  bool _isLoading = true;
  bool _isBulkMode = false;
  final Set<String> _selectedBookingIds = {};
  String? _sortColumn;
  bool _sortAscending = true;

  // Pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _firestore.getBookings();
      final rooms = await _firestore.getRooms();
      final teachers = await _firestore.getTeachers();
      final subjects = await _firestore.getSubjects();

      setState(() {
        _allBookings = bookings;
        _rooms = rooms;
        _teachers = teachers;
        _subjects = subjects;
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== FILTERING ====================

  List<Booking> get _filteredBookings {
    return _allBookings.where((booking) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = (booking.subjectName?.toLowerCase().contains(q) ?? false) ||
            (booking.subjectCode?.toLowerCase().contains(q) ?? false) ||
            (booking.teacherName?.toLowerCase().contains(q) ?? false) ||
            (booking.roomName?.toLowerCase().contains(q) ?? false) ||
            booking.dayOfWeek.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_selectedDay != null && booking.dayOfWeek != _selectedDay) return false;
      if (_selectedRoomId != null && booking.roomId != _selectedRoomId) return false;
      if (_selectedTeacherId != null && booking.teacherId != _selectedTeacherId) return false;
      if (_selectedStatus != null && booking.status.name != _selectedStatus) return false;
      return true;
    }).toList();
  }

  List<Booking> get _sortedBookings {
    final filtered = _filteredBookings;
    if (_sortColumn == null) return filtered;

    filtered.sort((a, b) {
      dynamic aVal, bVal;
      switch (_sortColumn) {
        case 'day':
          aVal = a.dayOfWeek;
          bVal = b.dayOfWeek;
          break;
        case 'time':
          aVal = a.startTime;
          bVal = b.startTime;
          break;
        case 'subject':
          aVal = a.subjectCode ?? '';
          bVal = b.subjectCode ?? '';
          break;
        case 'teacher':
          aVal = a.teacherName ?? '';
          bVal = b.teacherName ?? '';
          break;
        case 'room':
          aVal = a.roomName ?? '';
          bVal = b.roomName ?? '';
          break;
        case 'status':
          aVal = a.status.name;
          bVal = b.status.name;
          break;
        default:
          return 0;
      }
      return _sortAscending
          ? aVal.toString().compareTo(bVal.toString())
          : bVal.toString().compareTo(aVal.toString());
    });
    return filtered;
  }

  List<Booking> get _paginatedBookings {
    final sorted = _sortedBookings;
    final start = _currentPage * _rowsPerPage;
    if (start >= sorted.length) return [];
    final end = (start + _rowsPerPage).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  // ==================== CONFLICT DETECTION ====================

  bool _hasConflict(Booking booking) {
    return _allBookings.any((other) {
      if (other.id == booking.id) return false;
      if (other.dayOfWeek != booking.dayOfWeek) return false;
      if (other.startTime != booking.startTime) return false;
      return (other.roomId == booking.roomId) || (other.teacherId == booking.teacherId);
    });
  }

  // ==================== EDIT DIALOG ====================

  void _showEditDialog(Booking booking) {
    final currentRoom = _rooms.firstWhere(
          (r) => r.id == booking.roomId,
      orElse: () => Room(
        id: '',
        name: 'Unknown Room',
        building: '',
        floor: '',
        capacity: 0,
        type: RoomType.lecture,
        equipment: [],
      ),
    );

    final currentSubject = _subjects.firstWhere(
          (s) => s.id == booking.subjectId,
      orElse: () => Subject(
        id: '',
        code: 'N/A',
        name: 'Unknown Subject',
        department: '',
        units: 0,
        requiredHoursPerWeek: 0,
        preferredRoomType: RoomType.lecture,
        requiredEquipment: [],
      ),
    );

    final currentTeacher = _teachers.firstWhere(
          (t) => t.id == booking.teacherId,
      orElse: () => Teacher(
        id: '',
        name: 'Unknown Teacher',
        email: '',
        department: '',
        expertiseSubjects: [],
      ),
    );

    final dayController = TextEditingController(text: booking.dayOfWeek);
    final startController = TextEditingController(text: booking.startTime);
    final endController = TextEditingController(text: booking.endTime);
    final notesController = TextEditingController(text: booking.notes ?? '');

    String selectedRoomId = booking.roomId;
    String selectedTeacherId = booking.teacherId;
    BookingStatus selectedStatus = booking.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit: ${booking.subjectCode}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSubject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${currentSubject.code} • ${currentSubject.department} • ${currentSubject.units} units',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoomId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(),
                  ),
                  items: _rooms.where((r) {
                    return r.capacity >= currentSubject.maxStudents &&
                        (r.type == currentSubject.preferredRoomType ||
                            currentSubject.preferredRoomType == RoomType.lecture);
                  }).map((r) {
                    final isCurrent = r.id == booking.roomId;
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        '${r.name} (${r.capacity} seats)${isCurrent ? ' • CURRENT' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedRoomId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTeacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: _teachers.where((t) {
                    final load = _calculateTeacherLoad(t.id);
                    return t.id == booking.teacherId ||
                        (load + currentSubject.requiredHoursPerWeek <= t.maxWeeklyHours);
                  }).map((t) {
                    final load = _calculateTeacherLoad(t.id);
                    final isCurrent = t.id == booking.teacherId;
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        '${t.name} (${load.toStringAsFixed(1)}/${t.maxWeeklyHours}h)${isCurrent ? ' • CURRENT' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedTeacherId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: dayController.text,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                  items: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
                      .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (v) => dayController.text = v!,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: endController,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BookingStatus>(
                  value: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: BookingStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        _statusDot(s),
                        const SizedBox(width: 8),
                        Text(s.name.toUpperCase()),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newRoom = _rooms.firstWhere(
                      (r) => r.id == selectedRoomId,
                  orElse: () => currentRoom,
                );
                final newTeacher = _teachers.firstWhere(
                      (t) => t.id == selectedTeacherId,
                  orElse: () => currentTeacher,
                );

                final updated = Booking(
                  id: booking.id,
                  roomId: selectedRoomId,
                  teacherId: selectedTeacherId,
                  subjectId: booking.subjectId,
                  dayOfWeek: dayController.text,
                  startTime: startController.text,
                  endTime: endController.text,
                  semester: booking.semester,
                  schoolYear: booking.schoolYear,
                  status: selectedStatus,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  createdBy: booking.createdBy,
                  roomName: newRoom.name,
                  teacherName: newTeacher.name,
                  subjectName: booking.subjectName,
                  subjectCode: booking.subjectCode,
                );

                try {
                  await _firestore.updateBooking(updated);
                  if (context.mounted) Navigator.pop(context);
                  _showSnackBar('Booking updated successfully', Colors.green);
                  _loadData();
                } catch (e) {
                  _showSnackBar('Error: $e', Colors.red);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DELETE ====================

  Future<void> _deleteBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking?'),
        content: Text(
          'Are you sure you want to delete ${booking.subjectCode} on ${booking.dayOfWeek}?\n\n'
              'Room: ${booking.roomName}\n'
              'Teacher: ${booking.teacherName}\n'
              'Time: ${booking.startTime} - ${booking.endTime}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.deleteBooking(booking.id);
        _showSnackBar('Booking deleted', Colors.green);
        _loadData();
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  // ==================== BULK ACTIONS ====================

  Future<void> _bulkDelete() async {
    final count = _selectedBookingIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count Bookings?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete $count'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final id in _selectedBookingIds) {
          batch.delete(_firestore.bookingsCollection.doc(id));
        }
        await batch.commit();
        _showSnackBar('$count bookings deleted', Colors.green);
        setState(() {
          _selectedBookingIds.clear();
          _isBulkMode = false;
        });
        _loadData();
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  // ==================== EXPORT PDF ====================

  Future<void> _exportSchedulePdf() async {
    // Check if there's data to export
    if (_allBookings.isEmpty) {
      _showSnackBar('No schedule data available to export.', Colors.orange);
      return;
    }

    // Determine semester/school year from the data or use defaults
    final semester = _allBookings.first.semester.isNotEmpty
        ? _allBookings.first.semester
        : 'Current Semester';
    final schoolYear = _allBookings.first.schoolYear.isNotEmpty
        ? _allBookings.first.schoolYear
        : 'Current Year';

    // Filter active bookings only (optional — remove if you want all statuses)
    final exportBookings = _allBookings
        .where((b) => b.status != BookingStatus.cancelled)
        .toList();

    if (exportBookings.isEmpty) {
      _showSnackBar('No active bookings to export.', Colors.orange);
      return;
    }

    try {
      await PdfService.exportSemesterSchedule(
        context: context,
        bookings: exportBookings,
        rooms: _rooms,
        teachers: _teachers,
        semester: semester,
        schoolYear: schoolYear,
        schoolName: 'Your School Name', // ← CHANGE THIS TO YOUR SCHOOL NAME
      );
    } catch (e) {
      _showSnackBar('Failed to export PDF: $e', Colors.red);
    }
  }

  Future<void> _bulkChangeStatus(BookingStatus status) async {
    final count = _selectedBookingIds.length;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedBookingIds) {
        batch.update(_firestore.bookingsCollection.doc(id), {
          'status': status.name,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      _showSnackBar('$count bookings marked as ${status.name}', Colors.green);
      setState(() {
        _selectedBookingIds.clear();
        _isBulkMode = false;
      });
      _loadData();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  // ==================== HELPERS ====================

  double _calculateTeacherLoad(String teacherId) {
    return _allBookings
        .where((b) => b.teacherId == teacherId && b.status != BookingStatus.cancelled)
        .fold(0.0, (sum, b) => sum + _hours(b.startTime, b.endTime));
  }

  double _hours(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    return (int.parse(e[0]) * 60 + int.parse(e[1]) - int.parse(s[0]) * 60 - int.parse(s[1])) / 60.0;
  }

  // ==================== UI BUILDERS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(child: _buildDataTable()),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Text(
            'Schedule Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),

          // ─── EXPORT PDF BUTTON (NEW) ───
          ElevatedButton.icon(
            onPressed: _exportSchedulePdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC41E3A), // School Red
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // ────────────────────────────────

          if (_isBulkMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedBookingIds.length} selected',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                label: const Text('Bulk Actions', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text('Mark Cancelled'),
                    ],
                  ),
                  onTap: () => _bulkChangeStatus(BookingStatus.cancelled),
                ),
                PopupMenuItem(
                  value: 'active',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('Mark Active'),
                    ],
                  ),
                  onTap: () => _bulkChangeStatus(BookingStatus.active),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      const Text('Delete Selected'),
                    ],
                  ),
                  onTap: _bulkDelete,
                ),
              ],
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => setState(() {
                _isBulkMode = false;
                _selectedBookingIds.clear();
              }),
              icon: const Icon(Icons.close),
              label: const Text('Done'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => setState(() => _isBulkMode = true),
              icon: const Icon(Icons.checklist),
              label: const Text('Bulk Select'),
            ),
          ],
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _currentPage = 0;
              }),
            ),
          ),
          _buildFilterDropdown(
            value: _selectedDay,
            hint: 'All Days',
            items: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
            displayMapper: (v) => v.toUpperCase(),
            onChanged: (v) => setState(() {
              _selectedDay = v;
              _currentPage = 0;
            }),
          ),
          _buildFilterDropdown(
            value: _selectedRoomId,
            hint: 'All Rooms',
            items: _rooms.map((r) => r.id).toList(),
            displayMapper: (id) => _rooms.firstWhere(
                  (r) => r.id == id,
              orElse: () => Room(id: '', name: 'Unknown', building: '', floor: '', capacity: 0, type: RoomType.lecture, equipment: []),
            ).name,
            onChanged: (v) => setState(() {
              _selectedRoomId = v;
              _currentPage = 0;
            }),
          ),
          _buildFilterDropdown(
            value: _selectedTeacherId,
            hint: 'All Teachers',
            items: _teachers.map((t) => t.id).toList(),
            displayMapper: (id) => _teachers.firstWhere(
                  (t) => t.id == id,
              orElse: () => Teacher(id: '', name: 'Unknown', email: '', department: '', expertiseSubjects: []),
            ).name,
            onChanged: (v) => setState(() {
              _selectedTeacherId = v;
              _currentPage = 0;
            }),
          ),
          _buildFilterDropdown(
            value: _selectedStatus,
            hint: 'All Status',
            items: BookingStatus.values.map((s) => s.name).toList(),
            displayMapper: (v) => v.toUpperCase(),
            onChanged: (v) => setState(() {
              _selectedStatus = v;
              _currentPage = 0;
            }),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedDay = null;
              _selectedRoomId = null;
              _selectedTeacherId = null;
              _selectedStatus = null;
              _searchQuery = '';
              _currentPage = 0;
            }),
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredBookings.length} results',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required String Function(String) displayMapper,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          items: [
            DropdownMenuItem(value: null, child: Text(hint)),
            ...items.map((i) => DropdownMenuItem(
              value: i,
              child: Text(displayMapper(i), overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bookings = _paginatedBookings;
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _allBookings.isEmpty ? 'No schedules yet' : 'No results match your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            // FIXED: Removed dataRowMinHeight - let Flutter handle row height naturally
            columns: [
              if (_isBulkMode)
                DataColumn(
                  label: Checkbox(
                    value: _selectedBookingIds.length == bookings.length && bookings.isNotEmpty,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedBookingIds.addAll(bookings.map((b) => b.id));
                      } else {
                        _selectedBookingIds.clear();
                      }
                    }),
                  ),
                ),
              _buildSortableColumn('Day', 'day'),
              _buildSortableColumn('Time', 'time'),
              _buildSortableColumn('Subject', 'subject'),
              _buildSortableColumn('Teacher', 'teacher'),
              _buildSortableColumn('Room', 'room'),
              const DataColumn(label: Text('Status')),
              const DataColumn(label: Text('Actions')),
            ],
            rows: bookings.map((booking) => _buildDataRow(booking)).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildSortableColumn(String label, String column) {
    final isSorted = _sortColumn == column;
    return DataColumn(
      label: InkWell(
        onTap: () => setState(() {
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = true;
          }
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSorted ? FontWeight.bold : FontWeight.w500,
                color: isSorted ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            if (isSorted)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(Booking booking) {
    final hasConflict = _hasConflict(booking);
    final isSelected = _selectedBookingIds.contains(booking.id);

    return DataRow(
      selected: isSelected,
      color: hasConflict
          ? MaterialStateProperty.all(Colors.red.withOpacity(0.05))
          : null,
      cells: [
        if (_isBulkMode)
          DataCell(
            Checkbox(
              value: isSelected,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedBookingIds.add(booking.id);
                } else {
                  _selectedBookingIds.remove(booking.id);
                }
              }),
            ),
          ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(booking.dayOfWeek.toUpperCase()),
              if (hasConflict)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'CONFLICT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text('${booking.startTime} - ${booking.endTime}')),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                booking.subjectCode ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                booking.subjectName ?? 'Unknown',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        DataCell(Text(booking.teacherName ?? 'Unknown')),
        DataCell(Text(booking.roomName ?? 'Unknown')),
        DataCell(_buildStatusChip(booking.status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[600], size: 20),
                onPressed: () => _showEditDialog(booking),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                onPressed: () => _deleteBooking(booking),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    final colors = {
      BookingStatus.active: Colors.green,
      BookingStatus.cancelled: Colors.red,
      BookingStatus.completed: Colors.blue,
      BookingStatus.pending: Colors.orange,
    };
    final color = colors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _statusDot(BookingStatus status) {
    final colors = {
      BookingStatus.active: Colors.green,
      BookingStatus.cancelled: Colors.red,
      BookingStatus.completed: Colors.blue,
      BookingStatus.pending: Colors.orange,
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPaginationBar() {
    final total = _filteredBookings.length;
    final totalPages = total == 0 ? 1 : (total / _rowsPerPage).ceil();
    final start = total == 0 ? 0 : _currentPage * _rowsPerPage + 1;
    final end = total == 0 ? 0 : (_currentPage + 1) * _rowsPerPage;
    final actualEnd = end > total ? total : end;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Text(
            total > 0 ? 'Showing $start-$actualEnd of $total' : 'No results',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              items: [10, 25, 50, 100]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v rows')))
                  .toList(),
              onChanged: (v) => setState(() {
                _rowsPerPage = v!;
                _currentPage = 0;
              }),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: TextStyle(color: Colors.grey[700]),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage = totalPages - 1)
                : null,
          ),
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
}