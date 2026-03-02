import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageSectionsScreen extends StatefulWidget {
  const ManageSectionsScreen({super.key});

  @override
  State<ManageSectionsScreen> createState() => _ManageSectionsScreenState();
}

class _ManageSectionsScreenState extends State<ManageSectionsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Dropdown selections
  String? selectedDepartment;
  int selectedSemester = 1;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  // Add section controller
  final TextEditingController sectionC = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    sectionC.dispose();
    super.dispose();
  }

  //  Add Section
  Future<void> addSection() async {
    final section = sectionC.text.trim().toUpperCase();

    if (selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Please select Department")),
      );
      return;
    }

    if (section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Please enter Section (A/B/C)")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final docId = "${selectedDepartment}_${selectedSemester}_$section";

      final docRef = _db.collection("sections").doc(docId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" This section already exists!")),
        );
        return;
      }

      await docRef.set({
        "department": selectedDepartment,
        "semester": selectedSemester,
        "section": section,
        "createdAt": FieldValue.serverTimestamp(),
      });

      sectionC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Section Added Successfully!")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }
  }

  //  Delete Section
  Future<void> deleteSection(String docId) async {
    try {
      await _db.collection("sections").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Section Deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Delete Error: $e")),
      );
    }
  }

  //  Add Section Dialog
  void openAddDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Section"),
          content: TextField(
            controller: sectionC,
            decoration: const InputDecoration(
              labelText: "Section (Ex: A / B / C)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                sectionC.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                await addSection();
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
        title: const Text("Manage Sections"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            //  Department Dropdown (from Firestore)
            StreamBuilder<QuerySnapshot>(
              stream: depStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

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

            //  Semester Dropdown
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

            //  Sections List
            Expanded(
              child: selectedDepartment == null
                  ? const Center(
                child: Text("👆 Select Department first"),
              )
                  : StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection("sections")
                    .where("department", isEqualTo: selectedDepartment)
                    .where("semester", isEqualTo: selectedSemester)
                    // .orderBy("section")
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
                      child: Text("No sections found "),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final dept = data["department"] ?? "";
                      final sem = data["semester"] ?? "";
                      final sec = data["section"] ?? "";

                      return Card(
                        child: ListTile(
                          title: Text("Section $sec"),
                          subtitle: Text("Dept: $dept | Sem: $sem"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Delete Section"),
                                  content: Text(
                                      "Delete Section $sec (Sem $sem - $dept)?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await deleteSection(doc.id);
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
