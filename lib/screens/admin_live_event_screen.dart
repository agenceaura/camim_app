import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Gestionar: $category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              const Text('Estado de la Carrera', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['No iniciado', 'Manga 1', 'Manga 2', 'Finalizado'].map((s) {
                  final isSel = currentStatus == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setModalState(() => currentStatus = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Categoría en Pista (Destacar)', style: TextStyle(fontWeight: FontWeight.bold)),
                value: isActive,
                onChanged: (val) => setModalState(() => isActive = val),
                activeColor: Colors.red,
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: m1Controller, 
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Resultados Manga 1 (ej. 1° Tulio, 2° Badiali)',
                  labelStyle: TextStyle(color: Colors.grey),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: m2Controller, 
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Resultados Manga 2',
                  labelStyle: TextStyle(color: Colors.grey),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController, 
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Puntos Totales / Podio',
                  labelStyle: TextStyle(color: Colors.grey),
                )
              ),
              
              const SizedBox(height: 24),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('GUARDAR ESTADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestión En Vivo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeEvent == null
              ? const Center(child: Text('Debe haber un evento activo para gestionar.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final res = _liveResults.firstWhere((r) => r['category'] == cat, orElse: () => {});
                    final bool hasData = res.containsKey('id');
                    
                    return ListTile(
                      title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      subtitle: Text(
                        hasData ? 'Estado: ${res['status']} | Activo: ${res['is_active']}' : 'Sin datos en vivo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.edit_outlined, color: Colors.black54),
                      onTap: () => _showEditSheet(cat),
                    );
                  },
                ),
    );
  }
}
