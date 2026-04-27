// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with Admin Info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.meeting_room,
                  label: 'Room Management',
                  index: 1,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  label: 'Teacher Management',
                  index: 2,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.book,
                  label: 'Subject Management',
                  index: 3,
                ),
                // In lib/widgets/admin_sidebar.dart, add to the ListView children:

                _buildMenuItem(
                  context,
                  icon: Icons.table_chart,
                  label: 'Schedule Management',
                  index: 4, // or whatever index is next
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_fix_high,
                  label: 'Auto-Scheduler',
                  index: 5,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  label: 'Reports',
                  index: 6,
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 7,
                ),
              ],
            ),
          ),

          // Logout Button at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () async {
                await authProvider.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required int index,
      }) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}