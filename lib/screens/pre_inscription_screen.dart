import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Añadido para copiar al portapapeles
import '../widgets/countdown_widget.dart';

class PreInscriptionScreen extends StatefulWidget {
  const PreInscriptionScreen({super.key});

  @override
  State<PreInscriptionScreen> createState() => _PreInscriptionScreenState();
}

class _PreInscriptionScreenState extends State<PreInscriptionScreen> {
  bool _isLoading = true;
  final Set<String> _selectedCategories = {};
  Map<String, dynamic>? _activeEvent;
  Map<String, dynamic>? _pilotProfile;
  
  bool _isBonificado = false;
  
  final Map<String, Map<String, String>> _categoryPrices = {
    'Mini Cross A': {'bonus': '\$100.000', 'general': '\$120.000'},
    'Mini Cross B': {'bonus': '\$100.000', 'general': '\$120.000'},
    'Mini Quads': {'bonus': '\$100.000', 'general': '\$120.000'},
    'Quads Damas': {'bonus': '\$180.000', 'general': '\$200.000'},
    'Quads A': {'bonus': '\$180.000', 'general': '\$200.000'},
    'Quads B': {'bonus': '\$180.000', 'general': '\$200.000'},
    'Quads Senior': {'bonus': '\$180.000', 'general': '\$200.000'},
    'Juniors': {'bonus': '\$170.000', 'general': '\$190.000'},
    'Master A': {'bonus': '\$170.000', 'general': '\$190.000'},
    'Master B': {'bonus': '\$170.000', 'general': '\$190.000'},
    'MX 3 (Principiantes)': {'bonus': '\$170.000', 'general': '\$190.000'},
    'MX 2': {'bonus': '\$170.000', 'general': '\$190.000'},
    'Open Class': {'bonus': '\$170.000', 'general': '\$190.000'},
    'VeloNacional 200': {'bonus': '\$130.000', 'general': '\$150.000'},
    'VeloNacional 250': {'bonus': '\$130.000', 'general': '\$150.000'},
  };

  late TextEditingController _dniCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _dniCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profile != null) {
          _pilotProfile = profile;
          _dniCtrl.text = profile['dni'] ?? '';
          _phoneCtrl.text = profile['phone'] ?? '';
          _locationCtrl.text = profile['location'] ?? '';
          
          // Verificar bonificación: si ya participó (check_in) O si ya tiene puntos (ranking vinculado)
          final prevCheckIns = await Supabase.instance.client
              .from('check_ins').select('id').eq('profile_id', user.id).limit(1);
          final prevRankings = await Supabase.instance.client
              .from('rankings').select('id').eq('profile_id', user.id).gt('points', 0).limit(1);
          _isBonificado = prevCheckIns.isNotEmpty || prevRankings.isNotEmpty;
        }
      }

      final events = await Supabase.instance.client.from('events').select().eq('is_active', true).limit(1);
      if (events.isNotEmpty) _activeEvent = events[0];
      
    } catch (e) {
      debugPrint('Error loading pre-inscription data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processInscription(String paymentMethod) async {
    if (_pilotProfile == null || _activeEvent == null) return;
    
    // Verificar que tengo nombre real
    final nombre = _pilotProfile!['first_name']?.toString() ?? '';
    if (nombre.isEmpty || nombre.contains('invitado')) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa tus datos en tu Perfil antes de inscribirte.'), backgroundColor: Colors.red));
       return;
    }

    if (_selectedCategories.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccioná al menos una categoría.'), backgroundColor: Colors.red));
       return;
    }

    if (_dniCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNI y Teléfono son obligatorios.'), backgroundColor: Colors.red));
       return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Actualizar perfil del piloto con nuevos datos
      await Supabase.instance.client.from('profiles').update({
        'dni': _dniCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      }).eq('id', _pilotProfile!['id']);

      // 2. Guardar o actualizar la inscripción (una fila por categoría)
      for (final cat in _selectedCategories) {
        await Supabase.instance.client
            .from('inscriptions')
            .upsert({
              'event_id': _activeEvent!['id'],
              'pilot_id': _pilotProfile!['id'],
              'category': cat,
              'payment_method': paymentMethod,
              'payment_status': 'pending',
              'total_price': _getTotalPriceValue(),
            }, onConflict: 'event_id, pilot_id, category');
      }
      
      // 2. Acciones visuales post-guardado dependientes del método
      if (paymentMethod == 'mercadopago') {
         // TODO: Integrar lógica o SDK real de MP. Por ahora, lanzar URL falsa.
         final url = Uri.parse('https://link.mercadopago.com.ar/camimmobilock');
         if (await canLaunchUrl(url)) {
           await launchUrl(url, mode: LaunchMode.externalApplication);
         }
      } else {
         // Mostrar modal de datos bancarios
         if (mounted) {
           _showBankTransferDialog();
         }
      }
      
    } catch (e) {
      // Ignorar errores de duplicados si upsert falla por algún motivo extraño
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBankTransferDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.black),
            SizedBox(width: 8),
            Text('Transferencia', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Realiza el pago a la siguiente cuenta de CAMIM:', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Banco / App:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                  const Text('AstroPay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 10),
                  const Text('CVU:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('0000184305010023364563', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '0000184305010023364563'));
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('CVU copiado'), duration: Duration(seconds: 1)));
                        },
                      )
                    ],
                  ),
                  const Text('Alias:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                  const Text('Guillepay25', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 10),
                  const Text('Titular:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
                  const Text('Francisco Guillermo de Olivera', style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Una vez transferido, tu inscripción quedará como "Pendiente". Envía el comprobante por WhatsApp.', style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.of(ctx).pop();
               context.pop(); // Volver al inicio
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscripción Pendiente Registrada', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
            },
            child: const Text('Entendido, volver'),
          ),
        ],
      )
    );
  }

  int _getMaxPriceValue() {
    if (_selectedCategories.isEmpty) return 0;
    int maxVal = 0;
    for (final cat in _selectedCategories) {
      final priceStr = _isBonificado
          ? _categoryPrices[cat]!['bonus']!
          : _categoryPrices[cat]!['general']!;
      final numStr = priceStr.replaceAll(RegExp(r'[^\d]'), '');
      final val = int.tryParse(numStr) ?? 0;
      if (val > maxVal) maxVal = val;
    }
    return maxVal;
  }

  int _getTotalPriceValue() => _getMaxPriceValue();

  String _getTotalPriceDisplay() {
    final val = _getMaxPriceValue();
    if (val == 0) return '\$0';
    final formatted = val.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\$$formatted';
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activeEvent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pre-Inscripción')),
        body: const Center(child: Text('No hay eventos activos')),
      );
    }

    final String fullName = '${_pilotProfile?['first_name'] ?? 'Piloto'} ${_pilotProfile?['last_name'] ?? ''}';
    final String pilotMoto = '${_pilotProfile?['motorcycle_model'] ?? 'No especificada'}';
    final String pilotNumber = '${_pilotProfile?['racing_number'] ?? '??'}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inscripción Oficial', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                children: [
                   const Icon(Icons.sports_score, color: Colors.white, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_activeEvent!['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          CountdownWidget(
                            targetDate: DateTime.tryParse(_activeEvent!['date_start'] ?? ''),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                       ],
                     )
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Revisión de Datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Estos datos se envían a la torre de control.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            
            _InfoRow(label: 'Piloto', value: fullName),
            const Divider(),
            _InfoRow(label: 'Moto/Quad', value: pilotMoto),
            const Divider(),
            _InfoRow(label: 'N° Carrera', value: '#$pilotNumber'),
            const SizedBox(height: 16),
            
            _buildMandatoryField('DNI (Obligatorio)', _dniCtrl, Icons.badge_outlined, TextInputType.number),
            const SizedBox(height: 12),
            _buildMandatoryField('Teléfono de Contacto', _phoneCtrl, Icons.phone_android, TextInputType.phone),
            const SizedBox(height: 12),
            _buildMandatoryField('Localidad', _locationCtrl, Icons.location_on_outlined, TextInputType.text),
            
            const SizedBox(height: 32),
            const Text('Categorías a Inscribirse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Podés seleccionar más de una. Siempre pagás el precio mayor.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryPrices.entries.map((entry) {
                final isSelected = _selectedCategories.contains(entry.key);
                final price = _isBonificado ? entry.value['bonus']! : entry.value['general']!;
                return FilterChip(
                  label: Text('${entry.key}\n$price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  onSelected: (val) => setState(() {
                    if (val) _selectedCategories.add(entry.key);
                    else _selectedCategories.remove(entry.key);
                  }),
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey[100],
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.black : Colors.grey[300]!)),
                );
              }).toList(),
            ),

            // Resumen de precio en tiempo real
            if (_selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF333333)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCategories.join(' + '), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          const Text('Total a pagar:', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(_getTotalPriceDisplay(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                    if (_isBonificado) ...[
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)), child: const Text('BONUS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                    ],
                  ],
                ),
              ),
            ],

            const Text('Método de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            const SizedBox(height: 12),

            // Boton Efectivo
            ElevatedButton(
              onPressed: () => _processInscription('efectivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('PAGAR EN EFECTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boton Transferencia
            OutlinedButton(
              onPressed: () => _processInscription('transfer'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, color: Colors.black, size: 20),
                  SizedBox(width: 12),
                  Text('TRANSFERENCIA BANCARIA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMandatoryField(String label, TextEditingController ctrl, IconData icon, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.black, fontSize: 16), // Texto negro
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
