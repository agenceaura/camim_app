import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class GuestTicketScreen extends StatefulWidget {
  const GuestTicketScreen({super.key});

  @override
  State<GuestTicketScreen> createState() => _GuestTicketScreenState();
}

class _GuestTicketScreenState extends State<GuestTicketScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _showWinkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.camimInk,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.camimRed, width: 2),
        ),
        title: Text('¡PAGO EXITOSO! 🎉', style: AppTheme.displayFont(color: Colors.white, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu entrada ya fue enviada a tu correo. Buscá el código QR para presentar en el ingreso.',
              style: AppTheme.bodyFont(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.camimAsh,
              child: Column(
                children: [
                  Text(
                    '¿YA TE VAS?',
                    style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No te pierdas los puntajes, tiempos en vivo y fotos exclusivas del campeonato.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyFont(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('SALIR', style: AppTheme.dataFont(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.camimRed,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => context.go('/register'),
            child: Text('VER RANKINGS', style: AppTheme.dataFont(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa tus datos'), backgroundColor: AppTheme.camimRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulación de llamado a AstroPay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isLoading = false);
      _showWinkDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ COMPRA RÁPIDA', style: AppTheme.dataFont(color: Colors.white, fontSize: 14).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DATOS DEL\nESPECTADOR.',
              style: AppTheme.displayFont(color: Colors.white, fontSize: 40).copyWith(height: 0.9),
            ),
            const SizedBox(height: 16),
            Text(
              'Completá tus datos para recibir la entrada por Email. El QR es único y transferible.',
              style: AppTheme.bodyFont(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            
            _buildLabel('NOMBRE COMPLETO'),
            _buildField('Ej: Juan Pérez', _nameController),
            
            const SizedBox(height: 24),
            
            _buildLabel('EMAIL DE CONTACTO'),
            _buildField('usuario@correo.com', _emailController, type: TextInputType.emailAddress),
            
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.camimAsh,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL A PAGAR', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                      Text('\$ 8.000', style: AppTheme.displayFont(color: Colors.white, fontSize: 24)),
                    ],
                  ),
                  const Icon(Icons.payment, color: Colors.white38),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.camimRed,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('PAGAR CON ASTROPAY', style: AppTheme.dataFont(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: AppTheme.bodyFont(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyFont(color: Colors.white24),
        filled: true,
        fillColor: AppTheme.camimAsh,
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.camimRed, width: 2)),
      ),
    );
  }
}
