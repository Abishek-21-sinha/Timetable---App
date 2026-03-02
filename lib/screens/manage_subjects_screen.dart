import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedDepartment;
  int selectedSemester = 1;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  final TextEditingController subjectNameC = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    subjectNameC.dispose();
    super.dispose();
  }

  //  Add Subject
  Future<void> addSubject() async {
    final name = subjectNameC.text.trim();

    if (selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Please select Department")),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Please enter Subject name")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      //  Duplicate check (same dept+sem+name)
      final dupSnap = await _db
          .collection("subjects")
          .where("department", isEqualTo: selectedDepartment)
          .where("semester", isEqualTo: selectedSemester)
          .where("name", isEqualTo: name)
          .get();

      if (dupSnap.docs.isNotEmpty) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Subject already exists!")),
        );
        return;
      }

      await _db.collection("subjects").add({
        "department": selectedDepartment,
        "semester": selectedSemester,
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
      });

      subjectNameC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Subject Added Successfully!")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }
  }

  // Delete Subject
  Future<void> deleteSubject(String docId) async {
    try {
      await _db.collection("subjects").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Subject Deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Delete Error: $e")),
      );
    }
  }

  //  Add Dialog
  void openAddDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: TextField(
            controller: subjectNameC,
            decoration: const InputDecoration(
              labelText: "Subject Name (Ex: DBMS)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                subjectNameC.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                await addSubject();
                if (mounted) Navigator.pop(context);
              },
              child: loading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final depStream = _db.collection("departments").orderBy("code").snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Subjects"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            //  Department dropdown
            StreamBuilder<QuerySnapshot>(
              stream: depStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: "Select Department",
                    border: OutlineInputBorder(),
                  ),
                  items: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final code = data["code"] ?? d.id;
                    final name = data["name"] ?? "";
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text("$code - $name"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDepartment = val;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            //  Semester dropdown
            DropdownButtonFormField<int>(
              value: selectedSemester,
              decoration: const InputDecoration(
                labelText: "Select Semester",
                border: OutlineInputBorder(),
              ),
              items: semesters
                  .map((s) => DropdownMenuItem(
                value: s,
                child: Text("Semester $s"),
              ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedSemester = val);
                }
              },
            ),

            const SizedBox(height: 12),

            //  List of subjects
            Expanded(
              child: selectedDepartment == null
                  ? const Center(child: Text("👆 Select Department first"))
                  : StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection("subjects")
                    .where("department", isEqualTo: selectedDepartment)
                    .where("semester", isEqualTo: selectedSemester)
                    // .orderBy("name")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text(" Something went wrong"));
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No subjects found "),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final name = data["name"] ?? "";
                      final dept = data["department"] ?? "";
                      final sem = data["semester"] ?? "";

                      return Card(
                        child: ListTile(
                          title: Text(name.toString()),
                          subtitle: Text("Dept: $dept | Sem: $sem"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Delete Subject"),
                                  content:
                                  Text("Delete subject: $name ?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await deleteSubject(doc.id);
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
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
