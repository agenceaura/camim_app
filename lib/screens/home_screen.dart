import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    ProfileService().addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService().removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        setState(() {
          _profile = data;
        });
      } else {
        setState(() => _errorMessage = "El usuario no está autenticado.");
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.pushReplacement('/login');
  }
  
  Future<void> _editProfile() async {
    final result = await context.push('/edit_profile', extra: _profile);
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppTheme.camimInk, body: Center(child: CircularProgressIndicator(color: AppTheme.camimRed)));
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.camimInk,
        appBar: AppBar(title: const Text('ERROR')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 60, color: AppTheme.camimRed),
                const SizedBox(height: 20),
                Text('Hubo un problema con tu perfil.', textAlign: TextAlign.center, style: AppTheme.bodyFont(color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? 'Cargando...',
                  style: AppTheme.dataFont(color: AppTheme.camimRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: _loadProfile, child: const Text('REINTENTAR')),
                const SizedBox(height: 10),
                TextButton(onPressed: _logout, child: Text('Cerrar sesión', style: AppTheme.dataFont(color: AppTheme.camimBlue))),
              ],
            ),
          ),
        ),
      );
    }

    final String name = '${_profile!['first_name']} ${_profile!['last_name']}';
    final String role = _profile!['role'] ?? 'spectator';
    final String qrCode = _profile!['qr_code_id'] ?? '';
    final String photoUrl = _profile!['photo_url'] ?? '';
    final String moto = _profile!['motorcycle_model'] ?? '';
    final String num = _profile!['racing_number'] ?? '';
    final String birthdate = _profile!['birthdate'] ?? '';
    final String birthplace = _profile!['birthplace'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text(
          '◆ PERFIL / ${role.toUpperCase()}', 
          style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 13).copyWith(letterSpacing: 2)
        ),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section - Foto + Nombre
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.camimAsh,
                      border: Border.all(color: Colors.white12, width: 2),
                      image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                    ),
                    child: photoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white30) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: AppTheme.displayFont(color: Colors.white, fontSize: 32).copyWith(height: 1),
                        ),
                        if (moto.isNotEmpty || num.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                if (num.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: AppTheme.camimRed,
                                    child: Text(
                                      '#$num',
                                      style: AppTheme.displayFont(color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                if (num.isNotEmpty) const SizedBox(width: 8),
                                if (moto.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      moto.toUpperCase(),
                                      style: AppTheme.subheadFont(color: Colors.white70, fontSize: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Edit button
              OutlinedButton.icon(
                onPressed: _editProfile, 
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                label: Text('EDITAR PERFIL', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const ContinuousRectangleBorder(),
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (role == 'pilot' && qrCode.isNotEmpty) ...[
                Text('◆ CÓDIGO DE INGRESO PADDOCK', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.camimAsh,
                    border: Border.all(color: Colors.white12, width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: QrImageView(
                          data: qrCode,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(qrCode, style: AppTheme.dataFont(color: Colors.white70, fontSize: 14).copyWith(letterSpacing: 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Coloca el brillo al máximo para escanear en puerta.', textAlign: TextAlign.center, style: AppTheme.bodyFont(color: Colors.white38, fontSize: 13)),
              ] 
              else if (role == 'admin') ...[
                _AdminActionCard(
                  title: 'ESCANEAR INGRESO',
                  subtitle: 'Control de paddock',
                  icon: Icons.qr_code_scanner,
                  color: AppTheme.camimRed,
                  onTap: () => context.push('/scanner'),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: Supabase.instance.client.from('events').select('id, title').eq('is_active', true).maybeSingle(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return _AdminActionCard(
                        title: 'LISTA DE INGRESOS',
                        subtitle: 'Logs de pilotos (Hoy)',
                        icon: Icons.list_alt,
                        color: AppTheme.camimAsh,
                        onTap: () => context.push('/admin_check_in_logs', extra: {
                          'eventId': snapshot.data!['id'].toString(),
                          'eventTitle': snapshot.data!['title']
                        }),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                _AdminActionCard(
                  title: 'CAMPEONATOS',
                  subtitle: 'Gestionar temporadas',
                  icon: Icons.emoji_events,
                  color: AppTheme.camimAsh,
                  onTap: () => context.push('/championships'),
                ),
                const SizedBox(height: 16),
                _AdminActionCard(
                  title: 'EN VIVO',
                  subtitle: 'Gestión de fecha actual',
                  icon: Icons.live_tv,
                  color: AppTheme.camimBlue,
                  onTap: () => context.push('/admin_live_event'),
                ),
              ] else if (role == 'spectator') ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.camimAsh,
                    border: Border.all(color: Colors.white12, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.confirmation_num_outlined, size: 48, color: AppTheme.camimRed),
                      const SizedBox(height: 16),
                      Text('ACCESO ESPECTADOR', style: AppTheme.subheadFont(color: Colors.white, fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        'Comprá tus entradas online o en puerta y seguí los tiempos en vivo desde esta app.', 
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyFont(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/guest_ticket'),
                          icon: const Icon(Icons.confirmation_num, color: Colors.white),
                          label: Text('COMPRAR ENTRADA ONLINE', style: AppTheme.dataFont(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.camimRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ),
                    ]
                  )
                )
              ],
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

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color == AppTheme.camimAsh ? AppTheme.camimAsh : color.withOpacity(0.1),
          border: Border.all(color: color == AppTheme.camimAsh ? Colors.white12 : color.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color == AppTheme.camimAsh ? Colors.white70 : color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.subheadFont(color: Colors.white, fontSize: 24)),
                  Text(subtitle, style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
