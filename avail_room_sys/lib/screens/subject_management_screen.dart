// lib/screens/subject_management_screen.dart - WEB OPTIMIZED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject_model.dart';
import '../models/room_model.dart';
import '../providers/subject_provider.dart';
import '../providers/teacher_provider.dart';
import '../widgets/responsive_layout.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final _searchController = TextEditingController();
  Subject? _selectedSubject;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isWeb(context)) {
      return _buildWebLayout();
    }

    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                _buildWebHeader(),
                _buildSearchField(),
                Expanded(child: _buildSubjectList()),
              ],
            ),
          ),
          Expanded(
            child: _selectedSubject != null
                ? _buildSubjectDetail(_selectedSubject!)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Subjects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSubjectDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Select a subject to view details', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDetail(Subject subject) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.book, size: 40, color: Colors.purple),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${subject.code} - ${subject.name}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subject.department,
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(label: Text('${subject.units} Units')),
                                  Chip(label: Text('${subject.requiredHoursPerWeek} hrs/week')),
                                  Chip(label: Text(subject.preferredRoomType.name)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showSubjectDialog(subject: subject),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(subject),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 48),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard('Max Students', '${subject.maxStudents}', 'Capacity', Colors.blue),
                        _buildStatCard('Equipment', '${subject.requiredEquipment.length}', 'Items', Colors.orange),
                      ],
                    ),
                    if (subject.requiredEquipment.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('Required Equipment', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subject.requiredEquipment.map((e) => Chip(
                          label: Text(e),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // Keep existing methods but use _buildSubjectListItem for web
  Widget _buildSubjectList() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (subjectProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${subjectProvider.error}'),
                ElevatedButton(onPressed: () => subjectProvider.refresh(), child: const Text('Retry')),
              ],
            ),
          );
        }

        final subjects = _searchController.text.isEmpty
            ? subjectProvider.subjects
            : subjectProvider.searchSubjects(_searchController.text);

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(_searchController.text.isEmpty ? 'No subjects added yet' : 'No matching subjects'),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showSubjectDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Subject'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final isSelected = _selectedSubject?.id == subject.id;
            return _buildSubjectListItem(subject, isSelected);
          },
        );
      },
    );
  }

  Widget _buildSubjectListItem(Subject subject, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      color: isSelected ? Colors.purple.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: () => setState(() => _selectedSubject = subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: const Icon(Icons.book, size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${subject.code}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.department} • ${subject.requiredHoursPerWeek}h',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectDialog({Subject? subject}) {
    final isEditing = subject != null;
    // ... keep existing dialog code but wrap in Dialog with constraints like teacher dialog
    final codeController = TextEditingController(text: subject?.code ?? '');
    final nameController = TextEditingController(text: subject?.name ?? '');
    final departmentController = TextEditingController(text: subject?.department ?? '');
    final unitsController = TextEditingController(text: subject?.units.toString() ?? '3');
    final hoursController = TextEditingController(text: subject?.requiredHoursPerWeek.toString() ?? '3');
    final maxStudentsController = TextEditingController(text: subject?.maxStudents.toString() ?? '30');

    RoomType selectedRoomType = subject?.preferredRoomType ?? RoomType.lecture;
    List<String> selectedEquipment = List.from(subject?.requiredEquipment ?? []);
    List<String> selectedEligibleTeachers = List.from(subject?.eligibleTeachers ?? []);

    final equipmentOptions = ['Projector', 'Computers', 'Lab Equipment', 'Whiteboard', 'Mic', 'TV', 'Video Conf', 'Fume Hood', 'Chemistry Equipment', 'AC'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(isEditing ? 'Edit Subject' : 'Add New Subject', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code *', prefixIcon: Icon(Icons.code)))),
                            const SizedBox(width: 16),
                            Expanded(child: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.book)))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(controller: departmentController, decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.business))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: unitsController, decoration: const InputDecoration(labelText: 'Units'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: TextField(controller: hoursController, decoration: const InputDecoration(labelText: 'Hours/Week'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: TextField(controller: maxStudentsController, decoration: const InputDecoration(labelText: 'Max Students'), keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<RoomType>(
                          value: selectedRoomType,
                          decoration: const InputDecoration(labelText: 'Room Type', prefixIcon: Icon(Icons.meeting_room)),
                          items: RoomType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) => setDialogState(() => selectedRoomType = v!),
                        ),
                        const SizedBox(height: 24),
                        Text('Equipment', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: equipmentOptions.map((eq) => FilterChip(
                            label: Text(eq),
                            selected: selectedEquipment.contains(eq),
                            onSelected: (s) => setDialogState(() => s ? selectedEquipment.add(eq) : selectedEquipment.remove(eq)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (codeController.text.isEmpty || nameController.text.isEmpty || departmentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                            return;
                          }
                          final provider = Provider.of<SubjectProvider>(context, listen: false);
                          final newSubject = Subject(
                            id: subject?.id ?? '',
                            code: codeController.text.trim(),
                            name: nameController.text.trim(),
                            department: departmentController.text.trim(),
                            units: int.tryParse(unitsController.text) ?? 3,
                            requiredHoursPerWeek: int.tryParse(hoursController.text) ?? 3,
                            preferredRoomType: selectedRoomType,
                            requiredEquipment: selectedEquipment,
                            maxStudents: int.tryParse(maxStudentsController.text) ?? 30,
                            eligibleTeachers: selectedEligibleTeachers,
                          );
                          try {
                            if (isEditing) await provider.updateSubject(newSubject.copyWith(id: subject!.id));
                            else await provider.addSubject(newSubject);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Updated' : 'Added'), backgroundColor: Colors.green));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        },
                        child: Text(isEditing ? 'Update' : 'Add'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Delete ${subject.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<SubjectProvider>(context, listen: false);
              try {
                await provider.deleteSubject(subject.id);
                if (_selectedSubject?.id == subject.id) setState(() => _selectedSubject = null);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for non-web layouts
  Widget _buildMobileLayout() => Scaffold(appBar: AppBar(title: const Text('Subjects')), body: _buildSubjectList());
  Widget _buildTabletLayout() => Scaffold(appBar: AppBar(title: const Text('Subjects')), body: Row(children: [SizedBox(width: 350, child: _buildSubjectList()), Expanded(child: Container(color: Colors.grey[100]))]));
  Widget _buildDesktopLayout() => _buildWebLayout();
}