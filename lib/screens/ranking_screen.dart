import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ RANKINGS', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterRankings,
                  style: AppTheme.bodyFont(color: Colors.white, fontSize: 14),
                  cursorColor: AppTheme.camimRed,
                  decoration: InputDecoration(
                    hintText: 'Buscar piloto o N° de moto...',
                    hintStyle: AppTheme.bodyFont(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                    filled: true,
                    fillColor: AppTheme.camimAsh,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white12), borderRadius: BorderRadius.zero),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.camimRed, width: 2), borderRadius: BorderRadius.zero),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.camimRed,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: AppTheme.dataFont(fontSize: 12),
                unselectedLabelStyle: AppTheme.dataFont(fontSize: 12),
                tabAlignment: TabAlignment.start,
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.camimRed));
    }

    if (list == null || list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_motorsports_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'SIN DATOS CARGADOS' : 'NO HAY RESULTADOS', 
              style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.camimRed,
      backgroundColor: AppTheme.camimAsh,
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
      case 1: posColor = const Color(0xFFD4AF37); break; // Gold
      case 2: posColor = const Color(0xFFC0C0C0); break; // Silver
      case 3: posColor = const Color(0xFFCD7F32); break; // Bronze
      default: posColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.camimAsh,
        border: Border.all(color: pos == 1 ? posColor : Colors.white12, width: pos == 1 ? 2 : 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Indicador de posición
            Container(
              width: 44,
              color: isTop3 ? posColor.withOpacity(0.1) : Colors.transparent,
              alignment: Alignment.center,
              child: Text(
                'P$pos', 
                style: AppTheme.dataFont(
                  fontSize: 16, 
                  color: isTop3 ? posColor : Colors.white54,
                )
              ),
            ),
            
            Container(width: 1, color: isTop3 ? posColor.withOpacity(0.3) : Colors.white12),
            
            // Foto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.camimInk,
                  border: Border.all(color: isTop3 ? posColor : Colors.white12),
                  image: pilot['photo_url'] != null ? DecorationImage(image: NetworkImage(pilot['photo_url']), fit: BoxFit.cover) : null,
                ),
                child: pilot['photo_url'] == null ? const Icon(Icons.person, color: Colors.white24, size: 20) : null,
              ),
            ),
            
            // Info del Piloto
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (pilot['pilot_name'] ?? 'PILOTO').toString().toUpperCase(),
                    style: AppTheme.displayFont(fontSize: 18, color: Colors.white).copyWith(height: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.white10,
                        child: Text(
                          '#${pilot['moto_number'] ?? '-'}',
                          style: AppTheme.dataFont(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      if (lastPoints > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+$lastPoints PTS',
                          style: AppTheme.dataFont(color: Colors.greenAccent, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Puntos Totales
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: AppTheme.camimInk,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${pilot['points'] ?? 0}',
                    style: AppTheme.dataFont(fontSize: 20, color: AppTheme.camimRed),
                  ),
                  Text('TOTAL', style: AppTheme.dataFont(fontSize: 9, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
