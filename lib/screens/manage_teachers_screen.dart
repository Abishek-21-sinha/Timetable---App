import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    super.dispose();
  }

  Future<void> addTeacher() async {
    final name = nameC.text.trim();
    final email = emailC.text.trim().toLowerCase();
    final phone = phoneC.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name & Email required")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // 🔹 1. Check duplicate teacher in Firestore
      final dup = await _db
          .collection("teachers")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (dup.docs.isNotEmpty) {
        throw "Teacher already exists";
      }

      // 🔹 2. Create Firebase Auth user
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: "teacher@123", // default password
      );

      final uid = cred.user!.uid;

      // 🔹 3. Save teacher profile (UID based)
      await _db.collection("teachers").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 🔹 4. ALSO save in users collection (VERY IMPORTANT)
      await _db.collection("users").doc(uid).set({
        "uid": uid,
        "email": email,
        "role": "teacher",
        "isActive": true,
        "createdAt": FieldValue.serverTimestamp(),
      });

      nameC.clear();
      emailC.clear();
      phoneC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Teacher added successfully (password: teacher@123)"),
        ),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteTeacher(String docId) async {
    try {
      await _db.collection("teachers").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Teacher"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "Teacher Name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email (optional)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone (optional)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameC.clear();
              emailC.clear();
              phoneC.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
              await addTeacher();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection("teachers")
        .orderBy("name", descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Teachers"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No teachers added"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data["name"] ?? "").toString();
              final email = (data["email"] ?? "").toString();
              final phone = (data["phone"] ?? "").toString();

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    [
                      if (email.isNotEmpty) "Email: $email",
                      if (phone.isNotEmpty) "Phone: $phone",
                    ].join(" | "),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Teacher"),
                          content: Text("Delete $name ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await deleteTeacher(doc.id);
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
