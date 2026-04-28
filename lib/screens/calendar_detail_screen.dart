import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/countdown_widget.dart';

class CalendarDetailScreen extends StatefulWidget {
  const CalendarDetailScreen({super.key});

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;
  Map<String, dynamic>? _eventData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && mounted) {
           _isAdmin = profile['role'] == 'admin';
        }
      }

      final events = await Supabase.instance.client.from('events').select().eq('is_active', true).limit(1);
      if (events.isNotEmpty && mounted) {
        _eventData = events[0];
      }
    } catch (e) {
      debugPrint('Error cargando evento: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_eventData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendario')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay eventos activos programados.', style: TextStyle(fontSize: 16)),
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final result = await context.push('/edit_event');
                    if (result == true) _loadData();
                  },
                  child: const Text('Crear Evento Nuevo'),
                )
              ]
            ],
          ),
        ),
      );
    }

    final String dateTitle = _eventData!['title'] ?? 'Sin Título';
    final String dateSubtitle = _eventData!['subtitle'] ?? '';
    final String days = _eventData!['days_text'] ?? '';
    final String locationName = _eventData!['location_name'] ?? 'Ubicación no especificada';
    
    final double lat = (_eventData!['latitude'] as num?)?.toDouble() ?? -27.367083;
    final double lng = (_eventData!['longitude'] as num?)?.toDouble() ?? -55.896083;
    final LatLng locationLatLng = LatLng(lat, lng);

    List<dynamic> satSchedule = [];
    List<dynamic> sunSchedule = [];

    // Parseo inteligente de Sábado/Domingo y compatibilidad hacia atrás
    if (_eventData!['schedule'] != null) {
      if (_eventData!['schedule'] is Map) {
        final Map<String, dynamic> schedMap = _eventData!['schedule'];
        if (schedMap.containsKey('saturday') && schedMap['saturday'] is List) satSchedule = schedMap['saturday'];
        if (schedMap.containsKey('sunday') && schedMap['sunday'] is List) sunSchedule = schedMap['sunday'];
      } else if (_eventData!['schedule'] is List) {
        satSchedule = _eventData!['schedule'];
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () async {
                    final result = await context.push('/edit_event', extra: _eventData);
                    if (result == true) _loadData();
                  },
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: FlutterMap(
                key: ValueKey(locationLatLng),
                options: MapOptions(
                   initialCenter: locationLatLng,
                   initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.camim.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: locationLatLng,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateSubtitle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: Text(dateSubtitle.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    const SizedBox(height: 16),
                    Text(dateTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 16),
                    
                    if (_eventData!['date_start'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          CountdownWidget(
                            targetDate: DateTime.tryParse(_eventData!['date_start']!),
                            style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(locationName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                          try {
                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Maps')));
                          }
                        },
                        icon: const Icon(Icons.directions, color: Colors.blue),
                        label: const Text('Cómo llegar (Google Maps)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/admin_check_in_logs', extra: {
                            'eventId': _eventData!['id'].toString(),
                            'eventTitle': _eventData!['title']
                          }),
                          icon: const Icon(Icons.people, color: Colors.white),
                          label: const Text('VER LISTA DE INGRESOS', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                    
                    if (satSchedule.isNotEmpty || sunSchedule.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      const Text('Cronograma Oficial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 16),
                      
                      if (satSchedule.isNotEmpty) ...[
                        _buildDayHeader('SÁBADO', Colors.blue),
                        _buildScheduleList(satSchedule),
                        const SizedBox(height: 24),
                      ],
                      if (sunSchedule.isNotEmpty) ...[
                         _buildDayHeader('DOMINGO', Colors.red),
                        _buildScheduleList(sunSchedule),
                      ]
                    ] else ...[
                       const SizedBox(height: 32),
                       const Text('Cronograma pendiente...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(String day, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(day, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[100], height: 1),
        itemBuilder: (context, index) {
          final item = data[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
                  child: Text(item['time']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(item['event']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 15))),
              ],
            ),
          );
        },
      ),
    );
  }
}
