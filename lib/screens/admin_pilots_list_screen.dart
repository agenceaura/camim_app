import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        title: Text('◆ GESTIÓN DE PERFILES', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              style: AppTheme.dataFont(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'BUSCAR POR NOMBRE O NÚMERO...',
                hintStyle: AppTheme.dataFont(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppTheme.camimAsh,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
                enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.camimRed)),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
              : _filteredPilots.isEmpty
                ? Center(child: Text('NO HAY PERFILES.', style: AppTheme.dataFont(color: Colors.white54)))
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.camimAsh,
                          border: Border.all(color: Colors.white12)
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                              ),
                              child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? 'SIN NOMBRE' : name.toUpperCase(), 
                                    style: AppTheme.dataFont(color: Colors.white, fontSize: 14)
                                  ),
                                  const SizedBox(height: 4),
                                  if (moto.isNotEmpty) 
                                    Text(
                                      moto.toUpperCase(), 
                                      style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)
                                    ),
                                ],
                              )
                            ),
                            if (num.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                color: Colors.white10,
                                child: Text('#$num', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 14)),
                              ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              color: role == 'admin' ? AppTheme.camimRed : (role == 'pilot' ? Colors.greenAccent.withOpacity(0.1) : Colors.white10),
                              child: Icon(
                                role == 'admin' ? Icons.security : (role == 'pilot' ? Icons.sports_motorsports : Icons.visibility),
                                size: 16,
                                color: role == 'admin' ? Colors.white : (role == 'pilot' ? Colors.greenAccent : Colors.white54),
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
}
