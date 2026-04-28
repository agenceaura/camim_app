import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calendario CAMIM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: Colors.blue),
            onPressed: _selectYear,
            tooltip: 'Ir a fecha/año',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (!_isLoading && _birthdayData.isEmpty && _raceData.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No se encontraron eventos o cumpleaños.\nUsa el panel de administrador para registrar fechas de carrera.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              TableCalendar(
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
                  markerDecoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Colors.red.withOpacity(0.3), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  defaultTextStyle: const TextStyle(color: Colors.black), // Números en negro
                  weekendTextStyle: const TextStyle(color: Colors.red), // Fines de semana en rojo
                  outsideTextStyle: const TextStyle(color: Colors.grey),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                ),
              ),
              const Divider(),
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
      return const Center(child: Text('No hay eventos este día.', style: TextStyle(color: Colors.grey)));
    }
 
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isBirthday = item['calendarType'] == 'birthday';

        if (isBirthday) {
          final name = '${item['first_name']} ${item['last_name']}';
          final photo = item['photo_url'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('¡Feliz Cumpleaños! 🎂', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
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
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? 'Carrera', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['subtitle'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (item['days_text'] != null)
                        Text(item['days_text'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
