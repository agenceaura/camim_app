import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'MX 2', 'Open Class', 'MX 3 (Principiantes)', 'Juniors', 
    'Master A', 'Master B', 'Mini Cross A', 'Mini Cross B',
    'Quads A', 'Quads B', 'Quads Damas', 'Quads Senior', 'Mini Quads',
    'VeloNacional 200', 'VeloNacional 250'
  ];

  Map<String, List<Map<String, dynamic>>> _rankingsByCat = {};
  Map<String, List<Map<String, dynamic>>> _filteredRankingsByCat = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRankingsForCategory(_categories[_tabController.index]);
        _searchController.clear();
      }
    });
    _loadRankingsForCategory(_categories[0]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRankingsForCategory(String category) async {
    if (_rankingsByCat.containsKey(category)) {
      setState(() => _filteredRankingsByCat[category] = _rankingsByCat[category]!);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('rankings')
          .select('*')
          .eq('category', category)
          .order('points', ascending: false);

      final List<Map<String, dynamic>> rankingsWithPhotos = data.map((r) => Map<String, dynamic>.from(r)).toList();
      final profileIds = rankingsWithPhotos
          .where((r) => r['profile_id'] != null)
          .map((r) => r['profile_id'] as String)
          .toList();

      if (profileIds.isNotEmpty) {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, photo_url')
            .inFilter('id', profileIds);
        
        final photoMap = {for (var p in profiles) p['id'] as String: p['photo_url']};
        for (var r in rankingsWithPhotos) {
          if (r['profile_id'] != null) {
            r['photo_url'] = photoMap[r['profile_id'] as String];
          }
        }
      }

      if (mounted) {
        setState(() {
          _rankingsByCat[category] = rankingsWithPhotos;
          _filteredRankingsByCat[category] = rankingsWithPhotos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterRankings(String query) {
    final currentCat = _categories[_tabController.index];
    if (query.isEmpty) {
      setState(() => _filteredRankingsByCat[currentCat] = _rankingsByCat[currentCat]!);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filteredRankingsByCat[currentCat] = _rankingsByCat[currentCat]!.where((r) {
        final name = (r['pilot_name'] ?? '').toString().toLowerCase();
        final number = (r['moto_number'] ?? '').toString().toLowerCase();
        return name.contains(q) || number.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('RANKING 2026', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterRankings,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar piloto o número...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.red,
                indicatorWeight: 3,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                tabs: _categories.map((c) => Tab(text: c.toUpperCase())).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) => _buildRankingList(cat)).toList(),
      ),
    );
  }

  Widget _buildRankingList(String category) {
    final list = _filteredRankingsByCat[category];

    if (list == null && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (list == null || list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_motorsports_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No hay datos en esta categoría' : 'No se encontraron resultados', 
              style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _rankingsByCat.remove(category);
        await _loadRankingsForCategory(category);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final pilot = list[index];
          final pos = index + 1;
          
          return _RankingRow(pos: pos, pilot: pilot);
        },
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int pos;
  final Map<String, dynamic> pilot;

  const _RankingRow({required this.pos, required this.pilot});

  @override
  Widget build(BuildContext context) {
    final isTop3 = pos <= 3;
    final lastPoints = pilot['last_points'] ?? 0;
    
    Color posColor;
    switch (pos) {
      case 1: posColor = const Color(0xFFFFD700); break;
      case 2: posColor = const Color(0xFFC0C0C0); break;
      case 3: posColor = const Color(0xFFCD7F32); break;
      default: posColor = Colors.grey[300]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicador de posición lateral
              Container(
                width: 6,
                color: isTop3 ? posColor : Colors.transparent,
              ),
              const SizedBox(width: 12),
              
              // Número de posición
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '$pos', 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 18, 
                    color: isTop3 ? Colors.black : Colors.grey[400],
                    fontStyle: FontStyle.italic
                  )
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Foto
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isTop3 ? posColor : Colors.grey[100]!, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[50],
                    backgroundImage: pilot['photo_url'] != null ? NetworkImage(pilot['photo_url']) : null,
                    child: pilot['photo_url'] == null ? Icon(Icons.person, color: Colors.grey[300], size: 24) : null,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Info del Piloto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(pilot['pilot_name'] ?? 'Piloto'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'MOTO #${pilot['moto_number'] ?? '-'}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        if (lastPoints > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              '+$lastPoints esta fecha',
                              style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Puntos Totales
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${pilot['points'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black),
                    ),
                    const Text('PTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
