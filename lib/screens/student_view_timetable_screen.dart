import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:time_table/utils/timetable_pdf.dart';

class StudentViewTimetableScreen extends StatefulWidget {
  const StudentViewTimetableScreen({super.key});

  @override
  State<StudentViewTimetableScreen> createState() =>
      _StudentViewTimetableScreenState();
}

class _StudentViewTimetableScreenState
    extends State<StudentViewTimetableScreen> {

  Uint8List? pdfBytes;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final service = TimetablePdfService();

      final bytes = await service.generateWeeklyPdf(
        department: "MCA4TH",
        semester: 4,
        section: "A",
      );

      setState(() {
        pdfBytes = bytes;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      debugPrint("PDF Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Weekly Timetable"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pdfBytes == null
          ? const Center(child: Text("Failed to load timetable"))
          : SfPdfViewer.memory(
        pdfBytes!,
        pageLayoutMode: PdfPageLayoutMode.single,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}