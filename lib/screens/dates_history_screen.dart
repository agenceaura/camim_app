import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DatesHistoryScreen extends StatefulWidget {
  const DatesHistoryScreen({super.key});

  @override
  State<DatesHistoryScreen> createState() => _DatesHistoryScreenState();
}

class _DatesHistoryScreenState extends State<DatesHistoryScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        final List<Map<String, dynamic>> fetchedEvents = List<Map<String, dynamic>>.from(response);
        
        // Ordenamiento natural por el número en el subtítulo (ej. "FECHA 1")
        fetchedEvents.sort((a, b) {
          int getNumber(String s) {
            final match = RegExp(r'\d+').firstMatch(s);
            return match != null ? int.parse(match.group(0)!) : 999;
          }
          return getNumber(a['subtitle'] ?? '').compareTo(getNumber(b['subtitle'] ?? ''));
        });

        setState(() {
          _events = fetchedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSpeedhive(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Fechas y Resultados', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final bool isActive = event['is_active'] == true;
                  final String subtitle = event['subtitle']?.toString() ?? '';
                  final String title = event['title']?.toString() ?? 'Sin Título';
                  final String speedhive = event['speedhive_link']?.toString() ?? '';
                  final String days = event['days_text']?.toString() ?? '';
                  final String location = event['location_name']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: Colors.black12,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (subtitle.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: isActive ? Colors.red : Colors.grey[800], borderRadius: BorderRadius.circular(12)),
                                  child: Text(subtitle.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                              if (isActive)
                                const Text('PRÓXIMA CARRERA', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          const SizedBox(height: 12),
                          if (days.isNotEmpty || location.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  if (days.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month, color: Colors.grey, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(days, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                                      ],
                                    ),
                                  if (days.isNotEmpty && location.isNotEmpty) const SizedBox(height: 8),
                                  if (location.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(location, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          if (speedhive.trim().isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31837), // Speedhive-like red
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _openSpeedhive(speedhive.trim()),
                                icon: const Icon(Icons.leaderboard, color: Colors.white),
                                label: const Text('VER RESULTADOS (SPEEDHIVE)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ] else if (!isActive) ...[
                             const SizedBox(height: 20),
                             Center(child: Text('Resultados no disponibles', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic))),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
