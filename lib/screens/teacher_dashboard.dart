import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'login_screen.dart';
import '../utils/timetable_pdf.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool loading = true;
  bool generatingPdf = false;

  String? teacherDocId; //  teachers collection document ID
  String teacherName = "Teacher";

  List<QueryDocumentSnapshot> todayLectures = [];
  Map<String, String> subjectMap = {};

  @override
  void initState() {
    super.initState();
    loadTeacherAndLectures();

  }
  Future<void> loadSubjects() async {
    final snap = await _db.collection("subjects").get();

    for (var d in snap.docs) {
      subjectMap[d.id] = d["name"];
    }
  }

  // =====================================================
  // LOAD TEACHER + TODAY LECTURES (MERGED FLOW)
  // =====================================================
  Future<void> loadTeacherAndLectures() async {
    try {
      final uid = _auth.currentUser!.uid;

      // 1️ Get teacherId from users collection
      final userSnap = await _db.collection("users").doc(uid).get();

      if (!userSnap.exists || userSnap["role"] != "teacher") {
        throw "Not a teacher account";
      }

      teacherDocId = userSnap["teacherId"];
      await loadSubjects();

      // 2️ Get teacher name
      final teacherSnap =
      await _db.collection("teachers").doc(teacherDocId).get();

      if (teacherSnap.exists) {
        teacherName = teacherSnap["name"] ?? "Teacher";
      }

      // 3️ Load today's lectures
      await loadTodayLectures();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => loading = false);
  }

  // =====================================================
  // LOAD TODAY LECTURES
  // =====================================================
  Future<void> loadTodayLectures() async {
    if (teacherDocId == null) return;

    final today =
    DateFormat('EEE').format(DateTime.now()).toUpperCase(); // MON

    final snap = await _db
        .collection("timetable")
        .where("teacherId", isEqualTo: teacherDocId)
        .where("day", isEqualTo: today)
        // .orderBy("time")
        .get();

    setState(() {
      todayLectures = snap.docs;
    });
  }

  // =====================================================
  // GENERATE TEACHER WEEKLY PDF
  // =====================================================
  Future<void> generateTeacherPdf() async {
    if (teacherDocId == null || generatingPdf) return;

    setState(() => generatingPdf = true);

    try {
      final bytes = await TimetablePdfService()
          .generateTeacherWeeklyPdf(teacherId: teacherDocId!);

      await Printing.sharePdf(
        bytes: bytes,
        filename: "teacher_timetable.pdf",
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("PDF Error: $e")));
    } finally {
      if (mounted) setState(() => generatingPdf = false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $teacherName",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Today's Lectures",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: todayLectures.isEmpty
                  ? const Center(child: Text("No lectures today 🎉"))
                  : ListView.builder(
                itemCount: todayLectures.length,
                itemBuilder: (context, i) {
                  final d =
                  todayLectures[i].data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        subjectMap[d['subjectId']] ?? "Subject",
                      ),
                      subtitle: Text(
                        "${d["time"] ?? ""} | Section ${d["section"] ?? ""}",
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: generatingPdf
                      ? const Text("Generating...")
                      : const Text("My Weekly Timetable PDF"),
                  onPressed: generatingPdf ? null : generateTeacherPdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
