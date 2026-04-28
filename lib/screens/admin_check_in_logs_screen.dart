import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminCheckInLogsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const AdminCheckInLogsScreen({
    super.key, 
    required this.eventId, 
    required this.eventTitle
  });

  @override
  State<AdminCheckInLogsScreen> createState() => _AdminCheckInLogsScreenState();
}

class _AdminCheckInLogsScreenState extends State<AdminCheckInLogsScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
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

      final data = await Supabase.instance.client
          .from('check_ins')
          .select('*, profiles(first_name, last_name, photo_url, racing_number, motorcycle_model)')
          .eq('event_id', widget.eventId)
          .order('check_in_at', ascending: false);

      setState(() => _logs = data);
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresos a Pista'),
            Text(widget.eventTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text('No hay ingresos registrados para esta fecha.', 
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                )
              : ListView.separated(
                  itemCount: _logs.length,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final profile = log['profiles'];
                    final DateTime time = DateTime.parse(log['check_in_at']).toLocal();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile['photo_url'] != null
                            ? NetworkImage(profile['photo_url'])
                            : null,
                        child: profile['photo_url'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(
                        '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${profile['motorcycle_model'] ?? 'Moto'} | #${profile['racing_number'] ?? 'N/A'}'),
                          Text(
                            DateFormat('dd/MM HH:mm').format(time),
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    );
                  },
                ),
    );
  }
}
