import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'info';
  String _targetRole = 'all';
  bool _isLoading = false;

  late TabController _tabController;
  List<dynamic> _receivedNotifications = [];
  bool _isLoadingInbox = true;

  final List<Map<String, dynamic>> _types = [
    {'id': 'info', 'label': 'Información', 'icon': Icons.info, 'color': Colors.blueAccent},
    {'id': 'news', 'label': 'Noticia', 'icon': Icons.article, 'color': Colors.greenAccent},
    {'id': 'alert', 'label': 'Alerta', 'icon': Icons.warning, 'color': AppTheme.camimRed},
    {'id': 'success', 'label': 'Resultados', 'icon': Icons.emoji_events, 'color': Colors.purpleAccent},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
       if (_tabController.index == 1) {
         _loadInbox();
       }
    });
    _checkAdmin();
    _loadInbox();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadInbox() async {
    setState(() => _isLoadingInbox = true);
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('target_role', 'admin')
          .order('created_at', ascending: false)
          .limit(50);
      
      if (mounted) {
        setState(() {
          _receivedNotifications = response;
          _isLoadingInbox = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading inbox: $e');
      if (mounted) setState(() => _isLoadingInbox = false);
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completar título y mensaje', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.camimRed),
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
          const SnackBar(content: Text('Notificación enviada con éxito', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.camimRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ NOTIFICACIONES', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.camimRed,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: AppTheme.dataFont(fontSize: 12),
          tabs: const [
            Tab(text: 'ENVIAR PUSH'),
            Tab(text: 'RECIBIDAS (INBOX)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendForm(),
          _buildInbox(),
        ],
      ),
    );
  }

  Widget _buildSendForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TÍTULO', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: AppTheme.dataFont(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'EJ: NUEVOS RESULTADOS DISPONIBLES',
              hintStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: AppTheme.camimAsh,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.camimRed)),
            ),
          ),
          const SizedBox(height: 24),
          Text('MENSAJE', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            style: AppTheme.dataFont(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ESCRIBE EL DETALLE DE LA NOTIFICACIÓN...',
              hintStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: AppTheme.camimAsh,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.camimRed)),
            ),
          ),
          const SizedBox(height: 32),
          Text('TIPO DE NOTIFICACIÓN', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _types.map((type) {
              final isSelected = _selectedType == type['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type['id']),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? type['color'].withOpacity(0.1) : AppTheme.camimAsh,
                    border: Border.all(color: isSelected ? type['color'] : Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Icon(type['icon'], color: isSelected ? type['color'] : Colors.white38),
                      const SizedBox(height: 8),
                      Text(type['id'].toUpperCase(), style: AppTheme.dataFont(fontSize: 8, color: isSelected ? type['color'] : Colors.white54)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text('ENVIAR A:', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.camimAsh,
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetRole,
                isExpanded: true,
                dropdownColor: AppTheme.camimAsh,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                onChanged: (val) => setState(() => _targetRole = val!),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('TODOS LOS USUARIOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: 'pilot', child: Text('SOLO PILOTOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: 'spectator', child: Text('SOLO ESPECTADORES', style: AppTheme.dataFont(color: Colors.white, fontSize: 12))),
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
                backgroundColor: AppTheme.camimRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('PUBLICAR NOTIFICACIÓN', style: AppTheme.dataFont(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInbox() {
    if (_isLoadingInbox) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.camimRed));
    }

    if (_receivedNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off, size: 60, color: Colors.white38),
            const SizedBox(height: 16),
            Text('NO HAY NOTIFICACIONES RECIBIDAS', style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.camimRed,
      backgroundColor: AppTheme.camimAsh,
      onRefresh: _loadInbox,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedNotifications.length,
        itemBuilder: (context, index) {
          final notif = _receivedNotifications[index];
          final type = _types.firstWhere((t) => t['id'] == notif['type'], orElse: () => _types.first);
          
          DateTime? date;
          try {
            date = DateTime.parse(notif['created_at']).toLocal();
          } catch (e) {
            date = null;
          }
          final dateStr = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.camimAsh,
              border: Border(left: BorderSide(color: type['color'], width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(type['icon'], color: type['color'], size: 16),
                        const SizedBox(width: 8),
                        Text(type['label'].toString().toUpperCase(), style: AppTheme.dataFont(color: type['color'], fontSize: 10)),
                      ],
                    ),
                    Text(dateStr, style: AppTheme.dataFont(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(notif['title']?.toString().toUpperCase() ?? '', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Text(notif['body'] ?? '', style: AppTheme.dataFont(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
