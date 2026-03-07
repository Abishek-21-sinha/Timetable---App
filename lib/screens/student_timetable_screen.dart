import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() =>
      _StudentTimetableScreenState();
}

class _StudentTimetableScreenState
    extends State<StudentTimetableScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? department;
  int? semester;
  String? section;

  final List<String> days = [
    "MON","TUE","WED","THU","FRI","SAT"
  ];

  final List<String> timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "02:00-03:00",
    "03:00-04:00",
  ];

  @override
  void initState() {
    super.initState();
    loadStudentProfile();
  }

  Future<void> loadStudentProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await _db.collection("users").doc(uid).get();

    if (snap.exists) {
      final data = snap.data()!;

      setState(() {
        department = data["department"];
        semester = data["semester"] is int
            ? data["semester"]
            : int.tryParse(data["semester"].toString());
        section = data["section"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (department == null || semester == null || section == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Weekly Timetable"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _db
            .collection("timetable")
            .where("department", isEqualTo: department)
            .where("semester", isEqualTo: semester)
            .where("section", isEqualTo: section)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No timetable found"));
          }

          final docs = snapshot.data!.docs;

          return FutureBuilder<QuerySnapshot>(
            future: _db.collection("subjects").get(),
            builder: (context, subjectSnap) {

              if (subjectSnap.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final subjectMap = {
                for (var d in subjectSnap.data!.docs)
                  d.id: d["name"]
              };

              /// Create empty grid
              Map<String, Map<String, String>> grid = {};

              for (var day in days) {
                grid[day] = {};
                for (var time in timeSlots) {
                  grid[day]![time] = "";
                }
              }

              /// Fill grid
              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;

                final subjectName =
                    subjectMap[d["subjectId"]] ?? "";

                final day = d["day"];
                final time = d["time"];

                if (grid.containsKey(day) &&
                    grid[day]!.containsKey(time)) {
                  grid[day]![time] =
                  "$subjectName\n${d["venueId"]}";
                }
              }

              /// Double Scroll (Important Fix)
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: timeSlots.length * 140,
                        child: DataTable(
                          columnSpacing: 20,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 70,
                          border: TableBorder.all(),
                          columns: [
                            const DataColumn(label: Text("Day")),
                            ...timeSlots.map(
                                  (t) => DataColumn(label: Text(t)),
                            )
                          ],
                          rows: days.map((day) {
                            return DataRow(
                              cells: [
                                DataCell(Text(day)),
                                ...timeSlots.map(
                                      (t) => DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        grid[day]![t] ?? "",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}