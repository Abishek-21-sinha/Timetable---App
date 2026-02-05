import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddLectureScreen extends StatefulWidget {
  const AddLectureScreen({super.key});

  @override
  State<AddLectureScreen> createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends State<AddLectureScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  final List<String> days = ["MON", "TUE", "WED", "THU", "FRI", "SAT"];

  final List<String> timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "02:00-03:00",
    "03:00-04:00",
  ];

  String? selectedDepartment;
  int selectedSemester = 1;
  String? selectedSection;
  String? selectedSubjectId;
  String? selectedTeacherId;
  String? selectedVenueId;
  String? selectedDay;
  String? selectedTimeSlot;

  bool saving = false;

  List<Map<String, dynamic>> deptList = [];
  List<Map<String, dynamic>> sectionList = [];
  List<Map<String, dynamic>> subjectList = [];
  List<Map<String, dynamic>> teacherList = [];
  List<Map<String, dynamic>> venueList = [];

  @override
  void initState() {
    super.initState();
    loadDepartments();
    loadTeachers();
    loadVenues();
  }

  Future<void> loadDepartments() async {
    final snap = await _db.collection("departments").orderBy("code").get();
    setState(() {
      deptList = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
    });
  }

  Future<void> loadTeachers() async {
    final snap = await _db.collection("teachers").get();
    setState(() {
      teacherList = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
    });
  }

  Future<void> loadVenues() async {
    final snap = await _db.collection("classrooms").orderBy("id").get();
    setState(() {
      venueList = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
    });
  }

  Future<void> loadSections() async {
    if (selectedDepartment == null) return;

    final snap = await _db
        .collection("sections")
        .where("department", isEqualTo: selectedDepartment)
        .where("semester", isEqualTo: selectedSemester)
        .get();

    setState(() {
      sectionList = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
    });

    print("selectedDepartment = $selectedDepartment");
    print("selectedSemester = $selectedSemester");
    print("Sections Found = ${snap.docs.length}");
  }

  Future<void> addLecture(Map<String, dynamic> lectureData) async {
    final day = lectureData["day"].toString().trim();
    final time = lectureData["time"].toString().trim();
    final venueId = lectureData["venueId"].toString().trim();

    final conflict = await FirebaseFirestore.instance
        .collection("timetable")
        .where("day", isEqualTo: day)
        .where("time", isEqualTo: time)
        .where("venueId", isEqualTo: venueId)
        .limit(1)
        .get();

    if (conflict.docs.isNotEmpty) {
      throw "❌ Venue already booked for this time slot";
    }

    await FirebaseFirestore.instance
        .collection("timetable")
        .add({
      ...lectureData,
      "day": day,
      "time": time,
      "venueId": venueId,
    });
  }


  Future<void> loadSubjects() async {
    if (selectedDepartment == null) return;

    final snap = await _db
        .collection("subjects")
        .where("department", isEqualTo: selectedDepartment)
        .where("semester", isEqualTo: selectedSemester)
        .get();

    setState(() {
      subjectList = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
    });

    print("Subjects Found = ${snap.docs.length}");
  }


  String buildDocId(String day, String time, String venueId) {
    return "${day}_${time}_$venueId";
  }
  Future<void> checkVenueConflict({
    required String day,
    required String time,
    required String venueId,
    String? ignoreDocId, // edit ke liye
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection("timetable")
        .where("day", isEqualTo: day)
        .where("time", isEqualTo: time)
        .where("venueId", isEqualTo: venueId)
        .get();

    for (final doc in snap.docs) {
      if (ignoreDocId != null && doc.id == ignoreDocId) continue;
      throw "This venue is already booked for this time slot";
    }
  }

  Future<void> saveLecture() async {
    if (selectedDepartment == null ||
        selectedSemester == null ||
        selectedSection == null ||
        selectedSubjectId == null ||
        selectedTeacherId == null ||
        selectedVenueId == null ||
        selectedDay == null ||
        selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all fields")),
      );
      return;
    }

    if (saving) return; //  double click protection

    setState(() => saving = true);

    try {
      final lectureData = {
        "day": selectedDay,
        "time": selectedTimeSlot,
        "venueId": selectedVenueId,
        "department": selectedDepartment,
        "semester": selectedSemester,
        "section": selectedSection,
        "subjectId": selectedSubjectId,
        "teacherId": selectedTeacherId,
        "createdAt": FieldValue.serverTimestamp(),
      };

      //  CONFLICT CHECK + SAVE (inside addLecture)
      await addLecture(lectureData);

      //  RESET FORM
      setState(() {
        selectedDay = null;
        selectedTimeSlot = null;
        selectedVenueId = null;
        selectedTeacherId = null;
        selectedSubjectId = null;
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lecture saved successfully")),
      );

      // optional
      // Navigator.pop(context);

    } catch (e) {
      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }


  Widget drop<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: (v) => onChanged(v),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Lecture / Timetable"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              drop<String>(
                label: "Department",
                value: selectedDepartment,
                items: deptList.map((d) {
                  final code = (d["code"] ?? d["id"]).toString();
                  final name = (d["name"] ?? "").toString();

                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text("$code - $name"),
                  );
                }).toList(),

                onChanged: (v) async {
                  setState(() {
                    selectedDepartment = v;
                    selectedSection = null;
                    selectedSubjectId = null;
                    sectionList.clear();
                    subjectList.clear();
                  });
                  await loadSections();
                  await loadSubjects();
                },
              ),
              drop<int>(
                label: "Semester",
                value: selectedSemester,
                items: semesters
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text("Semester $s"),
                ))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() {
                    selectedSemester = v;
                    selectedSection = null;
                    selectedSubjectId = null;
                    sectionList.clear();
                    subjectList.clear();
                  });
                  await loadSections();
                  await loadSubjects();
                },
              ),
              drop<String>(
                label: "Section",
                value: selectedSection,
                items: sectionList.map((s) {
                  final sec = (s["section"] ?? "").toString();
                  return DropdownMenuItem(
                    value: sec,
                    child: Text(sec),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => selectedSection = v);
                },
              ),
              drop<String>(
                label: "Subject",
                value: selectedSubjectId,
                items: subjectList.map((sub) {
                  final id = (sub["id"] ?? "").toString();
                  final name = (sub["name"] ?? "").toString();
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => selectedSubjectId = v);
                },
              ),
              drop<String>(
                label: "Teacher",
                value: selectedTeacherId,
                items: teacherList.map((t) {
                  final id = (t["id"] ?? "").toString();
                  final name = (t["name"] ?? "").toString();
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => selectedTeacherId = v);
                },
              ),
              drop<String>(
                label: "Venue / Classroom",
                value: selectedVenueId,
                items: venueList.map((v) {
                  final id = (v["id"] ?? "").toString();
                  final name = (v["name"] ?? "").toString();
                  return DropdownMenuItem(
                    value: id,
                    child: Text("$id - $name"),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => selectedVenueId = v);
                },
              ),
              drop<String>(
                label: "Day",
                value: selectedDay,
                items: days
                    .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedDay = v);
                },
              ),
              drop<String>(
                label: "Time Slot",
                value: selectedTimeSlot,
                items: timeSlots
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedTimeSlot = v);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving ? null : saveLecture,
                  child: saving
                      ? const CircularProgressIndicator()
                      : const Text("Save Lecture"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
