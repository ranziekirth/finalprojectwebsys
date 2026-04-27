// lib/screens/teacher_management_screen.dart - WEB OPTIMIZED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/teacher_model.dart';
import '../providers/teacher_provider.dart';
import '../widgets/responsive_layout.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final _searchController = TextEditingController();
  Teacher? _selectedTeacher;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force desktop layout for web to prevent overflow
    if (ResponsiveLayout.isWeb(context)) {
      return _buildWebLayout();
    }

    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // NEW: Dedicated web layout with overflow protection
  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - fixed width
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
                Expanded(child: _buildTeacherList()),
              ],
            ),
          ),
          // Right content - flexible with scroll
          Expanded(
            child: _selectedTeacher != null
                ? _buildTeacherDetail(_selectedTeacher!)
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
              'Teachers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeacherDialog(),
            tooltip: 'Add Teacher',
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
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a teacher to view details',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDetail(Teacher teacher) {
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
                    // Header with actions
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teacher.email,
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(teacher.department),
                                backgroundColor: Colors.blue[50],
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showTeacherDialog(teacher: teacher),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(teacher),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 48),
                    // Stats grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isNarrow ? double.infinity : 200,
                              child: _buildStatCard(
                                'Weekly Hours',
                                '${teacher.currentWeeklyHours}/${teacher.maxWeeklyHours}',
                                '${teacher.loadPercentage.toStringAsFixed(0)}%',
                                teacher.isOverloaded() ? Colors.red : Colors.green,
                              ),
                            ),
                            SizedBox(
                              width: isNarrow ? double.infinity : 200,
                              child: _buildStatCard(
                                'Active Subjects',
                                '${teacher.activeSubjectsCount}',
                                'Assigned',
                                Colors.blue,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Expertise section
                    Text('Expertise', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teacher.expertiseSubjects.map((s) => Chip(
                        label: Text(s),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      )).toList(),
                    ),
                    if (teacher.preferredTimeSlots.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text('Preferred Time Slots', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: teacher.preferredTimeSlots.map((t) => Chip(
                          avatar: Icon(Icons.access_time, size: 18),
                          label: Text(t),
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

  // Keep existing mobile/tablet layouts
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeacherDialog(),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 350,
            child: _buildTeacherListPanel(),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: const Center(child: Text('Select a teacher')),
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
          SizedBox(
            width: 380,
            child: _buildTeacherListPanel(),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: const Center(child: Text('Select a teacher')),
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            'Teacher Management',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showTeacherDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Teacher'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search teachers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(child: _buildTeacherList()),
      ],
    );
  }

  Widget _buildTeacherListPanel() {
    return Column(
      children: [
        if (!ResponsiveLayout.isWeb(context) && ResponsiveLayout.isDesktop(context))
          _buildDesktopHeader(),
        if (ResponsiveLayout.isWeb(context)) _buildWebHeader(),
        if (!ResponsiveLayout.isWeb(context))
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
        Expanded(child: _buildTeacherList()),
      ],
    );
  }

  Widget _buildTeacherList() {
    return Consumer<TeacherProvider>(
      builder: (context, teacherProvider, child) {
        if (teacherProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teacherProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${teacherProvider.error}'),
                ElevatedButton(
                  onPressed: () => teacherProvider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final teachers = _searchController.text.isEmpty
            ? teacherProvider.teachers
            : teacherProvider.searchTeachers(_searchController.text);

        if (teachers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty ? 'No teachers added yet' : 'No matching teachers',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                if (_searchController.text.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showTeacherDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Teacher'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            final isSelected = _selectedTeacher?.id == teacher.id;
            return _buildTeacherListItem(teacher, isSelected);
          },
        );
      },
    );
  }

  // FIXED: Compact list item for web sidebar
  Widget _buildTeacherListItem(Teacher teacher, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: () => setState(() => _selectedTeacher = teacher),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        teacher.department,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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

  void _showTeacherDialog({Teacher? teacher}) {
    final isEditing = teacher != null;
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final departmentController = TextEditingController(text: teacher?.department ?? '');
    final maxHoursController = TextEditingController(text: teacher?.maxWeeklyHours.toString() ?? '20');

    List<String> expertiseSubjects = List.from(teacher?.expertiseSubjects ?? []);
    List<String> preferredTimeSlots = List.from(teacher?.preferredTimeSlots ?? ['morning']);

    final timeOptions = ['morning', 'afternoon', 'evening'];
    final expertiseController = TextEditingController();

    // FIXED: Use AlertDialog with constrained size for web
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close on web
      builder: (context) => Dialog(
        // Use Dialog instead of AlertDialog for better web sizing
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 700,
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        isEditing ? 'Edit Teacher' : 'Add New Teacher',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department *',
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: maxHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Max Weekly Hours',
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        Text('Expertise Subjects', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: expertiseController,
                                decoration: const InputDecoration(
                                  hintText: 'Add subject and press Enter',
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    setDialogState(() {
                                      expertiseSubjects.add(value);
                                      expertiseController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (expertiseController.text.isNotEmpty) {
                                  setDialogState(() {
                                    expertiseSubjects.add(expertiseController.text);
                                    expertiseController.clear();
                                  });
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: expertiseSubjects.map((s) => Chip(
                            label: Text(s),
                            onDeleted: () => setDialogState(() => expertiseSubjects.remove(s)),
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Preferred Time Slots', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: timeOptions.map((time) => FilterChip(
                            label: Text(time),
                            selected: preferredTimeSlots.contains(time),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  preferredTimeSlots.add(time);
                                } else {
                                  preferredTimeSlots.remove(time);
                                }
                              });
                            },
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Footer buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              departmentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all required fields')),
                            );
                            return;
                          }

                          final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

                          final newTeacher = Teacher(
                            id: teacher?.id ?? '',
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            department: departmentController.text.trim(),
                            expertiseSubjects: expertiseSubjects,
                            maxWeeklyHours: int.tryParse(maxHoursController.text) ?? 20,
                            preferredTimeSlots: preferredTimeSlots,
                          );

                          try {
                            if (isEditing) {
                              await teacherProvider.updateTeacher(newTeacher.copyWith(id: teacher!.id));
                            } else {
                              await teacherProvider.addTeacher(newTeacher);
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? 'Teacher updated successfully' : 'Teacher added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
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

  void _confirmDelete(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher?'),
        content: Text('Are you sure you want to delete ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
              try {
                await teacherProvider.deleteTeacher(teacher.id);
                if (_selectedTeacher?.id == teacher.id) {
                  setState(() => _selectedTeacher = null);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher deleted'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}