import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditLectureScreen extends StatefulWidget {
  final String lectureId;
  final Map<String, dynamic> lectureData;

  const EditLectureScreen({
    super.key,
    required this.lectureId,
    required this.lectureData,
  });

  @override
  State<EditLectureScreen> createState() => _EditLectureScreenState();
}

class _EditLectureScreenState extends State<EditLectureScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool saving = false;

  String? department;
  int? semester;
  String? section;
  String? subjectId;
  String? teacherId;
  String? venueId;
  String? day;
  String? time;

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> venues = [];

  final List<String> days = ["MON", "TUE", "WED", "THU", "FRI", "SAT"];
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
    loadInitialData();
  }

  // =====================================================
  // LOAD INITIAL DATA
  // =====================================================
  Future<void> loadInitialData() async {
    final d = widget.lectureData;

    department = d["department"];
    semester = d["semester"];
    section = d["section"];
    subjectId = d["subjectId"];
    teacherId = d["teacherId"];
    venueId = d["venueId"];
    day = d["day"];
    time = d["time"];

    final subSnap = await _db.collection("subjects").get();
    final teacherSnap = await _db.collection("teachers").get();
    final venueSnap = await _db.collection("classrooms").get();

    subjects = subSnap.docs
        .map((e) => {"id": e.id, "name": e["name"]})
        .toList();

    teachers = teacherSnap.docs
        .map((e) => {"id": e.id, "name": e["name"]})
        .toList();

    venues = venueSnap.docs
        .map((e) => {"id": e.id, "name": e["name"]})
        .toList();

    if (mounted) setState(() {});
  }

  // =====================================================
  // UPDATE LECTURE WITH CONFLICT CHECK
  // =====================================================
  Future<void> updateLecture() async {
    if (day == null ||
        time == null ||
        venueId == null ||
        subjectId == null ||
        teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      // 🔴 CONFLICT CHECK
      final conflict = await _db
          .collection("timetable")
          .where("day", isEqualTo: day)
          .where("time", isEqualTo: time)
          .where("venueId", isEqualTo: venueId)
          .get();

      for (var d in conflict.docs) {
        if (d.id != widget.lectureId) {
          throw "This venue is already booked for this time";
        }
      }

      // ✅ UPDATE
      await _db.collection("timetable").doc(widget.lectureId).update({
        "day": day,
        "time": time,
        "venueId": venueId,
        "subjectId": subjectId,
        "teacherId": teacherId,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lecture updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) setState(() => saving = false);
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Lecture"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: subjectId,
              items: subjects
                  .map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem<String>(
                  value: s["id"] as String,
                  child: Text(s["name"].toString()),
                ),
              )
                  .toList(),
              onChanged: (v) {
                setState(() => subjectId = v);
              },
              decoration: const InputDecoration(labelText: "Subject"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: teacherId,
              items: teachers
                  .map<DropdownMenuItem<String>>(
                    (t) => DropdownMenuItem<String>(
                  value: t["id"] as String,
                  child: Text(t["name"].toString()),
                ),
              )
                  .toList(),
              onChanged: (v) {
                setState(() => teacherId = v);
              },
              decoration: const InputDecoration(labelText: "Teacher"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: venueId,
              items: venues
                  .map<DropdownMenuItem<String>>(
                    (v) => DropdownMenuItem<String>(
                  value: v["id"] as String,
                  child: Text(v["name"].toString()),
                ),
              )
                  .toList(),
              onChanged: (v) {
                setState(() => venueId = v);
              },
              decoration: const InputDecoration(labelText: "Venue"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: day,
              items: days
                  .map(
                    (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => day = v),
              decoration: const InputDecoration(labelText: "Day"),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: time,
              items: timeSlots
                  .map(
                    (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => time = v),
              decoration: const InputDecoration(labelText: "Time Slot"),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : updateLecture,
                child: saving
                    ? const CircularProgressIndicator()
                    : const Text("Update Lecture"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
