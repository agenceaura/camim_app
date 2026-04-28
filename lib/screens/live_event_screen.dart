import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class LiveEventScreen extends StatefulWidget {
  const LiveEventScreen({super.key});

  @override
  State<LiveEventScreen> createState() => _LiveEventScreenState();
}

class _LiveEventScreenState extends State<LiveEventScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeEvent;
  List<Map<String, dynamic>> _liveResults = [];

  @override
  void initState() {
    super.initState();
    _loadLiveContent();
  }

  Future<void> _loadLiveContent() async {
    setState(() => _isLoading = true);
    try {
      // 1. Obtener el evento activo
      final eventData = await Supabase.instance.client
          .from('events')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      if (eventData != null) {
        _activeEvent = eventData;
        // 2. Obtener resultados en vivo para este evento
        final results = await Supabase.instance.client
            .from('live_results')
            .select()
            .eq('event_id', _activeEvent!['id'])
            .order('updated_at', ascending: false);
        
        _liveResults = List<Map<String, dynamic>>.from(results);
      }
    } catch (e) {
      debugPrint('Error loading live content: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.circle, color: Colors.red, size: 12),
            SizedBox(width: 8),
            Text('Carrera en Vivo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeEvent == null
              ? const Center(child: Text('No hay eventos activos en este momento'))
              : RefreshIndicator(
                  onRefresh: _loadLiveContent,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const Text(
                        'ESTADO DE LAS CATEGORÍAS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (_liveResults.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.timer_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Esperando el inicio de las mangas...', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._liveResults.map((res) => _buildLiveCard(res)).toList(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeEvent!['subtitle']?.toString().toUpperCase() ?? 'EVENTO',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            _activeEvent!['title']?.toString() ?? 'Sin Título',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _activeEvent!['location_name']?.toString() ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> result) {
    final category = result['category'] ?? 'Categoría';
    final status = result['status'] ?? 'No iniciado';
    final m1 = result['manga_1_results'] ?? '';
    final m2 = result['manga_2_results'] ?? '';
    final total = result['total_points'] ?? '';
    final isActive = result['is_active'] == true;

    Color statusColor = Colors.grey;
    if (status == 'Manga 1' || status == 'Manga 2') statusColor = Colors.green;
    if (status == 'Finalizado') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.red.withOpacity(0.5) : Colors.grey[200]!, width: isActive ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Row(
          children: [
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.circle, color: Colors.red, size: 10),
              ),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildResultRow('1ra Manga', m1),
                const SizedBox(height: 8),
                _buildResultRow('2da Manga', m2),
                const SizedBox(height: 8),
                _buildResultRow('Puntos Totales', total, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String results, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(
            results.isEmpty ? 'Sin datos' : results,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: results.isEmpty ? Colors.grey[400] : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
