import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TimetablePdfService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> days = ["MON", "TUE", "WED", "THU", "FRI", "SAT"];

  final List<String> timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "LUNCH",
    "02:00-03:00",
    "03:00-04:00",
  ];

  Future<Uint8List> generateWeeklyPdf({
    required String department,
    required int semester,
    required String section,
  }) async {
    final snap = await _db
        .collection("timetable")
        .where("department", isEqualTo: department)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    final subjects = await _db.collection("subjects").get();
    final teachers = await _db.collection("teachers").get();
    final rooms = await _db.collection("classrooms").get();

    final subjectMap = {
      for (var d in subjects.docs) d.id: d["name"].toString()
    };
    final teacherMap = {
      for (var d in teachers.docs) d.id: d["name"].toString()
    };
    final roomMap = {
      for (var d in rooms.docs) d.id: d["name"].toString()
    };

    // grid[day][slotIndex]
    final Map<String, List<String>> grid = {
      for (var d in days) d: List.filled(timeSlots.length, "")
    };

    for (var doc in snap.docs) {
      final data = doc.data();

      final day = data["day"];
      final time = data["time"];
      final duration = data["duration"] ?? 1;

      if (!days.contains(day)) continue;

      final slotIndex = timeSlots.indexOf(time);
      if (slotIndex == -1) continue;

      final cell =
          "${subjectMap[data["subjectId"]]}\n${teacherMap[data["teacherId"]]}\n${roomMap[data["venueId"]]}";

      grid[day]![slotIndex] = cell;

      if (duration == 2 && slotIndex + 1 < timeSlots.length) {
        grid[day]![slotIndex + 1] = "__MERGED__";
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  "M.M Institute of Computer Technology & Business Management",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "Maharishi Markandeshwar (Deemed to be University)",
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  "Department: $department | Semester: $semester | Section: $section",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(width: 0.6),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              for (int i = 1; i < timeSlots.length + 1; i++)
                i: const pw.FixedColumnWidth(90),
            },
            children: [
              // Header row
              pw.TableRow(
                children: [
                  headerCell("Day"),
                  ...timeSlots.map(headerCell),
                ],
              ),

              // Day rows
              for (var day in days)
                pw.TableRow(
                  children: [
                    headerCell(day),
                    ...List.generate(timeSlots.length, (i) {
                      final text = grid[day]![i];
                      if (text == "__MERGED__") {
                        return pw.SizedBox();
                      }
                      return bodyCell(text);
                    }),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget bodyCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }
}
