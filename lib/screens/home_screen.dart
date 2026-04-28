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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 60, color: AppTheme.primaryRed),
                const SizedBox(height: 20),
                const Text('Hubo un problema con tu perfil de la base de datos.', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? 'Cargando...',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: _loadProfile, child: const Text('Reintentar de Nuevo')),
                const SizedBox(height: 10),
                TextButton(onPressed: _logout, child: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.primaryBlue))),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(role.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
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
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatName(name),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              if (moto.isNotEmpty || num.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${moto.isNotEmpty ? moto : ''} ${num.isNotEmpty ? ' | #$num' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ),
              if (birthplace.isNotEmpty || birthdate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    [if(birthplace.isNotEmpty) birthplace, if(birthdate.isNotEmpty) birthdate].join(' - '),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _editProfile, 
                  icon: const Icon(Icons.edit, color: Colors.black, size: 16),
                  label: const Text('Editar Perfil', style: TextStyle(color: Colors.black)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              if (role == 'pilot' && qrCode.isNotEmpty) ...[
                const Text('CÓDIGO DE INGRESO A PISTA:', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrCode,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(qrCode, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Coloca el brillo de tu pantalla al máximo al momento de escanearlo en la puerta.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ] 
              else if (role == 'admin') ...[
                ElevatedButton.icon(
                  onPressed: () => context.push('/scanner'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('ESCANEAR INGRESO DE PILOTO'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Buscar evento activo para ver logs
                FutureBuilder<Map<String, dynamic>?>(
                  future: Supabase.instance.client.from('events').select('id, title').eq('is_active', true).maybeSingle(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return TextButton.icon(
                        onPressed: () => context.push('/admin_check_in_logs', extra: {
                          'eventId': snapshot.data!['id'].toString(),
                          'eventTitle': snapshot.data!['title']
                        }),
                        icon: const Icon(Icons.list_alt, color: Colors.blue),
                        label: const Text('VER LISTA DE INGRESOS (HOY)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/championships'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('GESTIONAR CAMPEONATOS'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin_live_event'),
                  icon: const Icon(Icons.live_tv, color: Colors.blue),
                  label: const Text('GESTIONAR EN VIVO'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[900],
                  ),
                ),
              ] else if (role == 'spectator') ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    children: [
                      Icon(Icons.confirmation_num_outlined, size: 40, color: Colors.black),
                      SizedBox(height: 10),
                      Text('Has ingresado como Espectador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 5),
                      Text('Compra tus entradas directo en puerta, y sigue el campeonato oficial desde esta app.', textAlign: TextAlign.center),
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
