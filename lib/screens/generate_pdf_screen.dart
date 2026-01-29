import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../utils/timetable_pdf.dart';

class GeneratePdfScreen extends StatefulWidget {
  const GeneratePdfScreen({super.key});

  @override
  State<GeneratePdfScreen> createState() => _GeneratePdfScreenState();
}

class _GeneratePdfScreenState extends State<GeneratePdfScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedDepartment;
  int selectedSemester = 1;
  String? selectedSection;

  final List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  bool loadingSections = false;
  bool generatingPdf = false;

  List<Map<String, dynamic>> sectionList = [];

  Future<void> loadSections() async {
    if (selectedDepartment == null) return;

    setState(() {
      loadingSections = true;
      selectedSection = null;
      sectionList.clear();
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

  Future<void> generatePdf() async {
    setState(() => generatingPdf = true);

    try {
      final bytes = await TimetablePdfService().generateWeeklyPdf(
        department: selectedDepartment!,
        semester: selectedSemester,
        section: selectedSection!,
      );

      if (bytes.length < 1000) {
        throw "Invalid PDF generated";
      }

      await Printing.sharePdf(
        bytes: bytes,
        filename:
        "timetable_${selectedDepartment}_${selectedSemester}_${selectedSection}.pdf",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Error: $e")),
      );
    }

    setState(() => generatingPdf = false);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Weekly Timetable PDF"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: depStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

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
                  setState(() => selectedSemester = v);

                  if (selectedDepartment != null) {
                    await loadSections();
                  }
                },
              ),

              if (loadingSections)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(),
                ),

              if (!loadingSections && selectedDepartment != null)
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

              if (!loadingSections &&
                  selectedDepartment != null &&
                  sectionList.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "No Sections Found for selected Department & Semester",
                    style: TextStyle(fontSize: 12),
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: generatingPdf ? null : generatePdf,
                  child: generatingPdf
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Generate PDF"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
