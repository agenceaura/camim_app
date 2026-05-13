import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AdminDatesListScreen extends StatefulWidget {
  const AdminDatesListScreen({super.key});

  @override
  State<AdminDatesListScreen> createState() => _AdminDatesListScreenState();
}

class _AdminDatesListScreenState extends State<AdminDatesListScreen> {
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final profile = await Supabase.instance.client.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (profile == null || profile['role'] != 'admin') {
        if (mounted) context.go('/');
        return;
      }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar fechas: $e'), backgroundColor: AppTheme.camimRed));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ GESTIÓN DE FECHAS', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
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
                itemCount: _events.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.camimRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () async {
                          final result = await context.push('/edit_event');
                          if (result == true) {
                            _loadEvents();
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text('CREAR NUEVA FECHA', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                      ),
                    );
                  }

                  final event = _events[index - 1];
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () async {
                        final result = await context.push('/edit_event', extra: event);
                        if (result == true) {
                          _loadEvents();
                        }
                      },
                      title: Row(
                        children: [
                          Expanded(child: Text(title.toUpperCase(), style: AppTheme.displayFont(fontSize: 18, color: Colors.white))),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Colors.greenAccent.withOpacity(0.1),
                              child: Text('ACTIVO', style: AppTheme.dataFont(color: Colors.greenAccent, fontSize: 10)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (subtitle.isNotEmpty)
                            Text(subtitle.toUpperCase(), style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)),
                          if (speedhive.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.link, size: 14, color: Colors.lightBlueAccent),
                                const SizedBox(width: 4),
                                Expanded(child: Text('TIENE LINK DE RESULTADOS', style: AppTheme.dataFont(color: Colors.lightBlueAccent, fontSize: 10))),
                              ]
                            )
                          ]
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
