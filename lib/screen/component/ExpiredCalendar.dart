import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyeonpyeon/screen/component/PhotoView.dart';
import 'package:table_calendar/table_calendar.dart';

class ExpiredCalendar extends StatefulWidget {
  ExpiredCalendar(this.storeDoc);

  final DocumentSnapshot storeDoc;

  @override
  _ExpiredCalendarState createState() => _ExpiredCalendarState();
}

class _ExpiredCalendarState extends State<ExpiredCalendar>
    with TickerProviderStateMixin {
  StreamController<Map<DateTime, List>> _streamController =
      StreamController<Map<DateTime, List>>.broadcast();

  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File _image;

  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController dayController = TextEditingController();

  DateTime _selectedDay;
  Map<DateTime, List> _events = {};
  List _selectedEvents;
  AnimationController _animationController;
  CalendarController _calendarController;

  final Map<DateTime, List> _holidays = {};

  bool loading = true;

  DateTime parseDate() {
    return DateTime(
        int.parse(yearController.value.text),
        int.parse(monthController.value.text),
        int.parse(dayController.value.text));
  }

  Future<void> _uploadToFirebase() async {
    DateTime temp = DateTime.now();
    Reference storageReference = _firebaseStorage
        .ref()
        .child("${widget.storeDoc.id}/expired/${temp.millisecondsSinceEpoch}");

    // 파일 업로드
    UploadTask storageUploadTask = storageReference.putFile(_image);

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

  Future<void> _showPicker(context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              if (_image == null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                        onTap: () async {
                          PickedFile image = await ImagePicker().getImage(
                              source: ImageSource.gallery, imageQuality: 10);
                          setState(() {
                            _image = File(image.path);
                          });
                        },
                        child: Text("갤러리")),
                    InkWell(
                        onTap: () async {
                          PickedFile image = await ImagePicker().getImage(
                              source: ImageSource.camera, imageQuality: 10);
                          setState(() {
                            _image = File(image.path);
                          });
                        },
                        child: Text("카메라"))
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.file(
                    _image,
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
                          onPressed: () async {
                            Navigator.of(context).pop(true);
                            await _uploadToFirebase();
                            _image = null;
                          },
                          child: Text("저장")),
                      TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(false);
                            _image = null;
                          },
                          child: Text("취소")),
                    ],
                  )
                ],
              );
            },
          ));
        }).then((value) {
      if(value == null){
        _image = null;
      }
    });
  }

  Future<void> _showDelete(context, imageUrl) async{
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text("사진을 삭제하시겠습니까?"),
            actions: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deleteImage(imageUrl);
                  },
                  child: Text("예")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("아니오"))
            ],
          );
        });
  }

  Future<void> _deleteImage(String imgUrl) async {
    _selectedEvents.remove(imgUrl);
    String imgName = imgUrl.toString().split('?')[0].split("%2F")[2];
    Reference storageReference =
        _firebaseStorage.ref().child("${widget.storeDoc.id}/expired/$imgName");
    await storageReference.delete();
    await widget.storeDoc.reference
        .collection("expired")
        .doc(DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)
            .toString())
        .update({
      "photoUrls": FieldValue.arrayRemove([imgUrl])
    });
  }

  void onChangeData(List<DocumentChange> documentChanges) {
    var isChange = false;
    documentChanges.forEach((eventChange) {
      print(eventChange.type.toString() + "===============");
      if (eventChange.type == DocumentChangeType.added) {
        _events[eventChange.doc.data()['expiredDate'].toDate()] =
            eventChange.doc.data()['photoUrls'];
        isChange = true;
      } else if (eventChange.type == DocumentChangeType.modified) {
        _events[eventChange.doc.data()['expiredDate'].toDate()] =
            eventChange.doc.data()['photoUrls'];
        isChange = true;
      } else {
        //removed
        _events[eventChange.doc.data()['expiredDate'].toDate()] = null;
        isChange = true;
      }

      // if(eventChange.doc.id == DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day).toString()){
      //   _selectedEvents = _events[DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day)];
      //   print('tt');
      // }
    });

    if (isChange) {
      _streamController.add(_events);
    }
    if (this.mounted) {
      setState(() {});
    }
  }

  void getEvents() async {
    await widget.storeDoc.reference
        .collection("expired")
        .get()
        .then((snapshot) {
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        _events[doc.data()['expiredDate'].toDate()] = doc.data()['photoUrls'];
      }
    });
    _streamController.add(_events);
    DateTime temp = DateTime.now();
    _selectedEvents = _events[DateTime(temp.year, temp.month, temp.day)];
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    widget.storeDoc.reference
        .collection("expired")
        .snapshots()
        .listen((data) => onChangeData(data.docChanges));

    getEvents();

    _selectedDay = DateTime.now();

    yearController.text = _selectedDay.year.toString();
    monthController.text = _selectedDay.month.toString();
    dayController.text = _selectedDay.day.toString();

    _selectedEvents = _events[_selectedDay] ?? [];
    _calendarController = CalendarController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  void dispose() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    _animationController.dispose();
    _calendarController.dispose();

    _streamController.close();
    super.dispose();
  }

  void _onDaySelected(DateTime day, List events, List holidays) {
    print('CALLBACK: _onDaySelected');
    setState(() {
      _selectedDay = day;
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
    return StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("에러 발생"),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text("로딩 중 ..."),
            );
          }
          if (_selectedEvents == null) {
            return Center(
              child: Text("데이터가 없습니다."),
            );
          }
          return GridView.count(
              scrollDirection: Axis.vertical,
              //스크롤 방향 조절
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              crossAxisCount: 3,
              children: List.generate(_selectedEvents.length, (index) {
                return InkWell(
                  onLongPress: () {
                    _showDelete(context, _selectedEvents[index]);
                  },
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            PhotoView(_selectedEvents, index)));
                  },
                  child: ExtendedImage.network(
                    _selectedEvents[index],
                    filterQuality: FilterQuality.low,
                    fit: BoxFit.cover,
                    cache: true,
                    //cancelToken: cancellationToken,
                  ),
                );
              }));
        });
  }

  Widget _buildHolidaysMarker() {
    return Icon(
      Icons.add_box,
      size: 20.0,
      color: Colors.blueGrey[800],
    );
  }

  Widget _buildTableCalendarWithBuilders() {
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
        outsideDaysVisible: true,
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
            opacity: Tween(begin: 0.0, end: 1.0).animate(_animationController),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await _showPicker(context);
        },
      ),
      body: loading
          ? Center(
              child: Text("로딩 중..."),
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildTableCalendarWithBuilders(),
                const SizedBox(height: 8.0),
                Expanded(child: _buildEventList()),
              ],
            ),
    );
  }
}
