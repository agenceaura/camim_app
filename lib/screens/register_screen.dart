import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;
  String _role = 'pilot'; // pilot, spectator o press

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _lastNameController.text.isEmpty || 
        _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: AppTheme.camimRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = res.user;
      
      if (user != null) {
        final uniqueQr = (_role == 'pilot' || _role == 'press') ? 'CAMIM-${user.id.substring(0, 8).toUpperCase()}' : null;
        
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'first_name': _nameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            if (uniqueQr != null) 'qr_code_id': uniqueQr,
            'role': _role,
          });
        } catch (e) {
          debugPrint('Error upsert profile: $e');
          throw 'Error al guardar tus datos de perfil. Por favor, intenta ingresar con tu mail y contraseña.';
        }

        if (mounted) {
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de Autenticación: ${e.message}'), backgroundColor: AppTheme.camimRed));
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('row-level security')) {
          msg = 'Error de Permisos: Ejecuta el script SQL de políticas INSERT en Supabase.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.camimRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('CREAR CUENTA', style: AppTheme.dataFont(color: Colors.white, fontSize: 14).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '◆ NUEVO PERFIL',
                style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 11).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                'BIENVENIDO\nA CAMIM.',
                style: AppTheme.displayFont(color: Colors.white, fontSize: 42).copyWith(height: 0.9),
              ),
              const SizedBox(height: 30),
              
              // Selector de Rol Visual
              Text('SELECCIONA TU TIPO DE ACCESO', style: AppTheme.dataFont(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      title: 'PILOTO',
                      icon: Icons.sports_motorsports,
                      isSelected: _role == 'pilot',
                      onTap: () => setState(() => _role = 'pilot'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleButton(
                      title: 'PRENSA',
                      icon: Icons.camera_alt,
                      isSelected: _role == 'press',
                      onTap: () => setState(() => _role = 'press'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleButton(
                      title: 'ESPECTADOR',
                      icon: Icons.groups,
                      isSelected: _role == 'spectator',
                      onTap: () => setState(() => _role = 'spectator'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              _buildField('Nombre', _nameController),
              const SizedBox(height: 16),
              _buildField('Apellido', _lastNameController),
              const SizedBox(height: 16),
              _buildField('Correo electrónico', _emailController, type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Contraseña', _passwordController, isPassword: true),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.camimRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const ContinuousRectangleBorder(),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('COMPLETAR REGISTRO', style: AppTheme.dataFont(fontSize: 14)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, {TextInputType type = TextInputType.text, bool isPassword = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword,
      style: AppTheme.bodyFont(color: Colors.white),
      cursorColor: AppTheme.camimRed,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyFont(color: Colors.white38),
        filled: true,
        fillColor: AppTheme.camimAsh,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.camimRed, width: 2),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.camimRed : AppTheme.camimAsh,
          border: Border.all(color: isSelected ? AppTheme.camimRed : Colors.white12, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 28),
            const SizedBox(height: 12),
            Text(
              title, 
              style: AppTheme.dataFont(color: isSelected ? Colors.white : Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
