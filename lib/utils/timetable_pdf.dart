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

  // =====================================================
  // STUDENT / SECTION WEEKLY PDF
  // =====================================================
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

    if (snap.docs.isEmpty) {
      throw "No timetable found";
    }

    final subjects = await _db.collection("subjects").get();
    final teachers = await _db.collection("teachers").get();
    final rooms = await _db.collection("classrooms").get();

    final subjectMap = {
      for (var d in subjects.docs) d.id: d["name"].toString()
    };

    // 🔥 FIXED: teacherId = document ID
    final teacherMap = {
      for (var d in teachers.docs) d.id: d["name"].toString()
    };

    final roomMap = {
      for (var d in rooms.docs) d.id: d["name"].toString()
    };

    final Map<String, List<String>> grid = {
      for (var d in days) d: List.filled(timeSlots.length, "")
    };

    for (var doc in snap.docs) {
      final data = doc.data();

      final day = data["day"];
      final time = data["time"];
      final duration = data["duration"] ?? 1;

      if (!days.contains(day)) continue;

      final index = timeSlots.indexOf(time);
      if (index == -1) continue;

      final cell =
          "${subjectMap[data["subjectId"]] ?? ""}\n"
          "${teacherMap[data["teacherId"]] ?? ""}\n"
          "${roomMap[data["venueId"]] ?? ""}";

      grid[day]![index] = cell;

      if (duration == 2 && index + 1 < timeSlots.length) {
        grid[day]![index + 1] = "__MERGED__";
      }
    }

    return _buildPdf(
      title:
      "Department: $department | Semester: $semester | Section: $section",
      grid: grid,
    );
  }

  // =====================================================
  // TEACHER WEEKLY PDF ✅ FINAL FIX
  // =====================================================
  Future<Uint8List> generateTeacherWeeklyPdf({
    required String teacherId, // 🔑 teachers document ID
  }) async {
    // 1️⃣ Get timetable
    final snap = await _db
        .collection("timetable")
        .where("teacherId", isEqualTo: teacherId)
        .get();

    if (snap.docs.isEmpty) {
      throw "No timetable found for this teacher";
    }

    // 2️⃣ Lookups
    final subjects = await _db.collection("subjects").get();
    final rooms = await _db.collection("classrooms").get();

    // 🔥 FIX: teacher name directly by docId
    final teacherSnap =
    await _db.collection("teachers").doc(teacherId).get();

    final teacherName =
    teacherSnap.exists ? teacherSnap["name"] : "Teacher";

    final subjectMap = {
      for (var d in subjects.docs) d.id: d["name"].toString()
    };

    final roomMap = {
      for (var d in rooms.docs) d.id: d["name"].toString()
    };

    // 3️⃣ Grid
    final Map<String, List<String>> grid = {
      for (var d in days) d: List.filled(timeSlots.length, "")
    };

    // 4️⃣ Fill grid
    for (var doc in snap.docs) {
      final data = doc.data();

      final day = data["day"];
      final time = data["time"];
      final duration = data["duration"] ?? 1;

      if (!days.contains(day)) continue;

      final index = timeSlots.indexOf(time);
      if (index == -1) continue;

      final cell =
          "${subjectMap[data["subjectId"]] ?? ""}\n"
          "${roomMap[data["venueId"]] ?? ""}";

      grid[day]![index] = cell;

      if (duration == 2 && index + 1 < timeSlots.length) {
        grid[day]![index + 1] = "__MERGED__";
      }
    }

    return _buildPdf(
      title: "Teacher: $teacherName (Weekly Timetable)",
      grid: grid,
    );
  }

  // =====================================================
  // COMMON PDF BUILDER
  // =====================================================
  Future<Uint8List> _buildPdf({
    required String title,
    required Map<String, List<String>> grid,
  }) async {
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
                  title,
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
              pw.TableRow(
                children: [
                  _header("Day"),
                  ...timeSlots.map(_header),
                ],
              ),
              for (var day in days)
                pw.TableRow(
                  children: [
                    _header(day),
                    ...List.generate(timeSlots.length, (i) {
                      final text = grid[day]![i];
                      if (text == "__MERGED__") return pw.SizedBox();
                      return _cell(text);
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

  pw.Widget _header(String text) => pw.Container(
    padding: const pw.EdgeInsets.all(4),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _cell(String text) => pw.Container(
    padding: const pw.EdgeInsets.all(4),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 8),
    ),
  );
}
