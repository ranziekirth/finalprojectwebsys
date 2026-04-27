// lib/screens/auto_scheduler_screen.dart - CLEAN VERSION
import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../services/scheduler_service.dart';
import '../services/firestore_service.dart';
import '../widgets/responsive_layout.dart';
import 'schedule_result_screen.dart';

class AutoSchedulerScreen extends StatefulWidget {
  const AutoSchedulerScreen({Key? key}) : super(key: key);

  @override
  State<AutoSchedulerScreen> createState() => _AutoSchedulerScreenState();
}

class _AutoSchedulerScreenState extends State<AutoSchedulerScreen> {
  final SchedulerService _scheduler = SchedulerService();
  final FirestoreService _firestore = FirestoreService();

  List<Subject> _subjects = [];
  List<Room> _rooms = [];
  List<Teacher> _teachers = [];

  List<String> _selectedSubjectIds = [];
  List<String> _selectedRoomIds = [];
  List<String> _selectedTeacherIds = [];

  String _semester = 'First Semester';
  String _schoolYear = '2024-2025';
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _firestore.getSubjects();
      final rooms = await _firestore.getRooms();
      final teachers = await _firestore.getTeachers();

      setState(() {
        _subjects = subjects;
        _rooms = rooms;
        _teachers = teachers;
        _selectedSubjectIds = subjects.map((s) => s.id).toList();
        _selectedRoomIds = rooms.map((r) => r.id).toList();
        _selectedTeacherIds = teachers.map((t) => t.id).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSchedule() async {
    if (_selectedSubjectIds.isEmpty ||
        _selectedRoomIds.isEmpty ||
        _selectedTeacherIds.isEmpty) {
      _showSnackBar('Please select at least one subject, room, and teacher', Colors.orange);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await _scheduler.generateSchedule(
        semester: _semester,
        schoolYear: _schoolYear,
        selectedSubjectIds: _selectedSubjectIds,
        selectedRoomIds: _selectedRoomIds,
        selectedTeacherIds: _selectedTeacherIds,
      );

      if (!mounted) return;

      // Navigate to Result Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleResultScreen(
            scheduleResult: result,
            semester: _semester,
            schoolYear: _schoolYear,
            rooms: _rooms,
            teachers: _teachers,
            subjects: _subjects,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
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
      appBar: AppBar(title: const Text('Auto Scheduler')),
      body: _buildContent(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 350, child: _buildConfigurationPanel()),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_fix_high, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Configure and generate schedule',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 380, child: _buildConfigurationPanel()),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 24),
                        Text(
                          'Auto Scheduler',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select subjects, rooms, and teachers, then click Generate',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
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
            'Auto Scheduler',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildConfigurationPanel(),
    );
  }

  Widget _buildConfigurationPanel() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _semester,
                      decoration: const InputDecoration(labelText: 'Semester'),
                      items: ['First Semester', 'Second Semester', 'Summer']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _schoolYear,
                      decoration: const InputDecoration(labelText: 'School Year'),
                      onChanged: (v) => _schoolYear = v,
                    ),
                    const SizedBox(height: 24),
                    _buildSelectionSection(
                      title: 'Subjects (${_selectedSubjectIds.length}/${_subjects.length})',
                      items: _subjects
                          .map((s) => _SelectionItem(
                        id: s.id,
                        label: '${s.code} - ${s.name}',
                        subtitle: '${s.requiredHoursPerWeek} hrs/week • ${s.department}',
                      ))
                          .toList(),
                      selectedIds: _selectedSubjectIds,
                      onToggle: (id) => setState(() {
                        _selectedSubjectIds.contains(id)
                            ? _selectedSubjectIds.remove(id)
                            : _selectedSubjectIds.add(id);
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionSection(
                      title: 'Rooms (${_selectedRoomIds.length}/${_rooms.length})',
                      items: _rooms
                          .map((r) => _SelectionItem(
                        id: r.id,
                        label: r.name,
                        subtitle: '${r.building} • ${r.capacity} seats • ${r.type.name}',
                      ))
                          .toList(),
                      selectedIds: _selectedRoomIds,
                      onToggle: (id) => setState(() {
                        _selectedRoomIds.contains(id)
                            ? _selectedRoomIds.remove(id)
                            : _selectedRoomIds.add(id);
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionSection(
                      title: 'Teachers (${_selectedTeacherIds.length}/${_teachers.length})',
                      items: _teachers
                          .map((t) => _SelectionItem(
                        id: t.id,
                        label: t.name,
                        subtitle: '${t.department} • Max ${t.maxWeeklyHours}h/week',
                      ))
                          .toList(),
                      selectedIds: _selectedTeacherIds,
                      onToggle: (id) => setState(() {
                        _selectedTeacherIds.contains(id)
                            ? _selectedTeacherIds.remove(id)
                            : _selectedTeacherIds.add(id);
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateSchedule,
                        icon: _isGenerating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.auto_fix_high),
                        label: Text(_isGenerating ? 'Optimizing...' : 'Generate Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
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

  Widget _buildSelectionSection({
    required String title,
    required List<_SelectionItem> items,
    required List<String> selectedIds,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (selectedIds.length == items.length) {
                  selectedIds.clear();
                } else {
                  selectedIds.clear();
                  selectedIds.addAll(items.map((i) => i.id));
                }
              }),
              child: Text(selectedIds.length == items.length ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIds.contains(item.id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => onToggle(item.id),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.subtitle ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionItem {
  final String id;
  final String label;
  final String? subtitle;
  _SelectionItem({required this.id, required this.label, this.subtitle});
}