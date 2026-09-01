import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/countdown_widget.dart';
import '../theme/app_theme.dart';

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
      return Scaffold(backgroundColor: AppTheme.camimInk, body: const Center(child: CircularProgressIndicator(color: AppTheme.camimRed)));
    }

    if (_eventData == null) {
      return Scaffold(
        backgroundColor: AppTheme.camimInk,
        appBar: AppBar(title: Text('CALENDARIO', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)), backgroundColor: AppTheme.camimInk, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 60, color: Colors.white38),
              const SizedBox(height: 16),
              Text('NO HAY EVENTOS ACTIVOS PROGRAMADOS.', style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)),
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final result = await context.push('/edit_event');
                    if (result == true) _loadData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.camimRed, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  child: Text('CREAR EVENTO NUEVO', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                )
              ]
            ],
          ),
        ),
      );
    }

    final String dateTitle = _eventData!['title']?.toString().toUpperCase() ?? 'SIN TÍTULO';
    final String dateSubtitle = _eventData!['subtitle']?.toString().toUpperCase() ?? '';
    final String days = _eventData!['days_text']?.toString() ?? '';
    final String locationName = _eventData!['location_name']?.toString().toUpperCase() ?? 'UBICACIÓN NO ESPECIFICADA';
    
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
      backgroundColor: AppTheme.camimInk,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: AppTheme.camimAsh, border: Border.all(color: Colors.white24)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(color: AppTheme.camimRed, border: Border.all(color: Colors.white24)),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () async {
                    final result = await context.push('/edit_event', extra: _eventData);
                    if (result == true) _loadData();
                  },
                  padding: EdgeInsets.zero,
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
                        child: const Icon(Icons.location_on, color: AppTheme.camimRed, size: 40.0),
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
                  color: AppTheme.camimInk,
                  border: Border(top: BorderSide(color: AppTheme.camimRed, width: 4)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateSubtitle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: AppTheme.camimRed,
                        child: Text(dateSubtitle, style: AppTheme.dataFont(color: Colors.white, fontSize: 10).copyWith(letterSpacing: 1)),
                      ),
                    const SizedBox(height: 16),
                    Text(dateTitle, style: AppTheme.displayFont(fontSize: 28, color: Colors.white)),
                    const SizedBox(height: 16),
                    
                    if (_eventData!['date_start'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white54, size: 20),
                          const SizedBox(width: 8),
                          CountdownWidget(
                            targetDate: DateTime.tryParse(_eventData!['date_start']!),
                            style: AppTheme.dataFont(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white54, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(locationName, style: AppTheme.dataFont(color: Colors.white, fontSize: 14))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                          try {
                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Maps', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.camimRed));
                          }
                        },
                        icon: const Icon(Icons.directions, color: Colors.lightBlueAccent),
                        label: Text('CÓMO LLEGAR (GOOGLE MAPS)', style: AppTheme.dataFont(color: Colors.lightBlueAccent, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.lightBlueAccent, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/guest_ticket'),
                        icon: const Icon(Icons.confirmation_num, color: Colors.white),
                        label: Text('COMPRAR ENTRADAS EN LÍNEA (\$8.000)', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.camimRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                          label: Text('VER LISTA DE INGRESOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ),
                    ],
                    
                    if (satSchedule.isNotEmpty || sunSchedule.isNotEmpty) ...[
                      const SizedBox(height: 36),
                      Text('CRONOGRAMA OFICIAL', style: AppTheme.subheadFont(fontSize: 20, color: Colors.white)),
                      const SizedBox(height: 16),
                      
                      if (satSchedule.isNotEmpty) ...[
                        _buildDayHeader('SÁBADO', Colors.lightBlueAccent),
                        _buildScheduleList(satSchedule),
                        const SizedBox(height: 24),
                      ],
                      if (sunSchedule.isNotEmpty) ...[
                         _buildDayHeader('DOMINGO', AppTheme.camimRed),
                        _buildScheduleList(sunSchedule),
                      ]
                    ] else ...[
                       const SizedBox(height: 32),
                       Text('CRONOGRAMA PENDIENTE...', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: color.withOpacity(0.1),
            child: Text(day, style: AppTheme.dataFont(color: color, fontSize: 12).copyWith(letterSpacing: 2)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.camimAsh,
        border: Border.all(color: Colors.white12)
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
        itemBuilder: (context, index) {
          final item = data[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  color: Colors.white10,
                  child: Text(item['time']?.toString() ?? '', style: AppTheme.dataFont(fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(item['event']?.toString().toUpperCase() ?? '', style: AppTheme.dataFont(color: Colors.white70, fontSize: 12))),
              ],
            ),
          );
        },
      ),
    );
  }
}
