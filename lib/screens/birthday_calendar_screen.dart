import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';

class AppCalendarScreen extends StatefulWidget {
  const AppCalendarScreen({super.key});

  @override
  State<AppCalendarScreen> createState() => _AppCalendarScreenState();
}

class _AppCalendarScreenState extends State<AppCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<dynamic>> _birthdayData = {};
  Map<DateTime, List<dynamic>> _raceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Fetch Birthdays
      final pilots = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, birthdate, photo_url');

      final Map<String, List<dynamic>> bMap = {};
      final Map<DateTime, List<dynamic>> rMap = {};
      int birthdayCount = 0;

      // Parse Birthdays
      for (var pilot in pilots) {
        final birthdateStr = pilot['birthdate'];
        if (birthdateStr != null && birthdateStr.isNotEmpty) {
          try {
            // Manejar formatos DD/MM/YYYY o YYYY-MM-DD
            int? day, month;
            if (birthdateStr.contains('/')) {
              final parts = birthdateStr.split('/');
              if (parts.length >= 2) {
                day = int.parse(parts[0]);
                month = int.parse(parts[1]);
              }
            } else if (birthdateStr.contains('-')) {
              final parts = birthdateStr.split('-');
              if (parts.length >= 3) {
                // Asumimos YYYY-MM-DD si empieza con 4 dígitos
                if (parts[0].length == 4) {
                  month = int.parse(parts[1]);
                  day = int.parse(parts[2]);
                } else {
                  day = int.parse(parts[0]);
                  month = int.parse(parts[1]);
                }
              }
            }

            if (day != null && month != null) {
              final key = "${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
              if (bMap[key] == null) bMap[key] = [];
              bMap[key]!.add({
                ...pilot,
                'calendarType': 'birthday',
              });
              birthdayCount++;
            }
          } catch (e) {
            debugPrint('Error parsing birthday: $e');
          }
        }
      }

         // 2. Fetch Race Events
      final events = await Supabase.instance.client
          .from('events')
          .select('title, subtitle, date_start, date_end, days_text');

      // Parse Race Events
      for (var event in events) {
        final startStr = event['date_start'];
        final endStr = event['date_end'];
        
        if (startStr != null) {
          try {
            final startDate = DateTime.parse(startStr);
            final endDate = endStr != null ? DateTime.parse(endStr) : startDate;
            
            // Recorrer todos los días entre inicio y fin
            for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
              final date = startDate.add(Duration(days: i));
              final normalizedDate = DateTime(date.year, date.month, date.day);
              
              if (rMap[normalizedDate] == null) rMap[normalizedDate] = [];
              rMap[normalizedDate]!.add({
                ...event,
                'calendarType': 'race',
              });
            }
          } catch (e) {
            debugPrint('Error parsing event range: $e');
          }
        }
      }

      setState(() {
        _birthdayData = bMap;
        _raceData = rMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching calendar data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final bKey = "${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final rKey = DateTime(day.year, day.month, day.day);
    
    final matchingBirthdays = _birthdayData[bKey] ?? [];
    final matchingRaces = _raceData[rKey] ?? [];
    
    return [...matchingBirthdays, ...matchingRaces];
  }

  Future<void> _selectYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
      helpText: 'SALTAR A FECHA',
      cancelText: 'CANCELAR',
      confirmText: 'IR',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.camimRed,
              onPrimary: Colors.white,
              surface: AppTheme.camimInk,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.camimInk,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ CALENDARIO', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: Colors.white),
            onPressed: _selectYear,
            tooltip: 'Ir a fecha/año',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
        : Column(
            children: [
              if (!_isLoading && _birthdayData.isEmpty && _raceData.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'NO SE ENCONTRARON EVENTOS.', 
                    textAlign: TextAlign.center,
                    style: AppTheme.dataFont(fontSize: 12, color: Colors.white54),
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.camimAsh,
                  border: Border.all(color: Colors.white12),
                ),
                child: TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                  lastDay: DateTime.utc(DateTime.now().year + 5, 12, 31),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: const BoxDecoration(color: Colors.lightBlueAccent, shape: BoxShape.rectangle),
                    todayDecoration: BoxDecoration(color: Colors.white12, shape: BoxShape.rectangle),
                    selectedDecoration: const BoxDecoration(color: AppTheme.camimRed, shape: BoxShape.rectangle),
                    defaultTextStyle: AppTheme.dataFont(color: Colors.white), // Números en blanco
                    weekendTextStyle: AppTheme.dataFont(color: AppTheme.camimRed), // Fines de semana en rojo
                    outsideTextStyle: AppTheme.dataFont(color: Colors.white38),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: AppTheme.dataFont(color: Colors.white, fontSize: 10),
                    weekendStyle: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: AppTheme.dataFont(fontSize: 16, color: Colors.white),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: _buildDayDetails(),
              ),
            ],
          ),
    );
  }

  Widget _buildDayDetails() {
    final items = _getEventsForDay(_selectedDay!);
    
    if (items.isEmpty) {
      return Center(child: Text('NO HAY EVENTOS ESTE DÍA.', style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)));
    }
 
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isBirthday = item['calendarType'] == 'birthday';

        if (isBirthday) {
          final name = '${item['first_name']} ${item['last_name']}'.toUpperCase();
          final photo = item['photo_url'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.camimAsh,
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
                  ),
                  child: photo == null ? const Icon(Icons.person, color: Colors.white30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('¡CUMPLEAÑOS! 🎉', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Race Event
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.camimAsh,
              border: const Border(left: BorderSide(color: AppTheme.camimRed, width: 4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_score, color: Colors.white, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title']?.toString().toUpperCase() ?? 'CARRERA', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(item['subtitle']?.toString().toUpperCase() ?? '', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10)),
                      if (item['days_text'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(item['days_text'].toString().toUpperCase(), style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
