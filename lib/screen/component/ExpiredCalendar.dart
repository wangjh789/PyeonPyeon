import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyeonpyeon/screen/component/PhotoView.dart';
import 'package:pyeonpyeon/widget/loading.dart';
import 'package:table_calendar/table_calendar.dart';

class ExpiredCalendar extends StatefulWidget {
  ExpiredCalendar(this.storeDoc);

  final DocumentSnapshot storeDoc;

  @override
  _ExpiredCalendarState createState() => _ExpiredCalendarState();
}

class _ExpiredCalendarState extends State<ExpiredCalendar>
    with TickerProviderStateMixin {
  Map<DateTime, List> _holidays = {};

  Map<DateTime, List> _events = {};
  List _selectedEvents;
  AnimationController _animationController;
  CalendarController _calendarController;

  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController dayController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    final _selectedDay = DateTime.now();
    _selectedEvents = _events[_selectedDay] ?? [];
    _calendarController = CalendarController();

    yearController.text = _selectedDay.year.toString();
    monthController.text = _selectedDay.month.toString();
    dayController.text = _selectedDay.day.toString();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();

    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    print('CALLBACK: _onDaySelected');
    setState(() {
      _selectedEvents = events;
    });
  }

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    print('CALLBACK: _onVisibleDaysChanged');
  }

  void _onCalendarCreated(
      DateTime first, DateTime last, CalendarFormat format) {
    print('CALLBACK: _onCalendarCreated');
  }

  Future<void> _deleteImage(String imgUrl) async {
    DateTime targetDate;
    _events.entries.forEach((element) {
      if (element.value.contains(imgUrl)) {
        targetDate = element.key;
      }
    });
    _selectedEvents.remove(imgUrl);
    String imgName = imgUrl.toString().split('?')[0].split("%2F")[2];
    Reference storageReference =
        _firebaseStorage.ref().child("${widget.storeDoc.id}/expired/$imgName");
    await storageReference.delete();
    await widget.storeDoc.reference
        .collection("expired")
        .doc(targetDate.toString())
        .update({
      "photoUrls": FieldValue.arrayRemove([imgUrl])
    });
  }

  Future<void> _showDelete(BuildContext context, String imageUrl) {
    setState(() {
      loading = true;
    });
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                content: Text("사진을 삭제하시겠습니까?"),
                actions: [
                  TextButton(
                    child: Text("예"),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteImage(imageUrl);
                    },
                  ),
                  TextButton(
                    child: Text("아니오"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        });
  }

  Future<void> _showPicker(context) async {
    setState(() {
      loading = true;
    });
    await ImagePicker()
        .getImage(source: ImageSource.camera, imageQuality: 10)
        .then((PickedFile image) async {
      if (image != null) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.file(
                        File(image.path),
                        height: 300,
                      ),
                      Row(
                        children: [
                          Flexible(
                              child: TextField(
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(isDense: true),
                            textAlign: TextAlign.center,
                            controller: yearController,
                          )),
                          Text(" 년 "),
                          Flexible(
                              child: TextField(
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(isDense: true),
                            textAlign: TextAlign.center,
                            controller: monthController,
                          )),
                          Text(" 월 "),
                          Flexible(
                              child: TextField(
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(isDense: true),
                            textAlign: TextAlign.center,
                            controller: dayController,
                          )),
                          Text(" 일 ")
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                              onPressed: ()  {
                                _uploadToFirebase(File(image.path));
                                Navigator.of(context).pop();
                              },
                              child: Text("저장")),
                          TextButton(
                              onPressed: ()  {
                                Navigator.of(context).pop();
                              },
                              child: Text("취소")),
                        ],
                      )
                    ],
                  ),
                );
              });
            });
      }
      setState(() {
        loading = false;
      });
    });
  }

  Future<void> _uploadToFirebase(File image) async {
    DateTime temp = DateTime.now();
    Reference storageReference = _firebaseStorage
        .ref()
        .child("${widget.storeDoc.id}/expired/${temp.millisecondsSinceEpoch}");

    // 파일 업로드
    UploadTask storageUploadTask = storageReference.putFile(image);

    // 파일 업로드 완료까지 대기
    await storageUploadTask;

    // 업로드한 사진의 URL 획득
    String downloadURL = await storageReference.getDownloadURL();
    DocumentSnapshot targetDoc = await widget.storeDoc.reference
        .collection("expired")
        .doc(parseDate().toString())
        .get();
    if (targetDoc.exists) {
      await targetDoc.reference.update({
        "photoUrls": FieldValue.arrayUnion([downloadURL])
      });
    } else {
      await targetDoc.reference.set({
        "expiredDate": Timestamp.fromDate(parseDate()),
        "photoUrls": [downloadURL]
      });
    }
  }

  DateTime parseDate() {
    return DateTime(
        int.parse(yearController.value.text),
        int.parse(monthController.value.text),
        int.parse(dayController.value.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          await _showPicker(context);
        },
      ),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              _buildTableCalendarWithBuilders(),
              const SizedBox(height: 8.0),
              Expanded(child: _buildEventList()),
            ],
          ),
          Loading().circularLoading(loading)
        ],
      ),
    );
  }

  Widget _buildTableCalendarWithBuilders() {
    return StreamBuilder(
        stream: widget.storeDoc.reference.collection("expired").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error"),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          for (QueryDocumentSnapshot doc in snapshot.data.docs) {
            _events[doc.data()['expiredDate'].toDate()] =
                doc.data()['photoUrls'];
          }
          // data to _events;
          return TableCalendar(
            locale: 'ko_KR',
            calendarController: _calendarController,
            events: _events,
            holidays: _holidays,
            initialCalendarFormat: CalendarFormat.month,
            formatAnimation: FormatAnimation.slide,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            availableGestures: AvailableGestures.all,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
              CalendarFormat.week: '',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendStyle: TextStyle().copyWith(color: Colors.blue[800]),
              holidayStyle: TextStyle().copyWith(color: Colors.blue[800]),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
            ),
            headerStyle: HeaderStyle(
              centerHeaderTitle: true,
              formatButtonVisible: false,
            ),
            builders: CalendarBuilders(
              selectedDayBuilder: (context, date, _) {
                return FadeTransition(
                  opacity:
                      Tween(begin: 0.0, end: 1.0).animate(_animationController),
                  child: Container(
                    margin: const EdgeInsets.all(4.0),
                    padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                    color: Colors.deepOrange[300],
                    width: 100,
                    height: 100,
                    child: Text(
                      '${date.day}',
                      style: TextStyle().copyWith(fontSize: 16.0),
                    ),
                  ),
                );
              },
              todayDayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                  color: Colors.amber[400],
                  width: 100,
                  height: 100,
                  child: Text(
                    '${date.day}',
                    style: TextStyle().copyWith(fontSize: 16.0),
                  ),
                );
              },
              markersBuilder: (context, date, events, holidays) {
                final children = <Widget>[];

                if (events.isNotEmpty) {
                  children.add(
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(date, events),
                    ),
                  );
                }

                if (holidays.isNotEmpty) {
                  children.add(
                    Positioned(
                      right: -2,
                      top: -2,
                      child: _buildHolidaysMarker(),
                    ),
                  );
                }

                return children;
              },
            ),
            onDaySelected: (date, events, holidays) {
              _onDaySelected(date, events, holidays);
              _animationController.forward(from: 0.0);
            },
            onVisibleDaysChanged: _onVisibleDaysChanged,
            onCalendarCreated: _onCalendarCreated,
          );
        });
  }

  Widget _buildHolidaysMarker() {
    return Icon(
      Icons.add_box,
      size: 20.0,
      color: Colors.blueGrey[800],
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: _calendarController.isSelected(date)
            ? Colors.brown[500]
            : _calendarController.isToday(date)
                ? Colors.brown[300]
                : Colors.blue[400],
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return GridView.builder(
        itemCount: _selectedEvents.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return Container(
            child: InkWell(
              onLongPress: () async {
                await _showDelete(context, _selectedEvents[index]);
                setState(() {
                  loading = false;
                });
              },
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PhotoView(_selectedEvents, index)));
              },
              child: ExtendedImage.network(
                _selectedEvents[index],
                filterQuality: FilterQuality.low,
                fit: BoxFit.cover,
                cache: true,
              ),
            ),
          );
        });
  }
}
