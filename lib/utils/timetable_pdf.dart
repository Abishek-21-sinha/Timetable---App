import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TimetablePdfService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> days = [
    "MON","TUE","WED","THU","FRI","SAT"
  ];


  final List<String> baseSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "02:00-03:00",
    "03:00-04:00",
  ];

  // =====================================================
  // LOAD PER DAY LUNCH FROM FIRESTORE
  // =====================================================

  Future<Map<String,int>> getLunchSlots() async {

    final doc =
    await _db.collection("settings").doc("timetable").get();

    if (doc.exists && doc.data()!.containsKey("lunchSlots")) {
      return Map<String,int>.from(doc["lunchSlots"]);
    }

    // default
    return {
      "MON":3,
      "TUE":3,
      "WED":3,
      "THU":3,
      "FRI":3,
      "SAT":3,
    };
  }

  // =====================================================
  // STUDENT WEEKLY PDF
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

    final lunchSlots = await getLunchSlots();

    final subjects = await _db.collection("subjects").get();
    final teachers = await _db.collection("teachers").get();
    final rooms = await _db.collection("classrooms").get();

    final subjectMap = {
      for (var d in subjects.docs)
        d.id: d["name"].toString()
    };

    final teacherMap = {
      for (var d in teachers.docs)
        d.id: d["name"].toString()
    };

    final roomMap = {
      for (var d in rooms.docs)
        d.id: d["name"].toString()
    };

    final Map<String,List<String>> grid = {};
    final Map<String,List<String>> daySlots = {};

    for (var day in days) {

      int lunchIndex = lunchSlots[day] ?? 3;

      List<String> slots = List.from(baseSlots);
      slots.insert(lunchIndex, "LUNCH");

      daySlots[day] = slots;
      grid[day] = List.filled(slots.length, "");
    }

    for (var doc in snap.docs) {

      final data = doc.data();
      final day = data["day"];
      final time = data["time"];
      final group = data["group"] ?? "ALL";

      if (!days.contains(day)) continue;
      if (time == "LUNCH") continue;

      final slots = daySlots[day]!;
      final index = slots.indexOf(time);
      if (index == -1) continue;

      final subject = subjectMap[data["subjectId"]] ?? "";
      final teacher = teacherMap[data["teacherId"]] ?? "";
      final venueId = data["venueId"] ?? "";
      final venueName = roomMap[data["venueId"]] ?? "";

      final cell =
          "$subject\n"
          "$teacher\n"
          "$venueId - $venueName ($group)";

      if (grid[day]![index].isEmpty) {
        grid[day]![index] = cell;
      } else {
        grid[day]![index] =
        "${grid[day]![index]}"
            "\n------------------------\n"
            "$cell";
      }
    }

    return _buildPdf(
      title:
      "Department: $department | Semester: $semester | Section: $section",
      grid: grid,
      daySlots: daySlots,
    );
  }

  // =====================================================
  // TEACHER WEEKLY PDF
  // =====================================================

  Future<Uint8List> generateTeacherWeeklyPdf({
    required String teacherId,
  }) async {

    final snap = await _db
        .collection("timetable")
        .where("teacherId", isEqualTo: teacherId)
        .get();

    if (snap.docs.isEmpty) {
      throw "No timetable found";
    }

    final lunchSlots = await getLunchSlots();

    final subjects = await _db.collection("subjects").get();
    final rooms = await _db.collection("classrooms").get();

    final teacherSnap =
    await _db.collection("teachers").doc(teacherId).get();

    final teacherName =
    teacherSnap.exists ? teacherSnap["name"] : "Teacher";

    final subjectMap = {
      for (var d in subjects.docs)
        d.id: d["name"].toString()
    };

    final roomMap = {
      for (var d in rooms.docs)
        d.id: d["name"].toString()
    };

    final Map<String,List<String>> grid = {};
    final Map<String,List<String>> daySlots = {};

    for (var day in days) {

      int lunchIndex = lunchSlots[day] ?? 3;

      List<String> slots = List.from(baseSlots);
      slots.insert(lunchIndex, "LUNCH");

      daySlots[day] = slots;
      grid[day] = List.filled(slots.length, "");
    }

    for (var doc in snap.docs) {

      final data = doc.data();
      final day = data["day"];
      final time = data["time"];
      final group = data["group"] ?? "ALL";

      if (!days.contains(day)) continue;
      if (time == "LUNCH") continue;

      final slots = daySlots[day]!;
      final index = slots.indexOf(time);
      if (index == -1) continue;

      final subject = subjectMap[data["subjectId"]] ?? "";
      final venueId = data["venueId"] ?? "";
      final venueName = roomMap[data["venueId"]] ?? "";

      final cell =
          "$subject\n"
          "$venueId - $venueName ($group)";

      if (grid[day]![index].isEmpty) {
        grid[day]![index] = cell;
      } else {
        grid[day]![index] =
        "${grid[day]![index]}"
            "\n---------------------------\n"
            "$cell";
      }
    }

    return _buildPdf(
      title:
      "Teacher: $teacherName (Weekly Timetable)",
      grid: grid,
      daySlots: daySlots,
    );
  }

  // =====================================================
  // PDF BUILDER
  // =====================================================

  Future<Uint8List> _buildPdf({
    required String title,
    required Map<String,List<String>> grid,
    required Map<String,List<String>> daySlots,
  }) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => [

          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(),
            children: [

              pw.TableRow(
                children: [
                  _header("Day"),
                  ...baseSlots.map(_header),
                ],
              ),

              for (var day in days)
                pw.TableRow(
                  children: [

                    _header(day),

                    ...List.generate(
                      baseSlots.length,
                          (i) {

                            int lunchIndex =
                            (daySlots[day]!.indexOf("LUNCH"));

                            // if this column is lunch position
                            if (i == lunchIndex) {
                              return pw.Container(
                                alignment: pw.Alignment.center,
                                padding: const pw.EdgeInsets.all(4),
                                color: PdfColors.grey300,
                                child: pw.Text(
                                  "LUNCH",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }

                            return _cell(grid[day]![i]);
                          },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _cell(String text) {
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


// import 'dart:typed_data';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
//
// class TimetablePdfService {
//
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   final List<String> days = [
//     "MON","TUE","WED","THU","FRI","SAT"
//   ];
//
//   final List<String> timeSlots = [
//     "09:00-10:00",
//     "10:00-11:00",
//     "11:00-12:00",
//     "12:00-01:00",
//     "02:00-03:00",
//     "03:00-04:00",
//   ];
//
//   // =====================================================
//   // STUDENT WEEKLY PDF
//   // =====================================================
//
//   Future<Uint8List> generateWeeklyPdf({
//     required String department,
//     required int semester,
//     required String section,
//   }) async {
//
//     final snap = await _db
//         .collection("timetable")
//         .where("department", isEqualTo: department)
//         .where("semester", isEqualTo: semester)
//         .where("section", isEqualTo: section)
//         .get();
//
//     if (snap.docs.isEmpty) {
//       throw "No timetable found";
//     }
//
//     final subjects = await _db.collection("subjects").get();
//     final teachers = await _db.collection("teachers").get();
//     final rooms = await _db.collection("classrooms").get();
//
//     final subjectMap = {
//       for (var d in subjects.docs)
//         d.id: d["name"].toString()
//     };
//
//     final teacherMap = {
//       for (var d in teachers.docs)
//         d.id: d["name"].toString()
//     };
//
//     final roomMap = {
//       for (var d in rooms.docs)
//         d.id: d["name"].toString()
//     };
//
//     final Map<String, List<String>> grid = {
//       for (var d in days)
//         d: List.filled(timeSlots.length, "")
//     };
//
//     for (var doc in snap.docs) {
//
//       final data = doc.data();
//       final day = data["day"];
//       final time = data["time"];
//       final group = data["group"] ?? "ALL";
//
//       if (!days.contains(day)) continue;
//
//       final index = timeSlots.indexOf(time);
//       if (index == -1) continue;
//
//       final subject =
//           subjectMap[data["subjectId"]] ?? "";
//
//       final teacher =
//           teacherMap[data["teacherId"]] ?? "";
//
//       final venueId =
//           data["venueId"] ?? "";
//
//       final venueName =
//           roomMap[data["venueId"]] ?? "";
//
//       final cell =
//           "$subject\n"
//           "$teacher\n"
//           "$venueId - $venueName ($group)";
//
//       if (grid[day]![index].isEmpty) {
//         grid[day]![index] = cell;
//       } else {
//         grid[day]![index] =
//         "${grid[day]![index]}"
//             "\n\n────────────\n\n"
//             "$cell";
//       }
//     }
//
//     return _buildPdf(
//       title:
//       "Department: $department | Semester: $semester | Section: $section",
//       grid: grid,
//     );
//   }
//
//   // =====================================================
//   // TEACHER WEEKLY PDF (RESTORED PROPERLY)
//   // =====================================================
//
//   Future<Uint8List> generateTeacherWeeklyPdf({
//     required String teacherId,
//   }) async {
//
//     final snap = await _db
//         .collection("timetable")
//         .where("teacherId", isEqualTo: teacherId)
//         .get();
//
//     if (snap.docs.isEmpty) {
//       throw "No timetable found";
//     }
//
//     final subjects =
//     await _db.collection("subjects").get();
//
//     final rooms =
//     await _db.collection("classrooms").get();
//
//     final teacherSnap =
//     await _db.collection("teachers")
//         .doc(teacherId)
//         .get();
//
//     final teacherName =
//     teacherSnap.exists
//         ? teacherSnap["name"]
//         : "Teacher";
//
//     final subjectMap = {
//       for (var d in subjects.docs)
//         d.id: d["name"].toString()
//     };
//
//     final roomMap = {
//       for (var d in rooms.docs)
//         d.id: d["name"].toString()
//     };
//
//     final Map<String, List<String>> grid = {
//       for (var d in days)
//         d: List.filled(timeSlots.length, "")
//     };
//
//     for (var doc in snap.docs) {
//
//       final data = doc.data();
//       final day = data["day"];
//       final time = data["time"];
//       final group = data["group"] ?? "ALL";
//
//       if (!days.contains(day)) continue;
//
//       final index = timeSlots.indexOf(time);
//       if (index == -1) continue;
//
//       final subject =
//           subjectMap[data["subjectId"]] ?? "";
//
//       final venueId =
//           data["venueId"] ?? "";
//
//       final venueName =
//           roomMap[data["venueId"]] ?? "";
//
//       final cell =
//           "$subject\n"
//           "$venueId - $venueName ($group)";
//
//       if (grid[day]![index].isEmpty) {
//         grid[day]![index] = cell;
//       } else {
//         grid[day]![index] =
//         "${grid[day]![index]}"
//             "\n\n────────────\n\n"
//             "$cell";
//       }
//     }
//
//     return _buildPdf(
//       title:
//       "Teacher: $teacherName (Weekly Timetable)",
//       grid: grid,
//     );
//   }
//
//   // =====================================================
//   // PDF BUILDER (UNCHANGED)
//   // =====================================================
//
//   Future<Uint8List> _buildPdf({
//     required String title,
//     required Map<String, List<String>> grid,
//   }) async {
//
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4.landscape,
//         margin: const pw.EdgeInsets.all(16),
//         build: (_) => [
//
//           pw.Center(
//             child: pw.Text(
//               title,
//               style: pw.TextStyle(
//                 fontSize: 14,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ),
//
//           pw.SizedBox(height: 12),
//
//           pw.Table(
//             border: pw.TableBorder.all(),
//             children: [
//
//               pw.TableRow(
//                 children: [
//                   _header("Day"),
//                   ...timeSlots.map(_header),
//                 ],
//               ),
//
//               for (var day in days)
//                 pw.TableRow(
//                   children: [
//                     _header(day),
//                     ...List.generate(
//                       timeSlots.length,
//                           (i) => _cell(grid[day]![i]),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   // =====================================================
//   // UI
//   // =====================================================
//
//   pw.Widget _header(String text) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(4),
//       alignment: pw.Alignment.center,
//       child: pw.Text(
//         text,
//         style: pw.TextStyle(
//           fontWeight: pw.FontWeight.bold,
//           fontSize: 9,
//         ),
//       ),
//     );
//   }
//
//   pw.Widget _cell(String text) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(4),
//       alignment: pw.Alignment.center,
//       child: pw.Text(
//         text,
//         textAlign: pw.TextAlign.center,
//         style: const pw.TextStyle(fontSize: 8),
//       ),
//     );
//   }
// }