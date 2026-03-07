import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherApprovalScreen extends StatelessWidget {
  const TeacherApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final teachersStream = FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "teacher")
        .where("status", isEqualTo: "pending")
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teachersStream,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No Pending Teachers"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data = docs[index].data() as Map<String, dynamic>;
              final uid = docs[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data["name"] ?? ""),
                  subtitle: Text(data["email"] ?? ""),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// APPROVE BUTTON
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid)
                              .update({
                            "status": "approved",
                            "isActive": true
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Teacher Approved"),
                            ),
                          );
                        },
                      ),

                      /// REJECT BUTTON
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(uid)
                              .update({
                            "status": "rejected",
                            "isActive": false
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Teacher Rejected"),
                            ),
                          );
                        },
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