import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/qr_modal.dart';
import '../theme/app_theme.dart';

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
    String title = 'SIN EVENTOS ACTIVOS';
    String days = '...';

    if (_activeEvent != null) {
      subtitle = _activeEvent!['subtitle']?.toString().toUpperCase() ?? '';
      if (subtitle.isNotEmpty) subtitle += ' // ACTIVO';
      title = _activeEvent!['title']?.toString() ?? 'EVENTO';
      days = _activeEvent!['days_text']?.toString() ?? '';
    }

    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text(
          'CAMIM', 
          style: AppTheme.displayFont(color: Colors.white, fontSize: 24)
        ),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.camimRed,
        backgroundColor: AppTheme.camimAsh,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER PERSONALIZADO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('◆ ${_formatName(_userName ?? 'PILOTO').toUpperCase()}', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 13).copyWith(letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text('SISTEMA ONLINE', style: AppTheme.subheadFont(color: Colors.white54, fontSize: 16)),
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
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.camimAsh,
                            border: Border.all(color: Colors.white12, width: 2),
                            image: _photoUrl != null ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover) : null,
                          ),
                          child: _photoUrl == null ? const Icon(Icons.person, color: Colors.white30) : null,
                        ),
                        if (!_isOrganizer)
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: AppTheme.camimRed,
                            child: const Icon(Icons.edit, size: 10, color: Colors.white),
                          )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // STATS CARDS (Piloto)
              if (_userRankings.isNotEmpty && !_isOrganizer)
                ..._userRankings.map((rk) => InkWell(
                  onTap: () => context.push('/ranking'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.camimAsh,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('CATEGORÍA', rk['category']),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _buildStatItem('POSICIÓN', 'P${rk['position']}', highlight: true),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _buildStatItem('PUNTOS', '${rk['points']}'),
                      ],
                    ),
                  ),
                )).toList(),

              if (_userRankings.isNotEmpty && !_isOrganizer) const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PRÓXIMA FECHA', style: AppTheme.subheadFont(color: Colors.white, fontSize: 20)),
                  InkWell(
                    onTap: () => context.push('/birthday_calendar'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: AppTheme.camimRed),
                          const SizedBox(width: 6),
                          Text('CALENDARIO', style: AppTheme.dataFont(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.camimRed)))
              else
                InkWell(
                  onTap: () async {
                    await context.push('/calendar_detail');
                    _loadData(); // actualiza por si admin edita
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.camimAsh,
                      border: const Border(left: BorderSide(color: AppTheme.camimRed, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle, style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10).copyWith(letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text(title.toUpperCase(), style: AppTheme.displayFont(color: Colors.white, fontSize: 26).copyWith(height: 1)),
                        const SizedBox(height: 12),
                        if (_activeEvent != null && _activeEvent!['date_start'] != null)
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white54, size: 14),
                              const SizedBox(width: 8),
                              CountdownWidget(
                                targetDate: DateTime.tryParse(_activeEvent!['date_start']!),
                                style: AppTheme.dataFont(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              if (_isOrganizer) ...[
                Text('PRECIOS REFERENCIA PÚBLICO', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppTheme.camimAsh, border: Border.all(color: Colors.white12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [const Icon(Icons.confirmation_num, color: Colors.white54, size: 20), const SizedBox(width: 12), Text('ENTRADA GENERAL', style: AppTheme.dataFont(color: Colors.white))]),
                          Text('\$3.000', style: AppTheme.dataFont(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 30, color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [const Icon(Icons.directions_car, color: Colors.white54, size: 20), const SizedBox(width: 12), Text('ESTACIONAMIENTO', style: AppTheme.dataFont(color: Colors.white))]),
                          Text('\$1.000', style: AppTheme.dataFont(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (!_isOrganizer) ...[
                // INVITACIÓN A INSCRIPCIÓN (Novedades)
                InkWell(
                  onTap: () => context.push('/pre_inscription'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.camimRed,
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: Row(
                      children: [
                         const Icon(Icons.app_registration, color: Colors.white, size: 32),
                         const SizedBox(width: 20),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('INSCRIPCIONES', style: AppTheme.dataFont(color: Colors.white70, fontSize: 10).copyWith(letterSpacing: 2)),
                               Text('PRE-INSCRIPCIÓN\nABIERTA', style: AppTheme.displayFont(color: Colors.white, fontSize: 20).copyWith(height: 1.1)),
                             ],
                           )
                         ),
                         const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text('INFORMACIÓN ÚTIL', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                
                // Reemplazamos los rectángulos enormes por barras horizontales fluidas
                Column(
                  children: [
                    _SleekTile(icon: Icons.article_outlined, title: 'REGLAMENTOS OFICIALES', onTap: () => context.push('/regulations')),
                    _SleekTile(icon: Icons.attach_money, title: 'COSTOS DE INSCRIPCIÓN', onTap: () => context.push('/costs')),
                    _SleekTile(icon: Icons.history, title: 'FECHAS Y RESULTADOS', onTap: () => context.push('/dates_history')),
                    _SleekTile(icon: Icons.live_tv, title: 'TIEMPOS EN VIVO', highlight: true, onTap: () => context.push('/live_event')),
                    const SizedBox(height: 16),
                    _SleekTile(icon: Icons.emoji_events, title: 'RANKINGS GENERALES', isGold: true, onTap: () => context.push('/ranking')),
                  ],
                ),
              ],

              if (_upcomingBirthdays.isNotEmpty) ...[
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CUMPLEAÑOS DEL MES', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingBirthdays.length,
                    itemBuilder: (context, index) {
                      final pilot = _upcomingBirthdays[index];
                      final isToday = pilot['isToday'] == true;
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isToday ? AppTheme.camimRed.withOpacity(0.1) : AppTheme.camimAsh,
                          border: Border.all(color: isToday ? AppTheme.camimRed : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                image: pilot['photo_url'] != null ? DecorationImage(image: NetworkImage(pilot['photo_url']), fit: BoxFit.cover) : null,
                              ),
                              child: pilot['photo_url'] == null ? const Icon(Icons.person, color: Colors.white30, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pilot['first_name'].toString().toUpperCase(), style: AppTheme.dataFont(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(isToday ? '¡HOY! 🎉' : 'DÍA ${pilot['day']}', style: AppTheme.dataFont(color: isToday ? AppTheme.camimRed : Colors.white54, fontSize: 10)),
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
                const SizedBox(height: 40),
                Text('PANEL ADMINISTRADOR', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                Column(
                 children: [
                   _AdminSleekTile(icon: Icons.people_alt, title: 'GESTIÓN DE PILOTOS', onTap: () => context.push('/admin_pilots')),
                   _AdminSleekTile(icon: Icons.calendar_today, title: 'GESTIÓN DE FECHAS', onTap: () => context.push('/admin_dates_list')),
                   _AdminSleekTile(icon: Icons.videocam, title: 'CONTROL EN VIVO', onTap: () => context.push('/admin_live_event')),
                   _AdminSleekTile(icon: Icons.notifications_active, title: 'NOTIFICACIONES PUSH', onTap: () => context.push('/admin_notifications'), showBadge: _hasNewNotifications),
                 ],
                ),
              ],
              
              const SizedBox(height: 80), // Margen para el botón flotante
            ],
          ),
        )
      )
    );
  }

  Widget _buildStatItem(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.displayFont(color: highlight ? AppTheme.camimRed : Colors.white, fontSize: 22).copyWith(height: 1)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes un código QR asignado.'), backgroundColor: AppTheme.camimRed));
      return;
    }
    showQRModal(context, _qrCode!);
  }
}

// Reemplazo visual de _ActionCard para los menús
class _SleekTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool highlight;
  final bool isGold;

  const _SleekTile({required this.icon, required this.title, required this.onTap, this.highlight = false, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    Color baseColor = isGold ? const Color(0xFFD4AF37) : (highlight ? AppTheme.camimRed : Colors.white70);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.camimAsh,
          border: Border.all(color: isGold ? baseColor.withOpacity(0.3) : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: baseColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: AppTheme.dataFont(color: highlight || isGold ? Colors.white : Colors.white70, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}

class _AdminSleekTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBadge;

  const _AdminSleekTile({required this.icon, required this.title, required this.onTap, this.showBadge = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white54, size: 24),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.camimRed, shape: BoxShape.circle)),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
