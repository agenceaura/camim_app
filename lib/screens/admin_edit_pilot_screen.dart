import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminEditPilotScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const AdminEditPilotScreen({super.key, required this.profile});

  @override
  State<AdminEditPilotScreen> createState() => _AdminEditPilotScreenState();
}

class _AdminEditPilotScreenState extends State<AdminEditPilotScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _motoCtrl;
  late TextEditingController _numberCtrl;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.profile['first_name']?.toString() ?? '');
    _lastNameCtrl = TextEditingController(text: widget.profile['last_name']?.toString() ?? '');
    _motoCtrl = TextEditingController(text: widget.profile['motorcycle_model']?.toString() ?? '');
    _numberCtrl = TextEditingController(text: widget.profile['racing_number']?.toString() ?? '');
    _selectedRole = widget.profile['role']?.toString() ?? 'spectator';
    
    // Fallback if role is completely invalid in DB
    if (!['admin', 'pilot', 'spectator', 'organizer'].contains(_selectedRole)) {
      _selectedRole = 'spectator';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final adminProfile = await Supabase.instance.client.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (adminProfile == null || adminProfile['role'] != 'admin') {
        if (mounted) context.go('/');
        return;
      }

      final updates = {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'motorcycle_model': _motoCtrl.text.trim(),
        'racing_number': _numberCtrl.text.trim(),
        'role': _selectedRole,
      };

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', widget.profile['id']);

      // Sincronizar con la tabla de rankings si existe entrada
      await Supabase.instance.client
          .from('rankings')
          .update({
            'pilot_name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.toUpperCase()
          })
          .eq('profile_id', widget.profile['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Editar Piloto', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Datos Personales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              _buildTextField(_firstNameCtrl, 'Nombre'),
              const SizedBox(height: 12),
              _buildTextField(_lastNameCtrl, 'Apellido'),
              
              const SizedBox(height: 32),
              const Text('Datos Deportivos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              _buildTextField(_numberCtrl, 'Número de Carrera (Ej. 46)', isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_motoCtrl, 'Modelo de Moto / Quad'),
              
              const SizedBox(height: 32),
              const Text('Nivel de Acceso (Rol)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                ),
                items: const [
                  DropdownMenuItem(value: 'spectator', child: Text('Espectador (No corre)')),
                  DropdownMenuItem(value: 'pilot', child: Text('Piloto (Compite)')),
                  DropdownMenuItem(value: 'organizer', child: Text('Organizador (Escanea QR)')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador (Acceso total)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              
              const SizedBox(height: 40),
              if (widget.profile['qr_code_id'] != null && widget.profile['qr_code_id'].toString().isNotEmpty) ...[
                const Text('CÓDIGO QR DE ACCESO', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.profile['qr_code_id'].toString(),
                          version: QrVersions.auto,
                          size: 140.0,
                        ),
                        const SizedBox(height: 4),
                        Text(widget.profile['qr_code_id'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black), // Texto negro
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
      ),
    );
  }
}
