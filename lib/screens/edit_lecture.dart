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

  String? subjectId;
  String? teacherId;
  String? venueId;
  String? day;
  String? time;
  String? group;

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

  final List<String> groups = ["ALL", "G1", "G2"];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  Future<void> loadInitialData() async {
    final data = widget.lectureData;

    subjectId = data["subjectId"];
    teacherId = data["teacherId"];
    venueId = data["venueId"];
    day = data["day"];
    time = data["time"];
    group = data["group"] ?? "ALL";

    final subjectSnap = await _db.collection("subjects").get();
    final teacherSnap = await _db.collection("teachers").get();
    final venueSnap = await _db.collection("classrooms").get();

    subjects = subjectSnap.docs
        .map((d) => {
      "id": d.id,
      "name": d["name"],
    })
        .toList();

    teachers = teacherSnap.docs
        .map((d) => {
      "id": d.id,
      "name": d["name"],
    })
        .toList();

    venues = venueSnap.docs
        .map((d) => {
      "id": d.id,
      "name": d["name"],
    })
        .toList();

    if (mounted) setState(() {});
  }

  // =====================================================
  // UPDATE WITH CONFLICT CHECK
  // =====================================================

  Future<void> updateLecture() async {
    if (subjectId == null ||
        teacherId == null ||
        venueId == null ||
        day == null ||
        time == null ||
        group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => saving = true);

    try {

      /// ======================
      /// 1️⃣ VENUE CONFLICT CHECK
      /// ======================

      final conflict = await _db
          .collection("timetable")
          .where("day", isEqualTo: day)
          .where("time", isEqualTo: time)
          .where("venueId", isEqualTo: venueId)
          .get();

      for (var doc in conflict.docs) {
        if (doc.id != widget.lectureId) {
          throw "❌ This venue is already booked at this time";
        }
      }

      /// ======================
      /// 2️⃣ MAX 3 PER DAY CHECK (Exclude current lecture)
      /// ======================

      final teacherDaySnap = await _db
          .collection("timetable")
          .where("teacherId", isEqualTo: teacherId)
          .where("day", isEqualTo: day)
          .get();

      int count = 0;

      for (var doc in teacherDaySnap.docs) {
        if (doc.id != widget.lectureId) {
          count++;
        }
      }

      if (count >= 3) {
        throw "❌ Teacher already has 3 lectures on $day";
      }

      /// ======================
      /// 3️⃣ NO CONSECUTIVE CHECK
      /// ======================

      final currentIndex = timeSlots.indexOf(time!);

      for (var doc in teacherDaySnap.docs) {

        if (doc.id == widget.lectureId) continue;

        final existingTime = doc["time"].toString();
        final existingIndex = timeSlots.indexOf(existingTime);

        if ((existingIndex - currentIndex).abs() == 1) {
          throw "❌ Teacher cannot have consecutive lectures on $day";
        }
      }

      /// ======================
      /// UPDATE
      /// ======================

      await _db.collection("timetable").doc(widget.lectureId).update({
        "subjectId": subjectId,
        "teacherId": teacherId,
        "venueId": venueId,
        "day": day,
        "time": time,
        "group": group,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lecture updated successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => saving = false);
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
            /// SUBJECT
            DropdownButtonFormField<String>(
              value: subjectId,
              items: subjects
                  .map<DropdownMenuItem<String>>((s) {
                return DropdownMenuItem<String>(
                  value: s["id"].toString(),
                  child: Text(s["name"].toString()),
                );
              })
                  .toList(),
              onChanged: (v) {
                setState(() => subjectId = v);
              },
              decoration: const InputDecoration(labelText: "Subject"),
            ),

            const SizedBox(height: 12),

            /// TEACHER
            DropdownButtonFormField<String>(
              value: teacherId,
              items: teachers
                  .map<DropdownMenuItem<String>>((t) {
                return DropdownMenuItem<String>(
                  value: t["id"].toString(),
                  child: Text(t["name"].toString()),
                );
              })
                  .toList(),
              onChanged: (v) {
                setState(() => teacherId = v);
              },
              decoration: const InputDecoration(labelText: "Teacher"),
            ),

            const SizedBox(height: 12),

            /// VENUE
            DropdownButtonFormField<String>(
              value: venueId,
              items: venues.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(
                  value: v["id"].toString(),
                  child: Text("${v["id"]} - ${v["name"]}"),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => venueId = v);
              },
              decoration: const InputDecoration(labelText: "Venue"),
            ),

            const SizedBox(height: 12),

            /// DAY
            DropdownButtonFormField<String>(
              value: day,
              items: days
                  .map((d) => DropdownMenuItem<String>(
                value: d,
                child: Text(d),
              ))
                  .toList(),
              onChanged: (v) => setState(() => day = v),
              decoration: const InputDecoration(labelText: "Day"),
            ),

            const SizedBox(height: 12),

            /// TIME
            DropdownButtonFormField<String>(
              value: time,
              items: timeSlots
                  .map((t) => DropdownMenuItem<String>(
                value: t,
                child: Text(t),
              ))
                  .toList(),
              onChanged: (v) => setState(() => time = v),
              decoration: const InputDecoration(labelText: "Time Slot"),
            ),

            const SizedBox(height: 12),

            /// GROUP ✅ NEW
            DropdownButtonFormField<String>(
              value: group,
              items: groups
                  .map((g) => DropdownMenuItem<String>(
                value: g,
                child: Text(g),
              ))
                  .toList(),
              onChanged: (v) => setState(() => group = v),
              decoration: const InputDecoration(labelText: "Group"),
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