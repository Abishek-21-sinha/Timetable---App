import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'edit_lecture.dart';

class AdminLectureListScreen extends StatefulWidget {
  const AdminLectureListScreen({super.key});

  @override
  State<AdminLectureListScreen> createState() =>
      _AdminLectureListScreenState();
}

class _AdminLectureListScreenState extends State<AdminLectureListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, String> subjectMap = {};
  Map<String, String> teacherMap = {};
  Map<String, String> venueMap = {};

  @override
  void initState() {
    super.initState();
    loadMasterData();
  }

  // =====================================================
  // LOAD MASTER DATA (Subject / Teacher / Venue names)
  // =====================================================
  Future<void> loadMasterData() async {
    final subjects = await _db.collection("subjects").get();
    final teachers = await _db.collection("teachers").get();
    final venues = await _db.collection("classrooms").get();

    for (var d in subjects.docs) {
      subjectMap[d.id] = d["name"];
    }
    for (var d in teachers.docs) {
      teacherMap[d.id] = d["name"];
    }
    for (var d in venues.docs) {
      venueMap[d.id] = d["name"];
    }

    if (mounted) setState(() {});
  }

  // =====================================================
  // DELETE LECTURE
  // =====================================================
  Future<void> deleteLecture(String docId) async {
    await _db.collection("timetable").doc(docId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lecture deleted")),
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Lectures / Timetable"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection("timetable")
            .orderBy("day")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No lectures found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data() as Map<String, dynamic>;

              final subject =
                  subjectMap[d["subjectId"]] ?? d["subjectId"];
              final teacher =
                  teacherMap[d["teacherId"]] ?? d["teacherId"];
              final venue =
                  venueMap[d["venueId"]] ?? d["venueId"];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    "$subject (${d["section"]})",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${d["day"]} | ${d["time"]}\n"
                        "Teacher: $teacher\n"
                        "Venue: $venue",
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == "edit") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditLectureScreen(
                              lectureId: doc.id,
                              lectureData: d,
                            ),
                          ),
                        );
                      } else if (v == "delete") {
                        await deleteLecture(doc.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: "edit",
                        child: Text("Edit"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
