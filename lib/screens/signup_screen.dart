import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  String selectedRole = "student";
  bool loading = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedDepartment;
  int selectedSemester = 1;
  String? selectedSection;

  String? selectedTeacherId;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  List<Map<String, dynamic>> sectionList = [];

  bool loadingSections = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> loadSections() async {
    if (selectedDepartment == null) return;

    setState(() {
      loadingSections = true;
      selectedSection = null;
      sectionList = [];
    });

    try {
      final snap = await _db
          .collection("sections")
          .where("department", isEqualTo: selectedDepartment)
          .where("semester", isEqualTo: selectedSemester)
          .get();

      final list = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();

      list.sort((a, b) {
        final sa = (a["section"] ?? "").toString();
        final sb = (b["section"] ?? "").toString();
        return sa.compareTo(sb);
      });

      setState(() {
        sectionList = list;
        loadingSections = false;
      });
    } catch (e) {
      setState(() => loadingSections = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Section Load Error: $e")),
      );
    }
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email);
  }

  Future<void> signup() async {
    final name = nameC.text.trim();
    final email = emailC.text.trim().toLowerCase();
    final pass = passC.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email")),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    /// STUDENT VALIDATION
    if (selectedRole == "student") {
      if (selectedDepartment == null ||
          selectedSection == null ||
          selectedDepartment!.isEmpty ||
          selectedSection!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select Department, Semester, Section")),
        );
        return;
      }
    }

    /// TEACHER VALIDATION
    if (selectedRole == "teacher") {
      if (selectedTeacherId == null || selectedTeacherId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select Teacher")),
        );
        return;
      }

      /// GET TEACHER DATA FROM FIRESTORE
      final teacherDoc =
      await _db.collection("teachers").doc(selectedTeacherId).get();

      if (!teacherDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teacher not found")),
        );
        return;
      }

      final teacherData = teacherDoc.data()!;
      final teacherEmail = (teacherData["email"] ?? "").toString().toLowerCase();

      /// EMAIL MATCH CHECK
      if (teacherEmail != email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Use the same email that admin registered")),
        );
        return;
      }
    }

    try {
      setState(() => loading = true);

      final userCred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final uid = userCred.user!.uid;

      final Map<String, dynamic> userData = {
        "name": name,
        "email": email,
        "role": selectedRole,
        "isActive": selectedRole == "teacher" ? false : true,
        "status": selectedRole == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (selectedRole == "student") {
        userData["department"] = selectedDepartment;
        userData["semester"] = selectedSemester;
        userData["section"] = selectedSection;
      }

      if (selectedRole == "teacher") {
        userData["teacherId"] = selectedTeacherId;
      }

      await _db.collection("users").doc(uid).set(userData);

      await userCred.user!.sendEmailVerification();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email sent! Verify then login."),
        ),
      );

      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Error: $e")),
      );
    }
  }
  Widget drop<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? (v) => onChanged(v) : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depStream = _db.collection("departments").orderBy("code").snapshots();
    final teacherStream = _db.collection("teachers").orderBy("name").snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              drop<String>(
                label: "Select Role",
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                  DropdownMenuItem(value: "student", child: Text("Student")),
                ],
                onChanged: (val) async {
                  if (val == null) return;

                  setState(() {
                    selectedRole = val;

                    selectedDepartment = null;
                    selectedSection = null;
                    selectedTeacherId = null;

                    sectionList.clear();
                  });
                },
              ),

              if (selectedRole == "student") ...[
                StreamBuilder<QuerySnapshot>(
                  stream: depStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final docs = snapshot.data!.docs;
                    final items = docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final code = (data["code"] ?? d.id).toString();
                      final name = (data["name"] ?? "").toString();
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text("$code - $name"),
                      );
                    }).toList();

                    return drop<String>(
                      label: "Department",
                      value: selectedDepartment,
                      items: items,
                      enabled: items.isNotEmpty,
                      onChanged: (v) async {
                        setState(() {
                          selectedDepartment = v;
                          selectedSection = null;
                          sectionList.clear();
                        });
                        await loadSections();
                      },
                    );
                  },
                ),

                drop<int>(
                  label: "Semester",
                  value: selectedSemester,
                  items: semesters
                      .map((s) => DropdownMenuItem<int>(
                    value: s,
                    child: Text("Semester $s"),
                  ))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() {
                      selectedSemester = v;
                      selectedSection = null;
                      sectionList.clear();
                    });

                    if (selectedDepartment != null) {
                      await loadSections();
                    }
                  },
                ),

                if (loadingSections)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: LinearProgressIndicator(),
                  ),

                drop<String>(
                  label: "Section",
                  value: selectedSection,
                  items: sectionList.map((s) {
                    final sec = (s["section"] ?? "").toString();
                    return DropdownMenuItem<String>(
                      value: sec,
                      child: Text(sec),
                    );
                  }).toList(),
                  enabled: sectionList.isNotEmpty,
                  onChanged: (v) {
                    setState(() => selectedSection = v);
                  },
                ),
              ],

              if (selectedRole == "teacher") ...[
                StreamBuilder<QuerySnapshot>(
                  stream: teacherStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final docs = snapshot.data!.docs;
                    final items = docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final id = d.id;
                      final name = (data["name"] ?? "").toString();
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList();

                    return drop<String>(
                      label: "Select Teacher",
                      value: selectedTeacherId,
                      items: items,
                      enabled: items.isNotEmpty,
                      onChanged: (v) {
                        setState(() => selectedTeacherId = v);
                      },
                    );
                  },
                ),
              ],

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : signup,
                  child: loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Create Account"),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
