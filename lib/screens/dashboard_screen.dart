import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/qr_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _activeEvent;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isOrganizer = false;
  bool _hasNewNotifications = false;
  
  // Pilot Data
  String? _userName;
  List<Map<String, dynamic>> _userRankings = [];
  String? _photoUrl;
  String? _qrCode;
  String? _role;
  List<dynamic> _upcomingBirthdays = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    ProfileService().addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService().removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar el evento activo PRIMERO para que siempre aparezca
      final events = await Supabase.instance.client.from('events').select().eq('is_active', true).limit(1);
      if (mounted && events.isNotEmpty) {
        setState(() => _activeEvent = events[0]);
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role, first_name, last_name, photo_url, qr_code_id')
            .eq('id', user.id)
            .maybeSingle();
            
        if (profile != null && mounted) {
           final role = profile['role'];
           final isAdmin = role == 'admin';
           final isOrganizer = role == 'organizer';
           final userName = profile['first_name'];
           final photoUrl = profile['photo_url'];
           final qr = profile['qr_code_id'];
           
           // Los rankings se cargan directamente si ya fueron vinculados manualmente por el admin
           List<dynamic> userRankings = await Supabase.instance.client
               .from('rankings')
               .select('id, category, points')
               .eq('profile_id', user.id);

           // Procesar TODOS los rankings y calcular posiciones
           List<Map<String, dynamic>> processedRankings = [];
           for (var r in userRankings) {
             final cat = r['category'];
             final pts = r['points'] ?? 0;
             final allCat = await Supabase.instance.client
                 .from('rankings').select('points').eq('category', cat).order('points', ascending: false);
             int p = 1;
             for (var row in allCat) {
               if ((row['points'] ?? 0) > pts) p++; else break;
             }
             processedRankings.add({'category': cat, 'points': pts, 'position': p});
           }

           if (isAdmin) {
             try {
               final last24h = DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();
               final recentNotifs = await Supabase.instance.client
                   .from('notifications')
                   .select('id')
                   .eq('target_role', 'admin')
                   .gte('created_at', last24h)
                   .limit(1);
               _hasNewNotifications = recentNotifs.isNotEmpty;
             } catch (e) {
               debugPrint('Error checking notifications: $e');
             }
           }

           if (mounted) {
             setState(() {
               _isAdmin = isAdmin;
               _isOrganizer = isOrganizer;
               _userName = userName;
               _photoUrl = photoUrl;
               _qrCode = qr;
               _role = role;
               _userRankings = processedRankings;
             });
           }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _fetchUpcomingBirthdays();
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUpcomingBirthdays() async {
    try {
      final pilots = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, birthdate, photo_url')
          .eq('role', 'pilot');

      final List<dynamic> upcoming = [];
      final now = DateTime.now();
      
      for (var pilot in pilots) {
        final birthdateStr = pilot['birthdate'];
        if (birthdateStr != null && birthdateStr.isNotEmpty) {
          final parts = birthdateStr.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            
            if (month == now.month) {
              upcoming.add({
                ...pilot,
                'isToday': day == now.day,
                'day': day,
              });
            }
          }
        }
      }
      
      upcoming.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));

      if (mounted) {
        setState(() {
          _upcomingBirthdays = upcoming;
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming birthdays: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = 'PRÓXIMAMENTE';
    String title = 'Sin eventos activos';
    String days = '...';

    if (_activeEvent != null) {
      subtitle = _activeEvent!['subtitle']?.toString().toUpperCase() ?? '';
      if (subtitle.isNotEmpty) subtitle += ' - ACTIVO';
      title = _activeEvent!['title']?.toString() ?? 'Evento';
      days = _activeEvent!['days_text']?.toString() ?? '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'CAMIM', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 18, letterSpacing: 1)
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 30),
              // HEADER PERSONALIZADO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola, ${_formatName(_userName ?? 'Piloto')} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      const Text('¡Bienvenido de nuevo!', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _isOrganizer ? null : () async {
                      final result = await context.push('/edit_profile');
                      if (result == true && mounted) {
                        _loadData();
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                        ),
                        if (!_isOrganizer)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black, 
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 2)
                            ),
                            child: const Icon(Icons.edit, size: 10, color: Colors.white),
                          )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // STATS CARDS (Unas debajo de otras si hay varias)
              if (_userRankings.isNotEmpty && !_isOrganizer)
                ..._userRankings.map((rk) => InkWell(
                  onTap: () => context.push('/ranking'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF333333)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Categoría', rk['category']),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildStatItem('Posición', '#${rk['position']}'),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildStatItem('Puntos', '${rk['points']}'),
                      ],
                    ),
                  ),
                )).toList(),

              if (_userRankings.isNotEmpty && !_isOrganizer) const SizedBox(height: 12),

              Row(
                children: [
                  const Text('Próxima Carrera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => context.push('/birthday_calendar'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('Calendario', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else
                InkWell(
                  onTap: () async {
                    await context.push('/calendar_detail');
                    _loadData(); // actualiza por si admin edita
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                          child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 12),
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                          if (_activeEvent != null && _activeEvent!['date_start'] != null)
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                                const SizedBox(width: 8),
                                CountdownWidget(
                                  targetDate: DateTime.tryParse(_activeEvent!['date_start']!),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              if (_isOrganizer) ...[
                const SizedBox(height: 24),
                const Text('Precios al Público (Referencia)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Icon(Icons.confirmation_num, color: Colors.red, size: 20), SizedBox(width: 12), Text('Entrada General:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                          Text('\$3.000', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                        ],
                      ),
                      Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Icon(Icons.directions_car, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Estacionamiento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                          Text('\$1.000', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (!_isOrganizer) ...[
                const SizedBox(height: 16),
                const Text('Información Útil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _ActionCard(icon: Icons.article_outlined, title: 'Reglamentos', color: Colors.blue, onTap: () => context.push('/regulations')),
                    _ActionCard(icon: Icons.attach_money, title: 'Costos\nInscripción', color: Colors.green, onTap: () => context.push('/costs')),
                    _ActionCard(icon: Icons.history, title: 'Fechas y\nResultados', color: Colors.orange, onTap: () => context.push('/dates_history')),
                    _ActionCard(icon: Icons.live_tv, title: 'Evento\nen Vivo', color: Colors.red, onTap: () => context.push('/live_event')),
                  ],
                ),

                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/ranking'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Text('Ver Rankings Generales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                const Text('Novedades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () => context.push('/pre_inscription'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                         Container(
                           height: 50, width: 50,
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                           child: const Icon(Icons.app_registration, color: Colors.white, size: 28),
                         ),
                         const SizedBox(width: 20),
                         const Expanded(
                           child: Text(
                             '¡INSCRIPCIONES ABIERTAS!', 
                             style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)
                           ),
                         ),
                         const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18)
                      ],
                    ),
                  ),
                ),
              ],

              if (_upcomingBirthdays.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cumpleaños del Mes 🎂', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextButton(
                      onPressed: () => context.push('/birthday_calendar'),
                      child: const Text('Ver Calendario', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingBirthdays.length,
                    itemBuilder: (context, index) {
                      final pilot = _upcomingBirthdays[index];
                      final isToday = pilot['isToday'] == true;
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.red[50] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isToday ? Colors.red[100]! : Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: pilot['photo_url'] != null ? NetworkImage(pilot['photo_url']) : null,
                              child: pilot['photo_url'] == null ? const Icon(Icons.person, size: 20) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pilot['first_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text(isToday ? '¡HOY! 🎉' : '${pilot['day']} de este mes', style: TextStyle(color: isToday ? Colors.red : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (_isAdmin) ...[
                const SizedBox(height: 36),
                const Text('Panel Administrador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 16),
                Row(
                 children: [
                   Expanded(child: _ActionCard(icon: Icons.people_alt, title: 'Pilotos', color: Colors.purple, onTap: () => context.push('/admin_pilots'), compact: true)),
                   const SizedBox(width: 8),
                   Expanded(child: _ActionCard(icon: Icons.calendar_today, title: 'Fechas', color: Colors.teal, onTap: () => context.push('/admin_dates_list'), compact: true)),
                   const SizedBox(width: 8),
                   Expanded(child: _ActionCard(icon: Icons.videocam, title: 'Vivo', color: Colors.red, onTap: () => context.push('/admin_live_event'), compact: true)),
                   const SizedBox(width: 8),
                   Expanded(child: _ActionCard(icon: Icons.notifications_active, title: 'Notif.', color: Colors.amber, onTap: () => context.push('/admin_notifications'), compact: true, showBadge: _hasNewNotifications)),
                 ],
                ),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        )
      )
    );
  }
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatName(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showQRModal() {
    if (_qrCode == null || _qrCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes un código QR asignado.')));
      return;
    }
    showQRModal(context, _qrCode!);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final MaterialColor color;
  final VoidCallback? onTap;
  final bool compact;
  final bool showBadge;

  const _ActionCard({required this.icon, required this.title, required this.color, this.onTap, this.compact = false, this.showBadge = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: compact ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: compact ? Colors.grey[900]! : Colors.grey[200]!),
          boxShadow: compact ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: compact ? Colors.white.withOpacity(0.1) : color.shade50, 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: compact ? 22 : 32),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: compact ? 11 : 13, 
                color: compact ? Colors.white : Colors.black,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
      ),
    );
  }
}
