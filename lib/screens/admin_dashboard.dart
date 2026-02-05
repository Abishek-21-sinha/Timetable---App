import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:time_table/screens/admin_lecture_list_screen.dart';
import 'package:time_table/screens/admin_master_data_screen.dart';

import 'login_screen.dart';
import 'add_lecture_screen.dart';
import 'manage_departments_screen.dart';
import 'manage_sections_screen.dart';
import 'manage_subjects_screen.dart';
import 'manage_classrooms_screen.dart';
import 'generate_pdf_screen.dart';
import 'manage_teachers_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget dashBtn({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " Welcome Admin",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),

            dashBtn(
              icon: Icons.add,
              title: "Add Lecture / Timetable",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLectureScreen()),
                );
              },
            ),
            dashBtn(
              icon: Icons.edit_calendar,
              title: "View / Edit Timetable",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLectureListScreen(),
                  ),
                );
              },
            ),
            dashBtn(
              icon: Icons.account_tree,
              title: "Manage Departments",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageDepartmentsScreen()),
                );
              },
            ),

            dashBtn(
              icon: Icons.group_work,
              title: "Manage Sections",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSectionsScreen()),
                );
              },
            ),

            dashBtn(
              icon: Icons.book,
              title: "Manage Subjects",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSubjectsScreen()),
                );
              },
            ),

            dashBtn(
              icon: Icons.meeting_room,
              title: "Manage Classrooms/Venues",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageClassroomsScreen()),
                );
              },
            ),
            dashBtn(
              icon: Icons.person,
              title: "Manage Teachers",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageTeachersScreen()),
                );
              },
            ),
            dashBtn(
              icon: Icons.storage,
              title: "Master Data (All Inputs)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMasterDataScreen()),
                );
              },
            ),

            dashBtn(
              icon: Icons.picture_as_pdf,
              title: "Generate Weekly PDF",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneratePdfScreen()),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}
