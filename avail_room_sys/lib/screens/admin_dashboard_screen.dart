import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/admin_sidebar.dart';
import 'room_management_screen.dart';
import 'teacher_management_screen.dart';
import 'subject_management_screen.dart';
import 'auto_scheduler_screen.dart';
import 'report_screen.dart';   // NEW
import 'settings_screen.dart';  // NEW
import 'schedule_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Admin Dashboard',
    'Room Management',
    'Teacher Management',
    'Subject Management',
    'Schedule Management',
    'Auto-Scheduler',
    'Reports & Analytics',
    'System Settings',
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ResponsiveLayout(
      mobile: _buildMobileLayout(authProvider),
      tablet: _buildTabletLayout(authProvider),
      desktop: _buildDesktopLayout(authProvider),
    );
  }

  Widget _buildMobileLayout(AuthProvider authProvider) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      drawer: AdminSidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
      body: _buildContent(),
    );
  }

  Widget _buildTabletLayout(AuthProvider authProvider) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthProvider authProvider) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(authProvider),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar(AuthProvider authProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('ADMIN MODE',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Text(
            _titles[_selectedIndex],
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authProvider.user?.displayName ?? 'Admin User',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(authProvider.user?.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleLogout,
                  tooltip: 'Logout'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FIXED: pass onNavigate callback so Quick Actions work inside dashboard ───
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return AdminOverviewContent(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const RoomManagementContent();
      case 2:
        return const TeacherManagementContent();
      case 3:
        return const SubjectManagementContent();
      case 4:
        return const ScheduleManagementContent();
      case 5:
        return const AutoSchedulerContent();// Now uses real ReportsScreen
      case 6:
        return const ReportsContent();
      case 7:
        return const SettingsContent();  // Now uses real SettingsScreen
      default:
        return AdminOverviewContent(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}

// ==================== ADMIN OVERVIEW CONTENT ====================

class AdminOverviewContent extends StatelessWidget {
  // FIXED: callback so Quick Actions change the dashboard tab instead of pushing new routes
  final Function(int)? onNavigate;

  const AdminOverviewContent({Key? key, this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(context),
          const SizedBox(height: 32),
          _buildStatsOverview(context),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentActivity(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildSystemHealth(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style:
          Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // FIXED: Use onNavigate callback — these now correctly switch tabs in the dashboard
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionCard(context,
                icon: Icons.add_box,
                label: 'Add Room',
                color: Colors.blue,
                onTap: () => onNavigate?.call(1)),
            _buildActionCard(context,
                icon: Icons.person_add,
                label: 'Add Teacher',
                color: Colors.green,
                onTap: () => onNavigate?.call(2)),
            _buildActionCard(context,
                icon: Icons.book,
                label: 'Add Subject',
                color: Colors.purple,
                onTap: () => onNavigate?.call(3)),
            _buildActionCard(context,
                icon: Icons.auto_fix_high,
                label: 'Scheduler',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => onNavigate?.call(4)),
            _buildActionCard(context,
                icon: Icons.assessment,
                label: 'Reports',
                color: Colors.orange,
                onTap: () => onNavigate?.call(5)),
            _buildActionCard(context,
                icon: Icons.settings,
                label: 'Settings',
                color: Colors.teal,
                onTap: () => onNavigate?.call(6)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap}) {
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration:
            BoxDecoration(border: Border(top: BorderSide(color: color, width: 4))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    return Consumer3<RoomProvider, TeacherProvider, BookingProvider>(
      builder: (context, roomProvider, teacherProvider, bookingProvider, child) {
        final roomCount = roomProvider.rooms.length;
        final availableRooms = roomProvider.getAvailableRooms().length;
        final teacherCount = teacherProvider.teachers.length;
        final bookingCount = bookingProvider.bookings.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(context,
                        title: 'Total Rooms',
                        value: '$roomCount',
                        trend: '$availableRooms available',
                        icon: Icons.meeting_room,
                        color: Colors.blue),
                    _buildStatCard(context,
                        title: 'Active Teachers',
                        value: '$teacherCount',
                        trend: 'Registered',
                        icon: Icons.people,
                        color: Colors.green),
                    _buildStatCard(context,
                        title: 'Scheduled Classes',
                        value: '$bookingCount',
                        trend: 'This semester',
                        icon: Icons.class_,
                        color: Colors.orange),
                    _buildStatCard(context,
                        title: 'Available Now',
                        value: '$availableRooms',
                        trend: 'Ready for use',
                        icon: Icons.check_circle,
                        color: Colors.teal),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
        required String value,
        required String trend,
        required IconData icon,
        required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                  child: Text(trend,
                      style: TextStyle(
                          color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Spacer(),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => onNavigate?.call(5), child: const Text('View Reports')),
              ],
            ),
            const SizedBox(height: 16),
            Consumer3<RoomProvider, TeacherProvider, BookingProvider>(
              builder: (context, roomProvider, teacherProvider, bookingProvider, child) {
                if (roomProvider.rooms.isEmpty && teacherProvider.teachers.isEmpty) {
                  return Center(
                      child: Text('No activity yet', style: TextStyle(color: Colors.grey[600])));
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    if (roomProvider.rooms.isNotEmpty)
                      _buildActivityItem(
                          '${roomProvider.rooms.last.name} added',
                          'Room',
                          Icons.meeting_room,
                          Colors.blue),
                    if (teacherProvider.teachers.isNotEmpty)
                      _buildActivityItem(
                          '${teacherProvider.teachers.last.name} added',
                          'Teacher',
                          Icons.person_add,
                          Colors.green),
                    if (bookingProvider.bookings.isNotEmpty)
                      _buildActivityItem(
                          '${bookingProvider.bookings.length} classes scheduled',
                          'Schedule',
                          Icons.schedule,
                          Colors.orange),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String category, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title),
      subtitle: Text(category),
      dense: true,
    );
  }

  Widget _buildSystemHealth(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Health',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildHealthItem(context,
                label: 'Database', status: 'Operational', color: Colors.green, icon: Icons.storage),
            const SizedBox(height: 16),
            _buildHealthItem(context,
                label: 'Authentication',
                status: 'Active',
                color: Colors.green,
                icon: Icons.security),
            const SizedBox(height: 16),
            _buildHealthItem(context,
                label: 'Scheduler Engine',
                status: 'Ready',
                color: Colors.blue,
                icon: Icons.auto_fix_high),
            const SizedBox(height: 16),
            _buildHealthItem(context,
                label: 'AI Suggestions',
                status: 'Coming Soon',
                color: Colors.orange,
                icon: Icons.psychology),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(BuildContext context,
      {required String label,
        required String status,
        required Color color,
        required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(status,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== EMBEDDED CONTENT WRAPPERS ====================

class RoomManagementContent extends StatelessWidget {
  const RoomManagementContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const RoomManagementScreen();
}

class TeacherManagementContent extends StatelessWidget {
  const TeacherManagementContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const TeacherManagementScreen();
}

class SubjectManagementContent extends StatelessWidget {
  const SubjectManagementContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const SubjectManagementScreen();
}

class ScheduleManagementContent extends StatelessWidget {
  const ScheduleManagementContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const ScheduleManagementScreen();
}

class AutoSchedulerContent extends StatelessWidget {
  const AutoSchedulerContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>  AutoSchedulerScreen();
}

// FIXED: Now returns real ReportsScreen instead of placeholder text
class ReportsContent extends StatelessWidget {
  const ReportsContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const ReportsScreen();
}

// FIXED: Now returns real SettingsScreen instead of placeholder text
class SettingsContent extends StatelessWidget {
  const SettingsContent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}