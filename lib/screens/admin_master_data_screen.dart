import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminMasterDataScreen extends StatefulWidget {
  const AdminMasterDataScreen({super.key});

  @override
  State<AdminMasterDataScreen> createState() => _AdminMasterDataScreenState();
}

class _AdminMasterDataScreenState extends State<AdminMasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  final deptCodeC = TextEditingController();
  final deptNameC = TextEditingController();

  String? secDept;
  int secSem = 1;
  final secNameC = TextEditingController();

  String? subDept;
  int subSem = 1;
  final subNameC = TextEditingController();

  final teacherNameC = TextEditingController();
  final teacherEmailC = TextEditingController();
  final teacherPhoneC = TextEditingController();

  final venueIdC = TextEditingController();
  final venueNameC = TextEditingController();
  final venueCapC = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    deptCodeC.dispose();
    deptNameC.dispose();
    secNameC.dispose();
    subNameC.dispose();
    teacherNameC.dispose();
    teacherEmailC.dispose();
    teacherPhoneC.dispose();
    venueIdC.dispose();
    venueNameC.dispose();
    venueCapC.dispose();
    super.dispose();
  }

  Future<void> addDepartment() async {
    final code = deptCodeC.text.trim().toUpperCase();
    final name = deptNameC.text.trim();

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Department Code and Name")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      await _db.collection("departments").doc(code).set({
        "code": code,
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
      });

      deptCodeC.clear();
      deptNameC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Department saved")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteDepartment(String deptCode) async {
    try {
      await _db.collection("departments").doc(deptCode).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Department deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> addSection() async {
    final section = secNameC.text.trim().toUpperCase();

    if (secDept == null || section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Department and enter Section")),
      );
      return;
    }

    final docId = "${secDept}_${secSem}_$section";

    try {
      setState(() => loading = true);

      await _db.collection("sections").doc(docId).set({
        "department": secDept,
        "semester": secSem,
        "section": section,
        "createdAt": FieldValue.serverTimestamp(),
      });

      secNameC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Section saved")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteSection(String docId) async {
    try {
      await _db.collection("sections").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Section deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> addSubject() async {
    final name = subNameC.text.trim();

    if (subDept == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Department and enter Subject")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      await _db.collection("subjects").add({
        "department": subDept,
        "semester": subSem,
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
      });

      subNameC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject saved")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteSubject(String docId) async {
    try {
      await _db.collection("subjects").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> addTeacher() async {
    final name = teacherNameC.text.trim();
    final email = teacherEmailC.text.trim().toLowerCase();
    final phone = teacherPhoneC.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Teacher Name")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      await _db.collection("teachers").add({
        "name": name,
        "email": email,
        "phone": phone,
        "createdAt": FieldValue.serverTimestamp(),
      });

      teacherNameC.clear();
      teacherEmailC.clear();
      teacherPhoneC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher saved")),
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

  Future<void> addVenue() async {
    final id = venueIdC.text.trim().toUpperCase();
    final name = venueNameC.text.trim();
    final capText = venueCapC.text.trim();

    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Venue ID and Name")),
      );
      return;
    }

    int cap = 0;
    if (capText.isNotEmpty) {
      final parsed = int.tryParse(capText);
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Capacity must be number")),
        );
        return;
      }
      cap = parsed;
    }

    try {
      setState(() => loading = true);

      await _db.collection("classrooms").doc(id).set({
        "id": id,
        "name": name,
        "capacity": cap,
        "createdAt": FieldValue.serverTimestamp(),
      });

      venueIdC.clear();
      venueNameC.clear();
      venueCapC.clear();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venue saved")),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteVenue(String venueId) async {
    try {
      await _db.collection("classrooms").doc(venueId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venue deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget box(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget titleRow(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depStream = _db.collection("departments").orderBy("code").snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Master Data"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Department"),
            Tab(text: "Section"),
            Tab(text: "Subject"),
            Tab(text: "Teacher"),
            Tab(text: "Venue"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                box(
                  Column(
                    children: [
                      titleRow("Add Department"),
                      TextField(
                        controller: deptCodeC,
                        decoration: const InputDecoration(
                          labelText: "Department Code",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: deptNameC,
                        decoration: const InputDecoration(
                          labelText: "Department Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : addDepartment,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                titleRow("Department List"),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: depStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No departments found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final code = (data["code"] ?? doc.id).toString();
                          final name = (data["name"] ?? "").toString();

                          return Card(
                            child: ListTile(
                              title: Text("$code - $name"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteDepartment(code);
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                box(
                  Column(
                    children: [
                      titleRow("Add Section"),
                      StreamBuilder<QuerySnapshot>(
                        stream: depStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final docs = snapshot.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: secDept,
                            decoration: const InputDecoration(
                              labelText: "Department",
                              border: OutlineInputBorder(),
                            ),
                            items: docs.map((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final code = (data["code"] ?? d.id).toString();
                              final name = (data["name"] ?? "").toString();
                              return DropdownMenuItem(
                                value: code,
                                child: Text("$code - $name"),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => secDept = v);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: secSem,
                        decoration: const InputDecoration(
                          labelText: "Semester",
                          border: OutlineInputBorder(),
                        ),
                        items: semesters
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("Semester $s"),
                        ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => secSem = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: secNameC,
                        decoration: const InputDecoration(
                          labelText: "Section",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : addSection,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                titleRow("Section List"),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection("sections")
                        .orderBy("department")
                        .orderBy("semester")
                        .orderBy("section")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No sections found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final dept = (data["department"] ?? "").toString();
                          final sem = (data["semester"] ?? "").toString();
                          final sec = (data["section"] ?? "").toString();

                          return Card(
                            child: ListTile(
                              title: Text("Dept: $dept  Sem: $sem  Sec: $sec"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteSection(doc.id);
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                box(
                  Column(
                    children: [
                      titleRow("Add Subject"),
                      StreamBuilder<QuerySnapshot>(
                        stream: depStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final docs = snapshot.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: subDept,
                            decoration: const InputDecoration(
                              labelText: "Department",
                              border: OutlineInputBorder(),
                            ),
                            items: docs.map((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final code = (data["code"] ?? d.id).toString();
                              final name = (data["name"] ?? "").toString();
                              return DropdownMenuItem(
                                value: code,
                                child: Text("$code - $name"),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => subDept = v);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: subSem,
                        decoration: const InputDecoration(
                          labelText: "Semester",
                          border: OutlineInputBorder(),
                        ),
                        items: semesters
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("Semester $s"),
                        ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => subSem = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subNameC,
                        decoration: const InputDecoration(
                          labelText: "Subject Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : addSubject,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                titleRow("Subject List"),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                    _db.collection("subjects").orderBy("name").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No subjects found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final dept = (data["department"] ?? "").toString();
                          final sem = (data["semester"] ?? "").toString();
                          final name = (data["name"] ?? "").toString();

                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text("Dept: $dept  Sem: $sem"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteSubject(doc.id);
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                box(
                  Column(
                    children: [
                      titleRow("Add Teacher"),
                      TextField(
                        controller: teacherNameC,
                        decoration: const InputDecoration(
                          labelText: "Teacher Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacherEmailC,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacherPhoneC,
                        decoration: const InputDecoration(
                          labelText: "Phone",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : addTeacher,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                titleRow("Teacher List"),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                    _db.collection("teachers").orderBy("name").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No teachers found"));
                      }

                      return ListView.builder(
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
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteTeacher(doc.id);
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                box(
                  Column(
                    children: [
                      titleRow("Add Venue"),
                      TextField(
                        controller: venueIdC,
                        decoration: const InputDecoration(
                          labelText: "Venue ID",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: venueNameC,
                        decoration: const InputDecoration(
                          labelText: "Venue Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: venueCapC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Capacity",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : addVenue,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                titleRow("Venue List"),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection("classrooms")
                        .orderBy("id")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text("No venues found"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final id = (data["id"] ?? doc.id).toString();
                          final name = (data["name"] ?? "").toString();
                          final cap = (data["capacity"] ?? 0).toString();

                          return Card(
                            child: ListTile(
                              title: Text("$id - $name"),
                              subtitle: Text("Capacity: $cap"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteVenue(id);
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
        ],
      ),
    );
  }
}
