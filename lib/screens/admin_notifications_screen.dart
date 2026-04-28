import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'info';
  String _targetRole = 'all';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _types = [
    {'id': 'info', 'label': 'Información', 'icon': Icons.info, 'color': Colors.blue},
    {'id': 'news', 'label': 'Noticia', 'icon': Icons.article, 'color': Colors.green},
    {'id': 'alert', 'label': 'Alerta', 'icon': Icons.warning, 'color': Colors.orange},
    {'id': 'success', 'label': 'Resultados', 'icon': Icons.emoji_events, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    final profile = await Supabase.instance.client.from('profiles').select('role').eq('id', user.id).maybeSingle();
    if (profile == null || profile['role'] != 'admin') {
      if (mounted) context.go('/');
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completar título y mensaje')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('notifications').insert({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'type': _selectedType,
        'target_role': _targetRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación enviada con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enviar Notificación', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Título', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: Nuevos Resultados Disponibles',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Mensaje', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe el detalle de la notificación...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tipo de Notificación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _types.map((type) {
                final isSelected = _selectedType == type['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['id']),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? type['color'].withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? type['color'] : Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(type['icon'], color: isSelected ? type['color'] : Colors.grey[400]),
                        const SizedBox(height: 4),
                        Text(type['id'].toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? type['color'] : Colors.grey[600], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Enviar a:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetRole,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _targetRole = val!),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos los usuarios')),
                    DropdownMenuItem(value: 'pilot', child: Text('Solo Pilotos')),
                    DropdownMenuItem(value: 'spectator', child: Text('Solo Espectadores')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PUBLICAR NOTIFICACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
