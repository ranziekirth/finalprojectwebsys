import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _institutionNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _schoolYearController = TextEditingController(text: '2024-2025');

  // State values
  String _currentSemester = 'First Semester';
  List<String> _workingDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  TimeOfDay _dayStartTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _dayEndTime = const TimeOfDay(hour: 18, minute: 0);
  int _slotDurationMinutes = 90;
  int _breakDurationMinutes = 0;
  int _defaultMaxTeacherHours = 20;

  static const _allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  static const _dayLabels = {'monday': 'Mon', 'tuesday': 'Tue', 'wednesday': 'Wed', 'thursday': 'Thu', 'friday': 'Fri', 'saturday': 'Sat'};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _institutionNameController.dispose();
    _addressController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firestore.getSettings();
      if (settings != null && mounted) {
        setState(() {
          _institutionNameController.text = settings['institutionName'] ?? '';
          _addressController.text = settings['address'] ?? '';
          _schoolYearController.text = settings['schoolYear'] ?? '2024-2025';
          _currentSemester = settings['currentSemester'] ?? 'First Semester';
          _workingDays = List<String>.from(
              settings['workingDays'] ?? ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']);
          _slotDurationMinutes = settings['slotDurationMinutes'] ?? 90;
          _breakDurationMinutes = settings['breakDurationMinutes'] ?? 0;
          _defaultMaxTeacherHours = settings['defaultMaxTeacherHours'] ?? 20;
          if (settings['dayStartTime'] != null) {
            final p = (settings['dayStartTime'] as String).split(':');
            _dayStartTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
          }
          if (settings['dayEndTime'] != null) {
            final p = (settings['dayEndTime'] as String).split(':');
            _dayEndTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.saveSettings({
        'institutionName': _institutionNameController.text.trim(),
        'address': _addressController.text.trim(),
        'schoolYear': _schoolYearController.text.trim(),
        'currentSemester': _currentSemester,
        'workingDays': _workingDays,
        'dayStartTime': _formatTime(_dayStartTime),
        'dayEndTime': _formatTime(_dayEndTime),
        'slotDurationMinutes': _slotDurationMinutes,
        'breakDurationMinutes': _breakDurationMinutes,
        'defaultMaxTeacherHours': _defaultMaxTeacherHours,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<String> _generateSlotPreviews() {
    final slots = <String>[];
    var cur = _dayStartTime.hour * 60 + _dayStartTime.minute;
    final end = _dayEndTime.hour * 60 + _dayEndTime.minute;
    while (cur + _slotDurationMinutes <= end) {
      final slotEnd = cur + _slotDurationMinutes;
      final sH = (cur ~/ 60).toString().padLeft(2, '0');
      final sM = (cur % 60).toString().padLeft(2, '0');
      final eH = (slotEnd ~/ 60).toString().padLeft(2, '0');
      final eM = (slotEnd % 60).toString().padLeft(2, '0');
      slots.add('$sH:$sM – $eH:$eM');
      cur = slotEnd + _breakDurationMinutes;
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 28),
              _buildSectionCard(
                icon: Icons.school_rounded,
                title: 'Institution Information',
                color: Colors.blue,
                children: [
                  TextField(
                    controller: _institutionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Institution Name',
                      hintText: 'e.g., De La Salle University',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Academic Calendar',
                color: Colors.green,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _currentSemester,
                          decoration: const InputDecoration(
                            labelText: 'Current Semester',
                            border: OutlineInputBorder(),
                          ),
                          items: ['First Semester', 'Second Semester', 'Summer']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _currentSemester = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _schoolYearController,
                          decoration: const InputDecoration(
                            labelText: 'School Year',
                            hintText: '2024-2025',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Working Days',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDays.map((day) {
                      final selected = _workingDays.contains(day);
                      return FilterChip(
                        label: Text(_dayLabels[day]!),
                        selected: selected,
                        selectedColor: Colors.green.withOpacity(0.15),
                        checkmarkColor: Colors.green[700],
                        onSelected: (v) => setState(() {
                          if (v) {
                            _workingDays.add(day);
                          } else {
                            _workingDays.remove(day);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                icon: Icons.schedule_rounded,
                title: 'Schedule Configuration',
                color: Colors.orange,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimePicker(
                              'Day Start Time', _dayStartTime, (t) => setState(() => _dayStartTime = t))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTimePicker(
                              'Day End Time', _dayEndTime, (t) => setState(() => _dayEndTime = t))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _slotDurationMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Slot Duration',
                            border: OutlineInputBorder(),
                          ),
                          items: [60, 90, 120]
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                              .toList(),
                          onChanged: (v) => setState(() => _slotDurationMinutes = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _breakDurationMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Break Between Slots',
                            border: OutlineInputBorder(),
                          ),
                          items: [0, 10, 15, 30]
                              .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m == 0 ? 'No break' : '$m minutes'),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _breakDurationMinutes = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSlotPreview(),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                icon: Icons.people_rounded,
                title: 'Teacher Load Defaults',
                color: Colors.purple,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Default Max Weekly Hours',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_defaultMaxTeacherHours hrs/week',
                          style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _defaultMaxTeacherHours.toDouble(),
                    min: 6,
                    max: 40,
                    divisions: 34,
                    activeColor: Colors.purple,
                    label: '$_defaultMaxTeacherHours hrs',
                    onChanged: (v) => setState(() => _defaultMaxTeacherHours = v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('6 hrs', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      Text('40 hrs', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save All Settings',
                      style: const TextStyle(fontSize: 15)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Configure your scheduling system preferences',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveSettings,
          icon: _isSaving
              ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded),
          label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(_formatTime(time), style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildSlotPreview() {
    final slots = _generateSlotPreviews();
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, size: 16, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text('No valid time slots with current configuration.',
                style: TextStyle(color: Colors.red[700], fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, size: 16, color: Colors.orange[600]),
            const SizedBox(width: 6),
            Text(
              'Preview: ${slots.length} time slot${slots.length == 1 ? '' : 's'} generated',
              style: TextStyle(
                  color: Colors.orange[700], fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots
              .map((s) => Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(s,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ))
              .toList(),
        ),
      ],
    );
  }
}