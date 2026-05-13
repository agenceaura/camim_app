import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: AppTheme.camimRed));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSpeedhive(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace'), backgroundColor: AppTheme.camimRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ RESULTADOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
          : RefreshIndicator(
              color: AppTheme.camimRed,
              backgroundColor: AppTheme.camimAsh,
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final bool isActive = event['is_active'] == true;
                  final String subtitle = event['subtitle']?.toString() ?? '';
                  final String title = event['title']?.toString() ?? 'SIN TÍTULO';
                  final String speedhive = event['speedhive_link']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.camimAsh,
                      border: Border.all(color: isActive ? AppTheme.camimRed : Colors.white12, width: isActive ? 2 : 1),
                    ),
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
                                  color: isActive ? AppTheme.camimRed : Colors.white10,
                                  child: Text(subtitle.toUpperCase(), style: AppTheme.dataFont(color: Colors.white, fontSize: 10)),
                                ),
                              if (isActive)
                                Text('PRÓXIMA CARRERA', style: AppTheme.dataFont(color: Colors.greenAccent, fontSize: 10))
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title.toUpperCase(), 
                            style: AppTheme.displayFont(color: Colors.white, fontSize: 22).copyWith(height: 1.1)
                          ),
                          const SizedBox(height: 12),

                          if (speedhive.trim().isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31837), // Speedhive-like red
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () => _openSpeedhive(speedhive.trim()),
                                icon: const Icon(Icons.leaderboard, color: Colors.white),
                                label: Text('RESULTADOS EN SPEEDHIVE', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ] else if (!isActive) ...[
                             const SizedBox(height: 20),
                             Center(child: Text('RESULTADOS NO DISPONIBLES', style: AppTheme.dataFont(color: Colors.white38, fontSize: 12))),
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
