// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/booking_model.dart';
import 'scheduler_service.dart';

/// AI Service for schedule optimization suggestions
///
/// Uses Google Cloud AI API (Vertex AI / Gemini) for intelligent scheduling.
/// Falls back to rule-based suggestions when API is unavailable.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // TODO: Replace with your actual Google Cloud API key
  static const String _apiKey = 'your_api_key';
  static const String _projectId = 'YOUR_GCP_PROJECT_ID';
  static const String _location = 'us-central1';

  // Toggle between mock mode and real API
  bool _useMockMode = true;
  bool get isMockMode => _useMockMode;

  void setMockMode(bool value) => _useMockMode = value;

  // ==================== MAIN AI FUNCTIONS ====================

  /// Analyzes current schedule data and suggests improvements
  Future<AIAnalysisResult> analyzeSchedule({
    required List<Booking> currentBookings,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<Subject> subjects,
  }) async {
    if (_useMockMode) {
      return _mockAnalyzeSchedule(
        currentBookings: currentBookings,
        teachers: teachers,
        rooms: rooms,
        subjects: subjects,
      );
    }

    return _callVertexAI(
      currentBookings: currentBookings,
      teachers: teachers,
      rooms: rooms,
      subjects: subjects,
    );
  }

  /// Suggests optimal room assignments for subjects
  Future<List<RoomSuggestion>> suggestRoomAssignments({
    required Subject subject,
    required List<Room> availableRooms,
    required List<Booking> existingBookings,
  }) async {
    if (_useMockMode) {
      return _mockSuggestRooms(
        subject: subject,
        availableRooms: availableRooms,
        existingBookings: existingBookings,
      );
    }
    // Real API call would go here
    return _mockSuggestRooms(
      subject: subject,
      availableRooms: availableRooms,
      existingBookings: existingBookings,
    );
  }

  /// Suggests teacher assignments based on workload and expertise
  Future<List<TeacherSuggestion>> suggestTeacherAssignments({
    required Subject subject,
    required List<Teacher> availableTeachers,
    required List<Booking> teacherCurrentLoad,
  }) async {
    if (_useMockMode) {
      return _mockSuggestTeachers(
        subject: subject,
        availableTeachers: availableTeachers,
        teacherCurrentLoad: teacherCurrentLoad,
      );
    }
    return _mockSuggestTeachers(
      subject: subject,
      availableTeachers: availableTeachers,
      teacherCurrentLoad: teacherCurrentLoad,
    );
  }

  /// Detects potential issues before they become conflicts
  Future<List<AIPrediction>> predictPotentialIssues({
    required List<Booking> proposedBookings,
    required List<Teacher> teachers,
    required List<Room> rooms,
  }) async {
    if (_useMockMode) {
      return _mockPredictIssues(
        proposedBookings: proposedBookings,
        teachers: teachers,
        rooms: rooms,
      );
    }
    return _mockPredictIssues(
      proposedBookings: proposedBookings,
      teachers: teachers,
      rooms: rooms,
    );
  }

  // ==================== MOCK IMPLEMENTATIONS (WORKING NOW) ====================

  AIAnalysisResult _mockAnalyzeSchedule({
    required List<Booking> currentBookings,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<Subject> subjects,
  }) {
    final suggestions = <AISuggestion>[];
    final insights = <AIInsight>[];

    // 1. Analyze teacher workload distribution
    final teacherHours = <String, double>{};
    for (final booking in currentBookings) {
      final hours = _calculateHours(booking.startTime, booking.endTime);
      teacherHours[booking.teacherId] = (teacherHours[booking.teacherId] ?? 0) + hours;
    }

    // Find overloaded and underloaded teachers
    for (final teacher in teachers) {
      final hours = teacherHours[teacher.id] ?? 0;
      final utilization = hours / teacher.maxWeeklyHours;

      if (utilization > 0.9) {
        suggestions.add(AISuggestion(
          type: SuggestionType.workload,
          priority: AIPriority.high,
          title: '${teacher.name} is near maximum capacity',
          description: 'Assigned ${hours.toStringAsFixed(1)}h / ${teacher.maxWeeklyHours}h max. '
              'Consider redistributing subjects to balance workload.',
          affectedEntity: teacher.name,
          action: 'Redistribute 1-2 subjects to teachers with lighter loads',
        ));
      } else if (utilization < 0.3 && currentBookings.isNotEmpty) {
        suggestions.add(AISuggestion(
          type: SuggestionType.workload,
          priority: AIPriority.medium,
          title: '${teacher.name} has light workload',
          description: 'Only ${hours.toStringAsFixed(1)}h assigned. Could take additional subjects.',
          affectedEntity: teacher.name,
          action: 'Assign additional subjects to optimize resource use',
        ));
      }
    }

    // 2. Analyze room utilization
    final roomBookings = <String, int>{};
    for (final booking in currentBookings) {
      roomBookings[booking.roomId] = (roomBookings[booking.roomId] ?? 0) + 1;
    }

    for (final room in rooms) {
      final bookings = roomBookings[room.id] ?? 0;
      if (bookings == 0 && currentBookings.isNotEmpty) {
        suggestions.add(AISuggestion(
          type: SuggestionType.roomUtilization,
          priority: AIPriority.low,
          title: '${room.name} is underutilized',
          description: 'No bookings assigned to this room. Consider scheduling here to balance load.',
          affectedEntity: room.name,
          action: 'Review room assignments for better distribution',
        ));
      }
    }

    // 3. Detect back-to-back classes for same teacher
    final teacherDaySlots = <String, List<Booking>>{};
    for (final booking in currentBookings) {
      final key = '${booking.teacherId}_${booking.dayOfWeek}';
      teacherDaySlots.putIfAbsent(key, () => []).add(booking);
    }

    for (final entry in teacherDaySlots.entries) {
      final dayBookings = entry.value;
      dayBookings.sort((a, b) => a.startTime.compareTo(b.startTime));

      for (int i = 0; i < dayBookings.length - 1; i++) {
        final current = dayBookings[i];
        final next = dayBookings[i + 1];

        final currentEnd = _timeToMinutes(current.endTime);
        final nextStart = _timeToMinutes(next.startTime);

        if (nextStart - currentEnd <= 30) { // 30 min or less gap
          suggestions.add(AISuggestion(
            type: SuggestionType.teacherWellness,
            priority: AIPriority.medium,
            title: 'Back-to-back classes detected',
            description: '${current.teacherName} has classes at ${current.startTime}-${current.endTime} '
                'and ${next.startTime}-${next.endTime} on ${current.dayOfWeek}',
            affectedEntity: current.teacherName ?? 'Unknown',
            action: 'Consider adding a break between these sessions',
          ));
        }
      }
    }

    // 4. Generate insights
    final avgUtilization = teachers.isEmpty ? 0 :
    teacherHours.values.fold(0.0, (a, b) => a + b) / teachers.length;

    insights.add(AIInsight(
      category: 'Workload Balance',
      value: '${avgUtilization.toStringAsFixed(1)}h',
      benchmark: '20h max',
      trend: avgUtilization > 18 ? 'critical' : avgUtilization > 15 ? 'warning' : 'good',
    ));

    insights.add(AIInsight(
      category: 'Room Usage',
      value: '${roomBookings.length}/${rooms.length}',
      benchmark: 'All rooms',
      trend: roomBookings.length < rooms.length * 0.7 ? 'underutilized' : 'optimal',
    ));

    return AIAnalysisResult(
      overallScore: _calculateOverallScore(suggestions, currentBookings.length),
      suggestions: suggestions,
      insights: insights,
      generatedAt: DateTime.now(),
    );
  }

  List<RoomSuggestion> _mockSuggestRooms({
    required Subject subject,
    required List<Room> availableRooms,
    required List<Booking> existingBookings,
  }) {
    final suggestions = <RoomSuggestion>[];

    for (final room in availableRooms) {
      double score = 0;
      List<String> reasons = [];

      // Capacity match
      final capacityRatio = subject.maxStudents / room.capacity;
      if (capacityRatio >= 0.7 && capacityRatio <= 1.0) {
        score += 30;
        reasons.add('Optimal capacity (${room.capacity} seats)');
      } else if (capacityRatio < 0.7) {
        score += 15;
        reasons.add('Adequate capacity');
      }

      // Room type match
      if (room.type == subject.preferredRoomType) {
        score += 25;
        reasons.add('Correct room type (${room.type.name})');
      }

      // Equipment match
      final hasAllEquipment = subject.requiredEquipment.every(
              (eq) => room.equipment.any((re) =>
              re.toLowerCase().contains(eq.toLowerCase()))
      );
      if (hasAllEquipment) {
        score += 20;
        reasons.add('All required equipment available');
      }

      // Current utilization (prefer less used rooms)
      final roomBookingCount = existingBookings.where((b) => b.roomId == room.id).length;
      if (roomBookingCount < 5) {
        score += 15;
        reasons.add('Low current utilization');
      }

      // Location/building preference
      if (subject.department.toLowerCase().contains(room.building.toLowerCase()) ||
          room.building.toLowerCase().contains(subject.department.toLowerCase())) {
        score += 10;
        reasons.add('Near ${subject.department} department');
      }

      suggestions.add(RoomSuggestion(
        room: room,
        score: score.clamp(0, 100),
        reasons: reasons,
      ));
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(3).toList();
  }

  List<TeacherSuggestion> _mockSuggestTeachers({
    required Subject subject,
    required List<Teacher> availableTeachers,
    required List<Booking> teacherCurrentLoad,
  }) {
    final suggestions = <TeacherSuggestion>[];

    for (final teacher in availableTeachers) {
      double score = 0;
      List<String> reasons = [];

      // Expertise match
      final expertiseMatch = teacher.expertiseSubjects.any((exp) {
        final expLower = exp.toLowerCase();
        return subject.name.toLowerCase().contains(expLower) ||
            subject.code.toLowerCase().contains(expLower) ||
            expLower.contains(subject.name.toLowerCase());
      });

      if (expertiseMatch) {
        score += 35;
        reasons.add('Expertise matches subject');
      }

      // Department match
      if (teacher.department.toLowerCase() == subject.department.toLowerCase()) {
        score += 20;
        reasons.add('Same department');
      }

      // Workload capacity
      final currentHours = teacherCurrentLoad
          .where((b) => b.teacherId == teacher.id)
          .fold(0.0, (sum, b) => sum + _calculateHours(b.startTime, b.endTime));

      final remainingCapacity = teacher.maxWeeklyHours - currentHours;
      if (remainingCapacity >= subject.requiredHoursPerWeek) {
        score += 25;
        reasons.add('Sufficient capacity (${remainingCapacity.toStringAsFixed(1)}h remaining)');
      } else if (remainingCapacity > 0) {
        score += 10;
        reasons.add('Partial capacity available');
      } else {
        score -= 20;
        reasons.add('At capacity limit');
      }

      // Prefer balanced workload
      final utilization = currentHours / teacher.maxWeeklyHours;
      if (utilization < 0.5) {
        score += 15;
        reasons.add('Light current workload');
      }

      // Direct assignment preference
      if (subject.eligibleTeachers.contains(teacher.id)) {
        score += 20;
        reasons.add('Explicitly assigned to this subject');
      }

      suggestions.add(TeacherSuggestion(
        teacher: teacher,
        score: score.clamp(0, 100),
        reasons: reasons,
        currentHours: currentHours,
        remainingCapacity: remainingCapacity,
      ));
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(3).toList();
  }

  List<AIPrediction> _mockPredictIssues({
    required List<Booking> proposedBookings,
    required List<Teacher> teachers,
    required List<Room> rooms,
  }) {
    final predictions = <AIPrediction>[];

    // Check for teacher overload
    final teacherHours = <String, double>{};
    for (final booking in proposedBookings) {
      final hours = _calculateHours(booking.startTime, booking.endTime);
      teacherHours[booking.teacherId] = (teacherHours[booking.teacherId] ?? 0) + hours;
    }

    for (final entry in teacherHours.entries) {
      final teacher = teachers.firstWhere((t) => t.id == entry.key);
      if (entry.value > teacher.maxWeeklyHours * 0.9) {
        predictions.add(AIPrediction(
          type: PredictionType.teacherOverload,
          severity: Severity.warning,
          description: '${teacher.name} will be at ${(entry.value / teacher.maxWeeklyHours * 100).toStringAsFixed(0)}% capacity',
          probability: 0.85,
          suggestedAction: 'Redistribute ${(entry.value - teacher.maxWeeklyHours * 0.8).toStringAsFixed(1)} hours to other teachers',
        ));
      }
    }

    // Check for room overbooking
    final roomDaySlots = <String, int>{};
    for (final booking in proposedBookings) {
      final key = '${booking.roomId}_${booking.dayOfWeek}_${booking.startTime}';
      roomDaySlots[key] = (roomDaySlots[key] ?? 0) + 1;
    }

    for (final entry in roomDaySlots.entries) {
      if (entry.value > 1) {
        predictions.add(AIPrediction(
          type: PredictionType.roomConflict,
          severity: Severity.critical,
          description: 'Room double-booked at ${entry.key.split('_')[2]} on ${entry.key.split('_')[1]}',
          probability: 1.0,
          suggestedAction: 'Reschedule one of the conflicting bookings',
        ));
      }
    }

    return predictions;
  }

  // ==================== REAL GOOGLE CLOUD AI INTEGRATION ====================
  // TODO: Implement when you have your API key ready

  Future<AIAnalysisResult> _callVertexAI({
    required List<Booking> currentBookings,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<Subject> subjects,
  }) async {
    // This will be implemented when you provide your Google Cloud API credentials
    // Uses Vertex AI Gemini API for intelligent analysis

    /* Example implementation:
    final url = Uri.parse(
      'https://${_location}-aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/gemini-pro:generateContent'
    );

    final prompt = _buildAnalysisPrompt(
      bookings: currentBookings,
      teachers: teachers,
      rooms: rooms,
      subjects: subjects,
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }]
      }),
    );

    final data = jsonDecode(response.body);
    // Parse AI response...
    */

    // Fallback to mock for now
    return _mockAnalyzeSchedule(
      currentBookings: currentBookings,
      teachers: teachers,
      rooms: rooms,
      subjects: subjects,
    );
  }

  // ==================== HELPERS ====================

  double _calculateHours(String start, String end) {
    final startMin = _timeToMinutes(start);
    final endMin = _timeToMinutes(end);
    return (endMin - startMin) / 60.0;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  double _calculateOverallScore(List<AISuggestion> suggestions, int totalBookings) {
    if (totalBookings == 0) return 0;

    double score = 100;
    for (final s in suggestions) {
      switch (s.priority) {
        case AIPriority.critical: score -= 15; break;
        case AIPriority.high: score -= 10; break;
        case AIPriority.medium: score -= 5; break;
        case AIPriority.low: score -= 2; break;
      }
    }
    return score.clamp(0, 100);
  }
}

// ==================== DATA CLASSES ====================

class AIAnalysisResult {
  final double overallScore; // 0-100
  final List<AISuggestion> suggestions;
  final List<AIInsight> insights;
  final DateTime generatedAt;

  AIAnalysisResult({
    required this.overallScore,
    required this.suggestions,
    required this.insights,
    required this.generatedAt,
  });

  bool get hasCriticalIssues => suggestions.any((s) => s.priority == AIPriority.critical);
  bool get hasSuggestions => suggestions.isNotEmpty;

  List<AISuggestion> get criticalSuggestions =>
      suggestions.where((s) => s.priority == AIPriority.critical).toList();
  List<AISuggestion> get highPrioritySuggestions =>
      suggestions.where((s) => s.priority == AIPriority.high).toList();
}

class AISuggestion {
  final SuggestionType type;
  final AIPriority priority;
  final String title;
  final String description;
  final String affectedEntity;
  final String action;

  AISuggestion({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.affectedEntity,
    required this.action,
  });
}

class AIInsight {
  final String category;
  final String value;
  final String benchmark;
  final String trend; // 'good', 'warning', 'critical', 'optimal', 'underutilized'

  AIInsight({
    required this.category,
    required this.value,
    required this.benchmark,
    required this.trend,
  });
}

class RoomSuggestion {
  final Room room;
  final double score; // 0-100
  final List<String> reasons;

  RoomSuggestion({
    required this.room,
    required this.score,
    required this.reasons,
  });
}

class TeacherSuggestion {
  final Teacher teacher;
  final double score; // 0-100
  final List<String> reasons;
  final double currentHours;
  final double remainingCapacity;

  TeacherSuggestion({
    required this.teacher,
    required this.score,
    required this.reasons,
    required this.currentHours,
    required this.remainingCapacity,
  });
}

class AIPrediction {
  final PredictionType type;
  final Severity severity;
  final String description;
  final double probability; // 0-1
  final String suggestedAction;

  AIPrediction({
    required this.type,
    required this.severity,
    required this.description,
    required this.probability,
    required this.suggestedAction,
  });
}

enum SuggestionType {
  workload,
  roomUtilization,
  teacherWellness,
  conflictPrevention,
  optimization,
}

enum AIPriority {
  critical,
  high,
  medium,
  low,
}

enum PredictionType {
  teacherOverload,
  roomConflict,
  scheduleGap,
  resourceShortage,
}

enum Severity {
  critical,
  warning,
  info,
}