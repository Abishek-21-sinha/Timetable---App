import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'generate_pdf_screen.dart';
import 'student_timetable_screen.dart';   // 👈 ADD THIS

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ✅ VIEW TIMETABLE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text("View Timetable"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentTimetableScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// ✅ GENERATE PDF BUTTON (existing)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate Weekly PDF"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GeneratePdfScreen(),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}