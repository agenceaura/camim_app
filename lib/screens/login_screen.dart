import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa correo y contraseña'), backgroundColor: AppTheme.camimRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.pushReplacement('/home'); 
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.contains('Invalid login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correo o contraseña incorrectos.'), backgroundColor: AppTheme.camimRed),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppTheme.camimRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: AppTheme.camimRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.camimAsh,
        title: Text('RECUPERAR CONTRASEÑA', style: AppTheme.dataFont(color: AppTheme.camimRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresa tu correo para que el administrador pueda contactarte y blanquear tu acceso.', style: AppTheme.bodyFont(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTheme.bodyFont(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'usuario@correo.com',
                hintStyle: AppTheme.bodyFont(color: Colors.white38),
                filled: true,
                fillColor: AppTheme.camimInk,
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.camimRed)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR', style: AppTheme.dataFont(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.camimRed, shape: const ContinuousRectangleBorder()),
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await Supabase.instance.client.from('notifications').insert({
                    'title': 'Solicitud de Contraseña',
                    'body': 'El usuario ${emailController.text.trim()} ha solicitado blanquear su contraseña.',
                    'type': 'alert',
                    'target_role': 'admin',
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación enviada al administrador.'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e'), backgroundColor: AppTheme.camimRed));
                  }
                }
              }
            },
            child: Text('ENVIAR SOLICITUD', style: AppTheme.dataFont(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Meta info superior (Chip style)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CAMIM · APP',
                    style: AppTheme.dataFont(color: Colors.white70, fontSize: 12).copyWith(letterSpacing: 2),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30, width: 1.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'V0.1',
                      style: AppTheme.dataFont(color: Colors.white, fontSize: 11).copyWith(letterSpacing: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              
              // Textos centrales / Hero
              Text(
                '◆ ACCESO OFICIAL',
                style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 11).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: AppTheme.displayFont(color: Colors.white, fontSize: 56).copyWith(height: 0.9),
                  children: const [
                    TextSpan(text: 'PADDOCK\n'),
                    TextSpan(text: 'VIRTUAL.', style: TextStyle(color: AppTheme.camimRed)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ingresa tus credenciales para acceder a la gestión del campeonato.',
                style: AppTheme.bodyFont(color: Colors.white70, fontSize: 16),
              ),
              // ENTRADAS TEMPORALMENTE DESACTIVADAS
              // const SizedBox(height: 40),

              // Separador visual
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('O INGRESA A TU CUENTA', style: AppTheme.dataFont(color: Colors.white38, fontSize: 9)),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 32),

              // Campo Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.bodyFont(color: Colors.white),
                cursorColor: AppTheme.camimRed,
                decoration: InputDecoration(
                  hintText: 'usuario@correo.com',
                  hintStyle: AppTheme.bodyFont(color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.camimAsh,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0), // Bordes duros
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: const BorderSide(color: AppTheme.camimRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: AppTheme.bodyFont(color: Colors.white),
                cursorColor: AppTheme.camimRed,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: AppTheme.bodyFont(color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.camimAsh,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: const BorderSide(color: AppTheme.camimRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Olvidé mi contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text('¿Olvidaste tu contraseña?', style: AppTheme.dataFont(color: Colors.white38, fontSize: 10)),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Continuar
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.camimRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const ContinuousRectangleBorder(),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('INICIAR SESIÓN', style: AppTheme.dataFont(fontSize: 14)),
              ),
              
              const SizedBox(height: 20),
              // Enlace resaltado para ir a registro
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.bodyFont(color: Colors.white70, fontSize: 14),
                      children: const [
                        TextSpan(text: '¿Aún no tienes cuenta? '),
                        TextSpan(
                          text: 'Regístrate aquí', 
                          style: TextStyle(color: AppTheme.camimRed, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              
              // Textos Legales
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTheme.dataFont(color: Colors.white38, fontSize: 10).copyWith(height: 1.5),
                  children: const [
                    TextSpan(text: 'AL INGRESAR, ACEPTAS NUESTROS\n'),
                    TextSpan(text: 'TÉRMINOS DE SERVICIO', style: TextStyle(color: Colors.white)),
                    TextSpan(text: ' Y '),
                    TextSpan(text: 'POLÍTICA DE PRIVACIDAD', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
