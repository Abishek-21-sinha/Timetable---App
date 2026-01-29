import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController deptCodeC = TextEditingController();
  final TextEditingController deptNameC = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    deptCodeC.dispose();
    deptNameC.dispose();
    super.dispose();
  }

  //  Add Department
  Future<void> addDepartment() async {
    String code = deptCodeC.text.trim().toUpperCase();
    String name = deptNameC.text.trim();

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Please enter Department Code & Name")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      //  Check already exists
      final docRef = _db.collection("departments").doc(code);
      final doc = await docRef.get();

      if (doc.exists) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Department already exists!")),
        );
        return;
      }

      await docRef.set({
        "code": code,
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
      });

      deptCodeC.clear();
      deptNameC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Department Added Successfully!")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }
  }

  // Delete Department
  Future<void> deleteDepartment(String code) async {
    try {
      await _db.collection("departments").doc(code).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Department Deleted: $code")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Delete Error: $e")),
      );
    }
  }

  //  Add Form Dialog
  void openAddDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Department"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deptCodeC,
                decoration: const InputDecoration(
                  labelText: "Department Code (Ex: CSE)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deptNameC,
                decoration: const InputDecoration(
                  labelText: "Department Name (Ex: Computer Science)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                deptCodeC.clear();
                deptNameC.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                await addDepartment();
                if (mounted) Navigator.pop(context);
              },
              child: loading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Add"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection("departments").orderBy("code").snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Departments"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text(" Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No departments added yet "),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final code = (data["code"] ?? "").toString();
              final name = (data["name"] ?? "").toString();

              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text("$code - $name"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Department"),
                          content: Text("Are you sure you want to delete $code?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await deleteDepartment(code);
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
    );
  }
}
