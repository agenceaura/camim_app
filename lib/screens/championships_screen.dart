import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChampionshipsScreen extends StatefulWidget {
  const ChampionshipsScreen({super.key});

  @override
  State<ChampionshipsScreen> createState() => _ChampionshipsState();
}

class _ChampionshipsState extends State<ChampionshipsScreen> {
  List<dynamic> _championships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChampionships();
  }

  Future<void> _fetchChampionships() async {
    setState(() => _isLoading = true);
    final data = await Supabase.instance.client
        .from('championships')
        .select()
        .order('date_start', ascending: false);
    setState(() {
      _championships = data;
      _isLoading = false;
    });
  }

  Future<void> _addChampionship() async {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Campeonato (Anual)'),
        content: TextField(
          controller: nameCtrl, 
          decoration: const InputDecoration(labelText: 'Nombre (ej. Misionero MX 2026)')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                try {
                  // Desactivar otros si este será activo
                  await Supabase.instance.client.from('championships').update({'is_active': false}).eq('is_active', true);
                  
                  await Supabase.instance.client.from('championships').insert({
                    'name': nameCtrl.text.trim(),
                    'date_start': DateTime.now().toLocal().toIso8601String().split('T')[0],
                    'date_end': DateTime.now().toLocal().add(const Duration(days: 365)).toIso8601String().split('T')[0],
                    'is_active': true,
                  });
                  if (mounted) Navigator.pop(ctx);
                  _fetchChampionships();
                } catch (e) {
                  debugPrint('Error creating championship: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('CONFIRMAR'),
          )
        ],
      )
    );
  }

  Future<void> _toggleActive(String id, bool currentlyActive) async {
    if (currentlyActive) return; // Ya está activo
    
    setState(() => _isLoading = true);
    try {
      // 1. Desactivar todos los que estén activos
      await Supabase.instance.client.from('championships').update({'is_active': false}).eq('is_active', true);
      // 2. Activar el seleccionado
      await Supabase.instance.client.from('championships').update({'is_active': true}).eq('id', id);
      
      _fetchChampionships(); // Recargar la lista
    } catch (e) {
      debugPrint('Error toggling championship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al activar: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Campeonatos'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addChampionship),
      ]),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _championships.isEmpty
            ? const Center(child: Text('No hay campeonatos creados.'))
            : ListView.builder(
                itemCount: _championships.length,
                itemBuilder: (context, index) {
                  final c = _championships[index];
                  final bool isActive = c['is_active'] ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Inició: ${c['date_start'].toString().substring(0, 10)}'),
                      trailing: InkWell(
                        onTap: () => _toggleActive(c['id'].toString(), isActive),
                        child: Chip(
                          label: Text(isActive ? 'ACTIVO' : 'ACTIVAR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
