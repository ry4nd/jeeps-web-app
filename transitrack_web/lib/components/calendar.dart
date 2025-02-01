import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// Used in the Historical Data Tab

class CalendarWidget extends StatefulWidget {
  final RouteData routeData;
  final DateTime selectedDate;
  final ValueChanged<DateTime> newSelectedDate;
  const CalendarWidget(
      {super.key,
      required this.routeData,
      required this.selectedDate,
      required this.newSelectedDate});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();

    setState(() {
      _focusedDay = widget.selectedDate;
      _selectedDay = widget.selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
        firstDay: DateTime.utc(2024, 1, 20),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          widget.newSelectedDate(_selectedDay);
        },
        calendarBuilders: CalendarBuilders(
            todayBuilder: (context, day, focusedDay) => Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        size: 40,
                        color: Color(widget.routeData.routeColor),
                      ),
                      Text(
                        DateFormat('d').format(day),
                        style: TextStyle(
                          color: Color(widget.routeData.routeColor),
                        ),
                      ),
                    ],
                  ),
                ),
            selectedBuilder: (context, day, focusedDay) => Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 40,
                        color: Color(widget.routeData.routeColor),
                      ),
                      Text(
                        DateFormat('d').format(day),
                        style: const TextStyle(
                          color: Constants.bgColor,
                        ),
                      ),
                    ],
                  ),
                ),
            outsideBuilder: (context, day, focusedDay) => Center(
                  child: Text(
                    DateFormat('d').format(day),
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                ),
            disabledBuilder: (context, day, focusedDay) => Center(
                  child: Text(
                    DateFormat('d').format(day),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ),
            dowBuilder: (context, day) => Center(
                  child: Text(
                    DateFormat.E().format(day),
                    style: TextStyle(
                        color: day.weekday == DateTime.sunday ||
                                day.weekday == DateTime.saturday
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white),
                  ),
                ),
            defaultBuilder: ((context, day, focusedDay) => Center(
                  child: Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                        color: day.weekday == DateTime.sunday ||
                                day.weekday == DateTime.saturday
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white),
                  ),
                ))));
  }
}
