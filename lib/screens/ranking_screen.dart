import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _categories = [
    'MX 2', 'Open Class', 'MX 3 (Principiantes)', 'Juniors', 
    'Master A', 'Master B', 'Mini Cross A', 'Mini Cross B',
    'Quads A', 'Quads B', 'Quads Damas', 'Quads Senior', 'Mini Quads',
    'VeloNacional 200', 'VeloNacional 250'
  ];

  Map<String, List<Map<String, dynamic>>> _rankingsByCat = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRankingsForCategory(_categories[_tabController.index]);
      }
    });
    _loadRankingsForCategory(_categories[0]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankingsForCategory(String category) async {
    if (_rankingsByCat.containsKey(category)) return; // Evitar recargas innecesarias

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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CAMPEONATO 2026', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.grey[50], // Fondo sutil para crear contraste
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.red,
              indicatorWeight: 3,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54, // Forzado a negro traslúcido
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black54),
              tabs: _categories.map((c) => Tab(
                child: Text(c.toUpperCase(), style: const TextStyle(letterSpacing: 0.5)),
              )).toList(),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: _categories.map((cat) => _buildRankingList(cat)).toList(),
        ),
      ),
    );
  }

  Widget _buildRankingList(String category) {
    final list = _rankingsByCat[category];

    if (list == null && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (list == null || list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text('No hay datos registrados aún', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
    final colorPos = pos == 1 ? const Color(0xFFFFD700) : (pos == 2 ? const Color(0xFFC0C0C0) : (pos == 3 ? const Color(0xFFCD7F32) : Colors.grey[200]!));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // POSICIÓN
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop3 ? colorPos.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$pos', 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 15, 
                color: isTop3 ? (pos == 1 ? const Color(0xFFB8860B) : Colors.black87) : Colors.grey[400]
              )
            ),
          ),
          const SizedBox(width: 12),
          
          // FOTO
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isTop3 ? colorPos : Colors.grey[200]!, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[50],
              backgroundImage: pilot['photo_url'] != null ? NetworkImage(pilot['photo_url']) : null,
              child: pilot['photo_url'] == null ? Icon(Icons.person, color: Colors.grey[300], size: 20) : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // NOMBRE Y MOTO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatName(pilot['pilot_name'] ?? 'Piloto'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'MOTOR #${pilot['moto_number'] ?? '-'}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          
          // PUNTOS
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pilot['points'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
              ),
              const Text('PUNTOS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
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
