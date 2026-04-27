// lib/services/pdf_service.dart
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';

class PdfService {
  // ─── Theme Colors (School Red Palette) ───
  static const PdfColor _primaryRed = PdfColor.fromInt(0xFFC41E3A);
  static const PdfColor _darkRed = PdfColor.fromInt(0xFF8B0000);
  static const PdfColor _lightRedBg = PdfColor.fromInt(0xFFFFEBEE);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF212121);
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _borderGrey = PdfColor.fromInt(0xFFE0E0E0);

  /// Exports the full semester schedule as a PDF with room-centric cards.
  static Future<void> exportSemesterSchedule({
    required BuildContext context,
    required List<Booking> bookings,
    required List<Room> rooms,
    required List<Teacher> teachers,
    required String semester,
    required String schoolYear,
    String schoolName = 'Global Reciprocal Colleges',
  }) async {
    try {
      _showLoading(context);

      final enriched = _enrichBookings(bookings, rooms, teachers);
      final roomGroups = _groupByRoom(enriched, rooms);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => _buildHeader(context, schoolName, semester, schoolYear),
          footer: (context) => _buildFooter(context),
          build: (context) => _buildContent(roomGroups),
        ),
      );

      final bytes = await pdf.save();
      final safeSemester = semester.replaceAll(' ', '_');
      final fileName =
          'Schedule_${safeSemester}_${schoolYear}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        // ─── WEB: Use printing package (download dialog) ───
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        // ─── MOBILE/DESKTOP: Use system temp directory ───
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '$schoolName — $semester Schedule',
          text: 'Semester Schedule for $semester $schoolYear',
        );
      }

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  // ─────────────────── DATA HELPERS ───────────────────

  static List<Booking> _enrichBookings(
      List<Booking> bookings,
      List<Room> rooms,
      List<Teacher> teachers,
      ) {
    final roomMap = {for (final r in rooms) r.id: r};
    final teacherMap = {for (final t in teachers) t.id: t};

    return bookings.map((b) {
      final room = roomMap[b.roomId];
      final teacher = teacherMap[b.teacherId];

      return Booking(
        id: b.id,
        roomId: b.roomId,
        teacherId: b.teacherId,
        subjectId: b.subjectId,
        dayOfWeek: b.dayOfWeek,
        startTime: b.startTime,
        endTime: b.endTime,
        specificDate: b.specificDate,
        isRecurring: b.isRecurring,
        semester: b.semester,
        schoolYear: b.schoolYear,
        status: b.status,
        notes: b.notes,
        createdBy: b.createdBy,
        roomName: b.roomName ?? room?.name ?? 'Unknown Room',
        teacherName: b.teacherName ?? teacher?.name ?? 'Unknown Teacher',
        subjectName: b.subjectName ?? 'Unknown Subject',
        subjectCode: b.subjectCode,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      );
    }).toList();
  }

  static List<_RoomGroup> _groupByRoom(List<Booking> bookings, List<Room> allRooms) {
    final sortedRooms = List<Room>.from(allRooms)
      ..sort((a, b) {
        final buildingCmp = a.building.compareTo(b.building);
        if (buildingCmp != 0) return buildingCmp;
        return a.name.compareTo(b.name);
      });

    final bookingMap = <String, List<Booking>>{};
    for (final b in bookings) {
      bookingMap.putIfAbsent(b.roomId, () => []).add(b);
    }

    return sortedRooms.map((room) {
      final roomBookings = bookingMap[room.id] ?? [];
      roomBookings.sort((a, b) {
        final dayCmp = _dayIndex(a.dayOfWeek).compareTo(_dayIndex(b.dayOfWeek));
        if (dayCmp != 0) return dayCmp;
        return a.startTime.compareTo(b.startTime);
      });

      final byDay = <String, List<Booking>>{};
      for (final b in roomBookings) {
        byDay.putIfAbsent(b.dayOfWeek, () => []).add(b);
      }

      return _RoomGroup(room: room, bookingsByDay: byDay);
    }).toList();
  }

  static int _dayIndex(String day) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    return days.indexOf(day.toLowerCase());
  }

  static String _capitalizeDay(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1);
  }

  // ─────────────────── PDF WIDGETS ───────────────────

  static pw.Widget _buildHeader(
      pw.Context context,
      String schoolName,
      String semester,
      String schoolYear,
      ) {
    return pw.Container(
      width: double.infinity,
      color: _primaryRed,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            schoolName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Semester Schedule Report',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 13,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '$semester  $schoolYear',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    final now = DateFormat('MMMM dd, yyyy  hh:mm a').format(DateTime.now());
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderGrey, width: 0.5),
        ),
      ),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}  Generated on $now',
        style: pw.TextStyle(
          fontSize: 8,
          color: _textGrey,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  static List<pw.Widget> _buildContent(List<_RoomGroup> roomGroups) {
    final widgets = <pw.Widget>[];

    for (final group in roomGroups) {
      widgets.add(_buildRoomCard(group));
      widgets.add(pw.SizedBox(height: 16));
    }

    return widgets;
  }

  static pw.Widget _buildRoomCard(_RoomGroup group) {
    final room = group.room;
    final byDay = group.bookingsByDay;
    final sortedDays = byDay.keys.toList()
      ..sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderGrey, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 6,
                height: 36,
                decoration: pw.BoxDecoration(
                  color: _primaryRed,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      room.name,
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkRed,
                      ),
                    ),
                    pw.Text(
                      '${room.building} Floor ${room.floor}  ${room.type.name[0].toUpperCase()}${room.type.name.substring(1)}  Capacity: ${room.capacity}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: _lightRedBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '${byDay.values.fold<int>(0, (sum, list) => sum + list.length)} classes',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryRed,
                  ),
                ),
              ),
            ],
          ),

          pw.Divider(color: _borderGrey, thickness: 0.5),

          if (byDay.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Text(
                'No classes scheduled in this room.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _textGrey,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            )
          else
            ...sortedDays.map((day) => _buildDaySection(day, byDay[day]!)),
        ],
      ),
    );
  }

  static pw.Widget _buildDaySection(String day, List<Booking> bookings) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _lightRedBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              _capitalizeDay(day),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _darkRed,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          ...bookings.map((b) => _buildBookingRow(b)),
        ],
      ),
    );
  }

  static pw.Widget _buildBookingRow(Booking b) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 8, bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              '${b.startTime}  ${b.endTime}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${b.subjectCode ?? 'N/A'}  ${b.subjectName ?? 'Unknown Subject'}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  b.teacherName ?? 'Unknown Teacher',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomGroup {
  final Room room;
  final Map<String, List<Booking>> bookingsByDay;

  _RoomGroup({required this.room, required this.bookingsByDay});
}