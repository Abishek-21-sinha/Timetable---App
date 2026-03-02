import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:time_table/utils/timetable_pdf.dart';
// import 'timetable_pdf.dart';  // tumhara existing PDF service

class StudentViewTimetableScreen extends StatefulWidget {
  const StudentViewTimetableScreen({super.key});

  @override
  State<StudentViewTimetableScreen> createState() =>
      _StudentViewTimetableScreenState();
}

class _StudentViewTimetableScreenState
    extends State<StudentViewTimetableScreen> {

  Uint8List? pdfBytes;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {

    final service = TimetablePdfService();

    final bytes = await service.generateWeeklyPdf(
      department: "MCA4TH",   // yaha profile se pass karo
      semester: 4,
      section: "A",
    );

    setState(() {
      pdfBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (pdfBytes == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Timetable"),
      ),
      body: SfPdfViewer.memory(pdfBytes!),
    );
  }
}