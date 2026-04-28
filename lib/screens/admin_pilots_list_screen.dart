import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPilotsListScreen extends StatefulWidget {
  const AdminPilotsListScreen({super.key});

  @override
  State<AdminPilotsListScreen> createState() => _AdminPilotsListScreenState();
}

class _AdminPilotsListScreenState extends State<AdminPilotsListScreen> {
  List<dynamic> _allPilots = [];
  List<dynamic> _filteredPilots = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPilots();
  }

  Future<void> _loadPilots() async {
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
          .from('profiles')
          .select()
          .order('first_name', ascending: true);
      
      if (mounted) {
        setState(() {
          _allPilots = data;
          _filteredPilots = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error listando pilotos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPilots(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPilots = _allPilots);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredPilots = _allPilots.where((p) {
        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.toLowerCase();
        final number = p['racing_number']?.toString().toLowerCase() ?? '';
        final role = p['role']?.toString().toLowerCase() ?? '';
        return name.contains(q) || number.contains(q) || role.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text('Gestión de Perfiles', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPilots,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o número...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredPilots.isEmpty
                ? const Center(child: Text('No hay perfiles.'))
                : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _filteredPilots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final profile = _filteredPilots[index];
                    final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
                    final num = profile['racing_number']?.toString() ?? '';
                    final role = profile['role'] ?? 'spectator';
                    final moto = profile['motorcycle_model'] ?? '';
                    final photoUrl = profile['photo_url'] ?? '';

                    return InkWell(
                      onTap: () async {
                         final refresh = await context.push('/admin_edit_pilot', extra: profile);
                         if (refresh == true) _loadPilots();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              radius: 24,
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.isEmpty ? 'Sin Nombre' : _formatName(name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  if (moto.isNotEmpty) Text(moto, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              )
                            ),
                            if (num.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                                child: Text('#$num', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                              ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: role == 'admin' ? Colors.black : (role == 'pilot' ? Colors.green[50] : Colors.grey[100]), 
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Icon(
                                role == 'admin' ? Icons.security : (role == 'pilot' ? Icons.sports_motorsports : Icons.visibility),
                                size: 16,
                                color: role == 'admin' ? Colors.white : (role == 'pilot' ? Colors.green : Colors.grey),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  String _formatName(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }
}
