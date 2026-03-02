import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTimetableGridScreen extends StatefulWidget {
  const AdminTimetableGridScreen({super.key});

  @override
  State<AdminTimetableGridScreen> createState() =>
      _AdminTimetableGridScreenState();
}

class _AdminTimetableGridScreenState extends State<AdminTimetableGridScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> days = ["MON","TUE","WED","THU","FRI","SAT"];

  final List<String> timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "02:00-03:00",
    "03:00-04:00",
  ];

  Map<String, Map<String, List<Map<String,dynamic>>>> timetable = {};

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {

    final snap = await _db.collection("timetable").get();

    Map<String, Map<String, List<Map<String,dynamic>>>> temp = {};

    for (var d in days) {
      temp[d] = {};
      for (var t in timeSlots) {
        temp[d]![t] = [];
      }
    }

    for (var doc in snap.docs) {

      final data = doc.data();

      final day = data["day"];
      final time = data["time"];

      if (temp.containsKey(day) && temp[day]!.containsKey(time)) {

        temp[day]![time]!.add(data);
      }
    }

    setState(() {
      timetable = temp;
    });
  }

  Widget buildCell(String day,String time) {

    final lectures = timetable[day]?[time] ?? [];

    if (lectures.isEmpty) {
      return const Text("-");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lectures.map((lec){

        return Container(
          margin: const EdgeInsets.only(bottom:4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "${lec["subjectId"]} (${lec["group"]})\n${lec["venueId"]}",
            style: const TextStyle(fontSize:12),
          ),
        );

      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Timetable Grid"),
      ),

      body: SingleChildScrollView(

        scrollDirection: Axis.horizontal,

        child: SingleChildScrollView(

          child: Table(

            border: TableBorder.all(),

            defaultColumnWidth: const FixedColumnWidth(120),

            children: [

              /// HEADER
              TableRow(

                children: [

                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Day/Time",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  ...timeSlots.map((t)=>Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(t,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))

                ],
              ),

              /// DATA ROWS

              ...days.map((day){

                return TableRow(

                  children: [

                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(day,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    ...timeSlots.map((time){

                      return Padding(
                        padding: const EdgeInsets.all(6),
                        child: buildCell(day,time),
                      );

                    })

                  ],
                );

              })

            ],
          ),
        ),
      ),
    );
  }
}