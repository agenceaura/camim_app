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
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.circle, color: AppTheme.camimRed, size: 12),
            const SizedBox(width: 12),
            Text('EN VIVO', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
          ],
        ),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
          : _activeEvent == null
              ? Center(child: Text('NO HAY EVENTOS ACTIVOS', style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)))
              : RefreshIndicator(
                  color: AppTheme.camimRed,
                  backgroundColor: AppTheme.camimAsh,
                  onRefresh: _loadLiveContent,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      Text(
                        'ESTADO DE LAS CATEGORÍAS',
                        style: AppTheme.dataFont(fontSize: 14, color: Colors.white54).copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      if (_liveResults.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(Icons.timer_outlined, size: 48, color: Colors.white24),
                                const SizedBox(height: 12),
                                Text('ESPERANDO INICIO DE MANGAS...', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
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
        color: AppTheme.camimAsh,
        border: const Border(left: BorderSide(color: AppTheme.camimRed, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeEvent!['subtitle']?.toString().toUpperCase() ?? 'EVENTO',
            style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10).copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            _activeEvent!['title']?.toString().toUpperCase() ?? 'SIN TÍTULO',
            style: AppTheme.displayFont(color: Colors.white, fontSize: 24).copyWith(height: 1),
          ),
          const SizedBox(height: 8),
          Text(
            _activeEvent!['location_name']?.toString().toUpperCase() ?? '',
            style: AppTheme.dataFont(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> result) {
    final category = result['category'] ?? 'CATEGORÍA';
    final status = result['status'] ?? 'No iniciado';
    final m1 = result['manga_1_results'] ?? '';
    final m2 = result['manga_2_results'] ?? '';
    final total = result['total_points'] ?? '';
    final isActive = result['is_active'] == true;

    Color statusColor = Colors.white54;
    if (status == 'Manga 1' || status == 'Manga 2') statusColor = Colors.greenAccent;
    if (status == 'Finalizado') statusColor = Colors.lightBlueAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.camimAsh,
        border: Border.all(color: isActive ? AppTheme.camimRed : Colors.white12, width: isActive ? 2 : 1),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        title: Row(
          children: [
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.circle, color: AppTheme.camimRed, size: 8),
              ),
            Expanded(
              child: Text(
                category.toString().toUpperCase(),
                style: AppTheme.dataFont(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: statusColor.withOpacity(0.1),
              child: Text(
                status.toString().toUpperCase(),
                style: AppTheme.dataFont(color: statusColor, fontSize: 10),
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
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                _buildResultRow('1RA MANGA', m1),
                const SizedBox(height: 8),
                _buildResultRow('2DA MANGA', m2),
                const SizedBox(height: 8),
                _buildResultRow('PUNTOS TOTALES', total, isBold: true),
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
          child: Text(label, style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
        ),
        Expanded(
          child: Text(
            results.isEmpty ? 'SIN DATOS' : results,
            style: AppTheme.dataFont(
              fontSize: 12,
              color: results.isEmpty ? Colors.white38 : (isBold ? Colors.white : Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}
