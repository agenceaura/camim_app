import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _motoCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _birthdateCtrl;
  late TextEditingController _birthplaceCtrl;
  bool _isLoading = false;
  String? _role;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialProfile?['first_name'] ?? '');
    _lastCtrl = TextEditingController(text: widget.initialProfile?['last_name'] ?? '');
    _motoCtrl = TextEditingController(text: widget.initialProfile?['motorcycle_model'] ?? '');
    _numberCtrl = TextEditingController(text: widget.initialProfile?['racing_number'] ?? '');
    _birthdateCtrl = TextEditingController(text: widget.initialProfile?['birthdate'] ?? '');
    _birthplaceCtrl = TextEditingController(text: widget.initialProfile?['birthplace'] ?? '');
    _role = widget.initialProfile?['role'];
    _photoUrl = widget.initialProfile?['photo_url'];
    
    // Siempre cargar datos frescos de Supabase para evitar desfases entre pantallas
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (profile != null && mounted) {
          setState(() {
            _role = profile['role'];
            _nameCtrl.text = profile['first_name'] ?? '';
            _lastCtrl.text = profile['last_name'] ?? '';
            _motoCtrl.text = profile['motorcycle_model'] ?? '';
            _numberCtrl.text = profile['racing_number'] ?? '';
            _birthdateCtrl.text = profile['birthdate'] ?? '';
            _birthplaceCtrl.text = profile['birthplace'] ?? '';
            _photoUrl = profile['photo_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading initial profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'first_name': _nameCtrl.text.trim(),
          'last_name': _lastCtrl.text.trim(),
          'motorcycle_model': _motoCtrl.text.trim(),
          'racing_number': _numberCtrl.text.trim(),
          'birthdate': _birthdateCtrl.text.trim().isEmpty ? null : _birthdateCtrl.text.trim(),
          'birthplace': _birthplaceCtrl.text.trim().isEmpty ? null : _birthplaceCtrl.text.trim(),
          'photo_url': _photoUrl,
        }).eq('id', user.id);

        // Sincronizar nombre en la tabla de rankings si ya estaba vinculado
        await Supabase.instance.client.from('rankings').update({
          'pilot_name': '${_nameCtrl.text.trim()} ${_lastCtrl.text.trim()}'.toUpperCase()
        }).eq('profile_id', user.id);
        
        // Notificar cambio global
        final updatedData = {
          'first_name': _nameCtrl.text.trim(),
          'last_name': _lastCtrl.text.trim(),
          'motorcycle_model': _motoCtrl.text.trim(),
          'racing_number': _numberCtrl.text.trim(),
          'birthdate': _birthdateCtrl.text.trim(),
          'birthplace': _birthplaceCtrl.text.trim(),
          'photo_url': _photoUrl,
          'role': _role,
        };
        ProfileService().updateProfile(updatedData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado con éxito'), backgroundColor: Colors.green));
          context.pop(true); // Retorna true para refrescar la pantalla anterior
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      // ImagePicker maneja los permisos automáticamente en la web y móviles modernos.

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        final url = await _uploadImage(image);
        if (url != null) {
          setState(() {
            _photoUrl = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto subida con éxito'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar imagen: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(XFile xfile) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final bytes = await xfile.readAsBytes();
      final fileExt = xfile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(filePath, bytes);

      final String publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : (_isLoading ? const CircularProgressIndicator() : null),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : _pickImage,
                    )
                  )
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildTextField('Nombre', _nameCtrl),
            const SizedBox(height: 16),
            _buildTextField('Apellido', _lastCtrl),
            const SizedBox(height: 16),
            _buildTextField('Fecha de Nacimiento', _birthdateCtrl, hint: 'Ej: 15/04/1998', type: TextInputType.number, formatters: [_DateInputFormatter()]),
            const SizedBox(height: 16),
            _buildTextField('Lugar de Nacimiento', _birthplaceCtrl, hint: 'Ej: Posadas, Misiones'),
            
            if (_role == 'pilot') ...[
              const SizedBox(height: 32),
              const Align(alignment: Alignment.centerLeft, child: Text('Datos Técnicos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              const SizedBox(height: 16),
              _buildTextField('Modelo de Motocicleta / Quad', _motoCtrl, hint: 'Ej: Yamaha YZ250F'),
              const SizedBox(height: 16),
              _buildTextField('Número de Carrera', _numberCtrl, hint: 'Ej: 74', type: TextInputType.number),
            ],
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, TextInputType type = TextInputType.text, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.black, fontSize: 16), // Texto negro visible
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white, // Fondo blanco puro
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) return newValue;
    
    var buffer = StringBuffer();
    var cleanText = text.replaceAll('/', '');
    for (int i = 0; i < cleanText.length; i++) {
       buffer.write(cleanText[i]);
       if ((i == 1 || i == 3) && i != cleanText.length - 1) {
         buffer.write('/');
       }
    }
    
    var string = buffer.toString();
    if (string.length > 10) string = string.substring(0, 10);
    
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
