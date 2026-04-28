import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar fechas: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Gestión de Fechas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                itemCount: _events.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final result = await context.push('/edit_event');
                          if (result == true) {
                            _loadEvents();
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('CREAR NUEVA FECHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }

                  final event = _events[index - 1];
                  final bool isActive = event['is_active'] == true;
                  final String subtitle = event['subtitle']?.toString() ?? '';
                  final String title = event['title']?.toString() ?? 'Sin Título';
                  final String speedhive = event['speedhive_link']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: Colors.white,
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
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black))),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                              child: const Text('ACTIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (subtitle.isNotEmpty)
                            Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          if (speedhive.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.link, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Expanded(child: Text('Tiene link de resultados', style: TextStyle(color: Colors.blue[700], fontSize: 13))),
                              ]
                            )
                          ]
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
