import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageClassroomsScreen extends StatefulWidget {
  const ManageClassroomsScreen({super.key});

  @override
  State<ManageClassroomsScreen> createState() => _ManageClassroomsScreenState();
}

class _ManageClassroomsScreenState extends State<ManageClassroomsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController roomIdC = TextEditingController();
  final TextEditingController roomNameC = TextEditingController();
  final TextEditingController capacityC = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    roomIdC.dispose();
    roomNameC.dispose();
    capacityC.dispose();
    super.dispose();
  }

  Future<void> addClassroom() async {
    final id = roomIdC.text.trim().toUpperCase();
    final name = roomNameC.text.trim();
    final capText = capacityC.text.trim();

    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Room ID and Room Name")),
      );
      return;
    }

    int? capacity;
    if (capText.isNotEmpty) {
      capacity = int.tryParse(capText);
      if (capacity == null || capacity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Capacity must be a valid number")),
        );
        return;
      }
    }

    try {
      setState(() => loading = true);

      final docRef = _db.collection("classrooms").doc(id);
      final doc = await docRef.get();

      if (doc.exists) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This Room ID already exists")),
        );
        return;
      }

      await docRef.set({
        "id": id,
        "name": name,
        "capacity": capacity ?? 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      roomIdC.clear();
      roomNameC.clear();
      capacityC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classroom added")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteClassroom(String docId) async {
    try {
      await _db.collection("classrooms").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classroom deleted")),
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
        title: const Text("Add Classroom / Venue"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomIdC,
                decoration: const InputDecoration(
                  labelText: "Room ID (CR101 / LAB1)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomNameC,
                decoration: const InputDecoration(
                  labelText: "Room Name (CR-101 / Lab-1)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capacityC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Capacity (optional)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              roomIdC.clear();
              roomNameC.clear();
              capacityC.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
              await addClassroom();
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
    final stream =
    _db.collection("classrooms").orderBy("id", descending: false).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Classrooms / Venues"),
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
            return const Center(child: Text("No classrooms added"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final id = (data["id"] ?? doc.id).toString();
              final name = (data["name"] ?? "").toString();
              final capacity = (data["capacity"] ?? 0).toString();

              return Card(
                child: ListTile(
                  title: Text("$id - $name"),
                  subtitle: Text("Capacity: $capacity"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Classroom"),
                          content: Text("Delete $id ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await deleteClassroom(doc.id);
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
