import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AdminLiveEventScreen extends StatefulWidget {
  const AdminLiveEventScreen({super.key});

  @override
  State<AdminLiveEventScreen> createState() => _AdminLiveEventScreenState();
}

class _AdminLiveEventScreenState extends State<AdminLiveEventScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeEvent;
  List<Map<String, dynamic>> _liveResults = [];

  final List<String> _categories = [
    'Mini Cross A', 'Mini Cross B', 'Juniors', 'Quads Damas', 'Master A', 'Master B', 
    'Mini Quads', 'Quads A', 'Quads B', 'VeloNacional 200', 'VeloNacional 250', 
    'MX 3 (Principiantes)', 'MX 2', 'Open Class', 'Quads Senior'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      final event = await Supabase.instance.client
          .from('events')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      if (event != null) {
        _activeEvent = event;
        final results = await Supabase.instance.client
            .from('live_results')
            .select()
            .eq('event_id', _activeEvent!['id']);
        _liveResults = List<Map<String, dynamic>>.from(results);
      }
    } catch (e) {
      debugPrint('Error loading admin live data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _upsertResult(String category, {String? status, String? m1, String? m2, String? total, bool? isActive}) async {
    if (_activeEvent == null) return;

    final existing = _liveResults.firstWhere((r) => r['category'] == category, orElse: () => {});
    
    final Map<String, dynamic> data = {
      'event_id': _activeEvent!['id'],
      'category': category,
      'status': status ?? existing['status'] ?? 'No iniciado',
      'manga_1_results': m1 ?? existing['manga_1_results'] ?? '',
      'manga_2_results': m2 ?? existing['manga_2_results'] ?? '',
      'total_points': total ?? existing['total_points'] ?? '',
      'is_active': isActive ?? existing['is_active'] ?? false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (existing.containsKey('id')) {
        await Supabase.instance.client.from('live_results').update(data).eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('live_results').insert(data);
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.camimRed));
    }
  }

  void _showEditSheet(String category) {
    final existing = _liveResults.firstWhere((r) => r['category'] == category, orElse: () => {});
    
    final TextEditingController m1Controller = TextEditingController(text: existing['manga_1_results'] ?? '');
    final TextEditingController m2Controller = TextEditingController(text: existing['manga_2_results'] ?? '');
    final TextEditingController totalController = TextEditingController(text: existing['total_points'] ?? '');
    String currentStatus = existing['status'] ?? 'No iniciado';
    bool isActive = existing['is_active'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.camimAsh,
            border: Border(top: BorderSide(color: AppTheme.camimRed, width: 4)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('GESTIONAR: ${category.toUpperCase()}', style: AppTheme.displayFont(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 20),
              
              Text('ESTADO DE LA CARRERA', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['No iniciado', 'Manga 1', 'Manga 2', 'Finalizado'].map((s) {
                  final isSel = currentStatus == s;
                  return ChoiceChip(
                    label: Text(s.toUpperCase(), style: AppTheme.dataFont(color: isSel ? Colors.white : Colors.white54, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppTheme.camimRed,
                    backgroundColor: Colors.white10,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    onSelected: (val) {
                      if (val) setModalState(() => currentStatus = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('CATEGORÍA EN PISTA (DESTACAR)', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                value: isActive,
                onChanged: (val) => setModalState(() => isActive = val),
                activeColor: AppTheme.camimRed,
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: m1Controller, 
                style: AppTheme.dataFont(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'RESULTADOS MANGA 1 (EJ. 1° TULIO, 2° BADIALI)',
                  labelStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 10),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.camimRed)),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: m2Controller, 
                style: AppTheme.dataFont(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'RESULTADOS MANGA 2',
                  labelStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 10),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.camimRed)),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController, 
                style: AppTheme.dataFont(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PUNTOS TOTALES / PODIO',
                  labelStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 10),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.camimRed)),
                )
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _upsertResult(
                    category, 
                    status: currentStatus, 
                    m1: m1Controller.text, 
                    m2: m2Controller.text, 
                    total: totalController.text,
                    isActive: isActive,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.camimRed, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
                ),
                child: Text('GUARDAR ESTADO', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ GESTIÓN EN VIVO', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
          : _activeEvent == null
              ? Center(child: Text('DEBE HABER UN EVENTO ACTIVO PARA GESTIONAR.', style: AppTheme.dataFont(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final res = _liveResults.firstWhere((r) => r['category'] == cat, orElse: () => {});
                    final bool hasData = res.containsKey('id');
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.camimAsh,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        title: Text(cat.toUpperCase(), style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            hasData ? 'ESTADO: ${res['status'].toString().toUpperCase()} | ACTIVO: ${(res['is_active'] == true ? 'SÍ' : 'NO')}' : 'SIN DATOS EN VIVO',
                            style: AppTheme.dataFont(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                        trailing: const Icon(Icons.edit_outlined, color: Colors.white54),
                        onTap: () => _showEditSheet(cat),
                      ),
                    );
                  },
                ),
    );
  }
}
