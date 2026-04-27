// lib/screens/room_management_screen.dart - WEB OPTIMIZED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import '../widgets/responsive_layout.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final _searchController = TextEditingController();
  Room? _selectedRoom;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force web layout for desktop/web to prevent overflow
    if (ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isWeb(context)) {
      return _buildWebLayout();
    }

    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildWebLayout(), // Use web layout for desktop too
    );
  }

  // WEB LAYOUT - Master-Detail pattern prevents overflow
  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - fixed narrow width
          Container(
            width: 300, // Narrower to prevent overflow
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                _buildWebSidebarHeader(),
                _buildSearchField(),
                Expanded(child: _buildRoomList()),
              ],
            ),
          ),
          // Right detail view - scrollable and constrained
          Expanded(
            child: _selectedRoom != null
                ? _buildRoomDetail(_selectedRoom!)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSidebarHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rooms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _showRoomDialog(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Add Room',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        style: const TextStyle(fontSize: 13),
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
            Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a room to view details',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // DETAIL VIEW - Constrained and scrollable prevents overflow
  Widget _buildRoomDetail(Room room) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700), // Prevent stretching too wide
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _getStatusColor(room.currentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getStatusIcon(room.currentStatus),
                            size: 40,
                            color: _getStatusColor(room.currentStatus),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${room.building} • Floor ${room.floor}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(room.currentStatus).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  room.currentStatus.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(room.currentStatus),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showRoomDialog(room: room),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(room),
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    // Stats in a wrap to prevent overflow
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 500;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildDetailTile(
                              Icons.people,
                              'Capacity',
                              '${room.capacity} seats',
                              Colors.blue,
                              isNarrow ? double.infinity : 150,
                            ),
                            _buildDetailTile(
                              Icons.meeting_room,
                              'Type',
                              room.type.name,
                              Colors.purple,
                              isNarrow ? double.infinity : 150,
                            ),
                            _buildDetailTile(
                              Icons.location_on,
                              'Floor',
                              room.floor,
                              Colors.orange,
                              isNarrow ? double.infinity : 150,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    // Equipment section
                    Text(
                      'Equipment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (room.equipment.isEmpty)
                      Text('No equipment assigned', style: TextStyle(color: Colors.grey[600])),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: room.equipment.map((eq) => Chip(
                        label: Text(eq),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.grey[100],
                      )).toList(),
                    ),
                    const SizedBox(height: 28),
                    // Quick status change
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RoomStatus.values.map((status) => ElevatedButton.icon(
                        onPressed: status == room.currentStatus
                            ? null
                            : () => _updateStatus(room.id, status),
                        icon: Icon(_getStatusIcon(status), size: 16),
                        label: Text('Set ${status.name}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(status).withOpacity(0.1),
                          foregroundColor: _getStatusColor(status),
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, Color color, double width) {
    return Container(
      width: width == double.infinity ? null : width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // COMPACT LIST ITEM for sidebar
  Widget _buildRoomList() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        if (roomProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (roomProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Error', style: TextStyle(fontSize: 12)),
                TextButton(
                  onPressed: () => roomProvider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final rooms = _searchController.text.isEmpty
            ? roomProvider.rooms
            : roomProvider.searchRooms(_searchController.text);

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.isEmpty ? 'No rooms' : 'No matches',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final isSelected = _selectedRoom?.id == room.id;
            return _buildCompactRoomItem(room, isSelected);
          },
        );
      },
    );
  }

  Widget _buildCompactRoomItem(Room room, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: () => setState(() => _selectedRoom = room),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getStatusColor(room.currentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(room.currentStatus),
                  size: 18,
                  color: _getStatusColor(room.currentStatus),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${room.building} • ${room.capacity} seats',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available: return Colors.green;
      case RoomStatus.occupied: return Colors.red;
      case RoomStatus.maintenance: return Colors.orange;
      case RoomStatus.reserved: return Colors.blue;
    }
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.available: return Icons.check_circle;
      case RoomStatus.occupied: return Icons.lock;
      case RoomStatus.maintenance: return Icons.build;
      case RoomStatus.reserved: return Icons.schedule;
    }
  }

  Future<void> _updateStatus(String roomId, RoomStatus status) async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    try {
      await roomProvider.updateRoomStatus(roomId, status);
      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.name}'), duration: const Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // MOBILE/TABLET LAYOUTS (unchanged but compact)
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showRoomDialog())],
      ),
      body: _buildMobileList(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Row(
        children: [
          SizedBox(width: 320, child: _buildMobileList()),
          Expanded(child: Container(color: Colors.grey[100], child: const Center(child: Text('Select a room')))),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(child: _buildRoomList()),
      ],
    );
  }

  void _showRoomDialog({Room? room}) {
    final isEditing = room != null;
    final nameController = TextEditingController(text: room?.name ?? '');
    final buildingController = TextEditingController(text: room?.building ?? '');
    final floorController = TextEditingController(text: room?.floor ?? '');
    final capacityController = TextEditingController(text: room?.capacity.toString() ?? '30');

    RoomType selectedType = room?.type ?? RoomType.lecture;
    RoomStatus selectedStatus = room?.currentStatus ?? RoomStatus.available;
    List<String> selectedEquipment = List.from(room?.equipment ?? []);

    final equipmentOptions = ['Projector', 'AC', 'Whiteboard', 'Computers', 'Lab Equipment', 'Mic', 'TV', 'Video Conf', 'Fume Hood', 'Chemistry Equipment'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(isEditing ? 'Edit Room' : 'Add Room', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Room Name *')),
                        const SizedBox(height: 12),
                        TextField(controller: buildingController, decoration: const InputDecoration(labelText: 'Building *')),
                        const SizedBox(height: 12),
                        TextField(controller: floorController, decoration: const InputDecoration(labelText: 'Floor *')),
                        const SizedBox(height: 12),
                        TextField(
                          controller: capacityController,
                          decoration: const InputDecoration(labelText: 'Capacity'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RoomType>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Room Type'),
                          items: RoomType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) => setDialogState(() => selectedType = v!),
                        ),
                        if (isEditing) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<RoomStatus>(
                            value: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: RoomStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                            onChanged: (v) => setDialogState(() => selectedStatus = v!),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text('Equipment', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: equipmentOptions.map((eq) => FilterChip(
                            label: Text(eq, style: const TextStyle(fontSize: 11)),
                            selected: selectedEquipment.contains(eq),
                            onSelected: (s) => setDialogState(() => s ? selectedEquipment.add(eq) : selectedEquipment.remove(eq)),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || buildingController.text.isEmpty || floorController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                            return;
                          }
                          final provider = Provider.of<RoomProvider>(context, listen: false);
                          final newRoom = Room(
                            id: room?.id ?? '',
                            name: nameController.text.trim(),
                            building: buildingController.text.trim(),
                            floor: floorController.text.trim(),
                            capacity: int.tryParse(capacityController.text) ?? 30,
                            type: selectedType,
                            equipment: selectedEquipment,
                            currentStatus: selectedStatus,
                          );
                          try {
                            if (isEditing) await provider.updateRoom(newRoom.copyWith(id: room!.id));
                            else await provider.addRoom(newRoom);
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

  void _confirmDelete(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room?'),
        content: Text('Delete ${room.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<RoomProvider>(context, listen: false);
              try {
                await provider.deleteRoom(room.id);
                if (_selectedRoom?.id == room.id) setState(() => _selectedRoom = null);
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
}