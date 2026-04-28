import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String _role = 'pilot'; // pilot o spectator

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _lastNameController.text.isEmpty || 
        _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.red),
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
        final uniqueQr = _role == 'pilot' ? 'CAMIM-${user.id.substring(0, 8).toUpperCase()}' : null;
        
        // 1. Crear el perfil primero (Quitamos 'email' porque no existe la columna en el DB del usuario)
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'first_name': _nameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            // 'email': _emailController.text.trim(), // Comentado para evitar error PGRST204
            if (uniqueQr != null) 'qr_code_id': uniqueQr,
            'role': _role,
          });
        } catch (e) {
          debugPrint('Error upsert profile: $e');
          throw 'Error al guardar tus datos de perfil. Por favor, intenta ingresar con tu mail y contraseña.';
        }

        // 2. Vinculación manual desde Supabase (Desactivado en app)
        if (mounted) {
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de Autenticación: ${e.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('row-level security')) {
          msg = 'Error de Permisos: Ejecuta el script SQL de políticas INSERT en Supabase.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bienvenidos a CAMIM',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 30),
              
              // Selector de Rol Visual
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _role = 'pilot'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: _role == 'pilot' ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _role == 'pilot' ? Colors.black : Colors.grey[300]!, width: 2)
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.sports_motorsports, color: _role == 'pilot' ? Colors.white : Colors.grey[600], size: 36),
                            const SizedBox(height: 12),
                            Text('Soy Piloto', style: TextStyle(color: _role == 'pilot' ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _role = 'spectator'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: _role == 'spectator' ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _role == 'spectator' ? Colors.black : Colors.grey[300]!, width: 2)
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.groups, color: _role == 'spectator' ? Colors.white : Colors.grey[600], size: 36),
                            const SizedBox(height: 12),
                            Text('Soy Espectador', style: TextStyle(color: _role == 'spectator' ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              _buildField('Nombre', _nameController),
              const SizedBox(height: 16),
              _buildField('Apellido', _lastNameController),
              const SizedBox(height: 16),
              _buildField('Correo electrónico', _emailController, type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Contraseña', _passwordController, isPassword: true),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Completar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
      ),
    );
  }
}
