import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddLectureScreen extends StatefulWidget {
  const AddLectureScreen({super.key});

  @override
  State<AddLectureScreen> createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends State<AddLectureScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<int> semesters = [1,2,3,4,5,6,7,8];

  final List<String> days = ["MON","TUE","WED","THU","FRI","SAT"];

  final List<String> timeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-01:00",
    "02:00-03:00",
    "03:00-04:00",
  ];

  /// GROUP SUPPORT
  final List<String> groups = ["ALL","G1","G2"];

  String? selectedDepartment;
  int selectedSemester = 1;
  String? selectedSection;
  String? selectedSubjectId;
  String? selectedTeacherId;
  String? selectedVenueId;
  String? selectedDay;
  String? selectedTimeSlot;
  String? selectedGroup = "ALL";

  bool saving = false;

  List<Map<String,dynamic>> deptList = [];
  List<Map<String,dynamic>> sectionList = [];
  List<Map<String,dynamic>> subjectList = [];
  List<Map<String,dynamic>> teacherList = [];
  List<Map<String,dynamic>> venueList = [];

  @override
  void initState(){
    super.initState();
    loadDepartments();
    loadTeachers();
    loadVenues();
  }

  /// ======================
  /// LOAD DATA
  /// ======================

  Future<void> loadDepartments() async{
    final snap = await _db.collection("departments").orderBy("code").get();

    setState(() {
      deptList = snap.docs
          .map((d)=>{"id":d.id,...d.data()})
          .toList();
    });
  }

  Future<void> loadTeachers() async{
    final snap = await _db.collection("teachers").get();

    setState(() {
      teacherList = snap.docs
          .map((d)=>{"id":d.id,...d.data()})
          .toList();
    });
  }

  Future<void> loadVenues() async{
    final snap = await _db.collection("classrooms").orderBy("id").get();

    setState(() {
      venueList = snap.docs
          .map((d)=>{"id":d.id,...d.data()})
          .toList();
    });
  }

  Future<void> loadSections() async{

    if(selectedDepartment==null) return;

    final snap = await _db
        .collection("sections")
        .where("department",isEqualTo:selectedDepartment)
        .where("semester",isEqualTo:selectedSemester)
        .get();

    setState(() {
      sectionList = snap.docs
          .map((d)=>{"id":d.id,...d.data()})
          .toList();
    });
  }

  Future<void> loadSubjects() async{

    if(selectedDepartment==null) return;

    final snap = await _db
        .collection("subjects")
        .where("department",isEqualTo:selectedDepartment)
        .where("semester",isEqualTo:selectedSemester)
        .get();

    setState(() {
      subjectList = snap.docs
          .map((d)=>{"id":d.id,...d.data()})
          .toList();
    });
  }

  /// ======================
  /// CONFLICT CHECK
  /// ======================

  Future<void> addLecture(Map<String,dynamic> lectureData) async{

    final String day = lectureData["day"].toString();
    final String time = lectureData["time"].toString();
    final String venueId = lectureData["venueId"].toString();
    final String teacherId = lectureData["teacherId"].toString();

    /// ======================
    /// 1️⃣ VENUE CONFLICT CHECK
    /// ======================

    final conflict = await _db
        .collection("timetable")
        .where("day",isEqualTo:day)
        .where("time",isEqualTo:time)
        .where("venueId",isEqualTo:venueId)
        .limit(1)
        .get();

    if(conflict.docs.isNotEmpty){
      throw "❌ Venue already booked for this time slot";
    }

    /// ======================
    /// 2️⃣ MAX 3 LECTURE PER DAY CHECK
    /// ======================

    final teacherDaySnap = await _db
        .collection("timetable")
        .where("teacherId",isEqualTo:teacherId)
        .where("day",isEqualTo:day)
        .get();

    if(teacherDaySnap.docs.length >= 3){
      throw "❌ Teacher already has 3 lectures on $day";
    }

    /// ======================
    /// 3️⃣ NO CONSECUTIVE LECTURE CHECK
    /// ======================

    final int currentIndex = timeSlots.indexOf(time);

    for(var doc in teacherDaySnap.docs){

      final existingTime = doc["time"].toString();
      final existingIndex = timeSlots.indexOf(existingTime);

      if((existingIndex - currentIndex).abs() == 1){
        throw "❌ Teacher cannot have consecutive lectures on $day";
      }
    }

    await _db.collection("timetable").add(lectureData);
  }

  /// ======================
  /// SAVE LECTURE
  /// ======================

  Future<void> saveLecture() async{

    if(selectedDepartment==null ||
        selectedSection==null ||
        selectedSubjectId==null ||
        selectedTeacherId==null ||
        selectedVenueId==null ||
        selectedDay==null ||
        selectedTimeSlot==null){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text("Please select all fields")),
      );

      return;
    }

    if(saving) return;

    setState(()=>saving=true);

    try{

      final lectureData = {

        "department":selectedDepartment,
        "semester":selectedSemester,
        "section":selectedSection,

        "subjectId":selectedSubjectId,
        "teacherId":selectedTeacherId,
        "venueId":selectedVenueId,

        "day":selectedDay,
        "time":selectedTimeSlot,

        "group":selectedGroup ?? "ALL",

        "createdAt":FieldValue.serverTimestamp(),
      };

      await addLecture(lectureData);

      setState(() {

        selectedSection=null;
        selectedSubjectId=null;
        selectedTeacherId=null;
        selectedVenueId=null;
        selectedDay=null;
        selectedTimeSlot=null;
        selectedGroup="ALL";

        saving=false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text("✅ Lecture saved successfully")),
      );

    }
    catch(e){

      setState(()=>saving=false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString())),
      );
    }
  }

  /// ======================
  /// DROPDOWN WIDGET
  /// ======================

  Widget drop<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }){
    return Padding(
      padding:const EdgeInsets.symmetric(vertical:8),
      child:DropdownButtonFormField<T>(
        value:value,
        items:items,
        onChanged:onChanged,
        decoration:InputDecoration(
          labelText:label,
          border:OutlineInputBorder(
            borderRadius:BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// ======================
  /// UI
  /// ======================

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar:AppBar(
        title:const Text("Add Lecture / Timetable"),
      ),

      body:Padding(

        padding:const EdgeInsets.all(16),

        child:SingleChildScrollView(

          child:Column(

            children:[

              /// Department
              drop<String>(
                label:"Department",
                value:selectedDepartment,
                items:deptList.map((d){

                  final code=(d["code"]??d["id"]).toString();
                  final name=(d["name"]??"").toString();

                  return DropdownMenuItem<String>(
                    value:code,
                    child:Text("$code - $name"),
                  );

                }).toList(),

                onChanged:(v) async{

                  setState((){

                    selectedDepartment=v;
                    selectedSection=null;
                    selectedSubjectId=null;

                    sectionList.clear();
                    subjectList.clear();
                  });

                  await loadSections();
                  await loadSubjects();
                },
              ),

              /// Semester
              drop<int>(
                label:"Semester",
                value:selectedSemester,
                items:semesters.map((s)=>DropdownMenuItem<int>(
                  value:s,
                  child:Text("Semester $s"),
                )).toList(),
                onChanged:(v) async{

                  if(v==null)return;

                  setState(()=>selectedSemester=v);

                  await loadSections();
                  await loadSubjects();
                },
              ),

              /// Section
              drop<String>(
                label:"Section",
                value:selectedSection,
                items:sectionList.map((s){

                  final section=(s["section"]??"").toString();

                  return DropdownMenuItem<String>(
                    value:section,
                    child:Text(section),
                  );

                }).toList(),

                onChanged:(v)=>setState(()=>selectedSection=v),
              ),

              /// Subject
              drop<String>(
                label:"Subject",
                value:selectedSubjectId,
                items:subjectList.map((s){

                  final id=(s["id"]??"").toString();
                  final name=(s["name"]??"").toString();

                  return DropdownMenuItem<String>(
                    value:id,
                    child:Text(name),
                  );

                }).toList(),

                onChanged:(v)=>setState(()=>selectedSubjectId=v),
              ),

              /// Teacher
              drop<String>(
                label:"Teacher",
                value:selectedTeacherId,
                items:teacherList.map((t){

                  final id=(t["id"]??"").toString();
                  final name=(t["name"]??"").toString();

                  return DropdownMenuItem<String>(
                    value:id,
                    child:Text(name),
                  );

                }).toList(),

                onChanged:(v)=>setState(()=>selectedTeacherId=v),
              ),

              /// Venue
              drop<String>(
                label:"Venue",
                value:selectedVenueId,
                items:venueList.map((v){

                  final id=(v["id"]??"").toString();
                  final name=(v["name"]??"").toString();

                  return DropdownMenuItem<String>(
                    value:id,
                    child:Text("$id - $name"),
                  );

                }).toList(),

                onChanged:(v)=>setState(()=>selectedVenueId=v),
              ),

              /// Day
              drop<String>(
                label:"Day",
                value:selectedDay,
                items:days.map((d)=>DropdownMenuItem<String>(
                  value:d,
                  child:Text(d),
                )).toList(),
                onChanged:(v)=>setState(()=>selectedDay=v),
              ),

              /// Time
              drop<String>(
                label:"Time Slot",
                value:selectedTimeSlot,
                items:timeSlots.map((t)=>DropdownMenuItem<String>(
                  value:t,
                  child:Text(t),
                )).toList(),
                onChanged:(v)=>setState(()=>selectedTimeSlot=v),
              ),

              /// Group
              drop<String>(
                label:"Group",
                value:selectedGroup,
                items:groups.map((g)=>DropdownMenuItem<String>(
                  value:g,
                  child:Text(g),
                )).toList(),
                onChanged:(v)=>setState(()=>selectedGroup=v),
              ),

              const SizedBox(height:20),

              SizedBox(
                width:double.infinity,
                height:50,
                child:ElevatedButton(
                  onPressed:saving?null:saveLecture,
                  child:saving
                      ?const CircularProgressIndicator()
                      :const Text("Save Lecture"),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}