import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../widgets/countdown_widget.dart';
import '../theme/app_theme.dart';

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
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, completa tus datos en tu Perfil antes de inscribirte.'), backgroundColor: AppTheme.camimRed));
       return;
    }

    if (_selectedCategories.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleccioná al menos una categoría.'), backgroundColor: AppTheme.camimRed));
       return;
    }

    if (_dniCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DNI y Teléfono son obligatorios.'), backgroundColor: AppTheme.camimRed));
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
      
      // Enviar notificación al admin (opcional, extra a lo guardado en tabla)
      await Supabase.instance.client.from('notifications').insert({
        'title': 'NUEVA INSCRIPCIÓN',
        'body': '${nombre.toUpperCase()} SE HA INSCRIPTO ($paymentMethod)',
        'type': 'info',
        'target_role': 'admin',
      });

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
        backgroundColor: AppTheme.camimAsh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: Colors.white),
            const SizedBox(width: 8),
            Text('TRANSFERENCIA', style: AppTheme.displayFont(color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REALIZA EL PAGO A LA SIGUIENTE CUENTA:', style: AppTheme.dataFont(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CVU:', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                  Row(
                    children: [
                      Expanded(
                        child: Text('0000177500096850511159', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '0000177500096850511159'));
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('CVU copiado', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent, duration: Duration(seconds: 1)));
                        },
                      )
                    ],
                  ),
                  Text('ALIAS:', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                  Text('camim2027', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text('TITULAR:', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                  Text('FRANCIS AUGUSTO DE OLIVERA', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('UNA VEZ TRANSFERIDO, TU INSCRIPCIÓN QUEDARÁ COMO "PENDIENTE". ENVÍA EL COMPROBANTE POR WHATSAPP.', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.of(ctx).pop();
               context.pop(); // Volver al inicio
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscripción Pendiente Registrada', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
            },
            child: Text('ENTENDIDO, VOLVER', style: AppTheme.dataFont(color: AppTheme.camimRed)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppTheme.camimInk, body: const Center(child: CircularProgressIndicator(color: AppTheme.camimRed)));
    }

    if (_activeEvent == null) {
      return Scaffold(
        backgroundColor: AppTheme.camimInk,
        appBar: AppBar(title: Text('PRE-INSCRIPCIÓN', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)), backgroundColor: AppTheme.camimInk, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: Text('NO HAY EVENTOS ACTIVOS', style: AppTheme.dataFont(color: Colors.white54))),
      );
    }

    final String fullName = '${_pilotProfile?['first_name'] ?? 'PILOTO'} ${_pilotProfile?['last_name'] ?? ''}'.toUpperCase();
    final String pilotMoto = '${_pilotProfile?['motorcycle_model'] ?? 'NO ESPECIFICADA'}'.toUpperCase();
    final String pilotNumber = '${_pilotProfile?['racing_number'] ?? '??'}';

    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ INSCRIPCIÓN OFICIAL', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                color: AppTheme.camimAsh,
                border: const Border(left: BorderSide(color: AppTheme.camimRed, width: 4)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.sports_score, color: Colors.white, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_activeEvent!['title']?.toString().toUpperCase() ?? '', style: AppTheme.displayFont(color: Colors.white, fontSize: 18)),
                         const SizedBox(height: 4),
                         CountdownWidget(
                           targetDate: DateTime.tryParse(_activeEvent!['date_start'] ?? ''),
                           style: AppTheme.dataFont(color: Colors.white54, fontSize: 12),
                         ),
                       ],
                     )
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('REVISIÓN DE DATOS', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text('ESTOS DATOS SE ENVÍAN A LA TORRE DE CONTROL.', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 16),
            
            _InfoRow(label: 'PILOTO', value: fullName),
            const Divider(color: Colors.white12),
            _InfoRow(label: 'MOTO/QUAD', value: pilotMoto),
            const Divider(color: Colors.white12),
            _InfoRow(label: 'N° CARRERA', value: '#$pilotNumber'),
            const SizedBox(height: 24),
            
            _buildMandatoryField('DNI (OBLIGATORIO)', _dniCtrl, Icons.badge_outlined, TextInputType.number),
            const SizedBox(height: 12),
            _buildMandatoryField('TELÉFONO DE CONTACTO', _phoneCtrl, Icons.phone_android, TextInputType.phone),
            const SizedBox(height: 12),
            _buildMandatoryField('LOCALIDAD', _locationCtrl, Icons.location_on_outlined, TextInputType.text),
            
            const SizedBox(height: 32),
            Text('CATEGORÍAS A INSCRIBIRSE', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text('PODÉS SELECCIONAR MÁS DE UNA. SIEMPRE PAGÁS EL PRECIO MAYOR.', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryPrices.entries.map((entry) {
                final isSelected = _selectedCategories.contains(entry.key);
                final price = _isBonificado ? entry.value['bonus']! : entry.value['general']!;
                return FilterChip(
                  label: Text('${entry.key.toUpperCase()}\n$price', style: AppTheme.dataFont(fontSize: 10, color: isSelected ? Colors.white : Colors.white70)),
                  selected: isSelected,
                  onSelected: (val) => setState(() {
                    if (val) _selectedCategories.add(entry.key);
                    else _selectedCategories.remove(entry.key);
                  }),
                  selectedColor: AppTheme.camimRed,
                  backgroundColor: AppTheme.camimAsh,
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: isSelected ? AppTheme.camimRed : Colors.white12)),
                );
              }).toList(),
            ),

            // Resumen de precio en tiempo real
            if (_selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.camimAsh,
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white54, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCategories.join(' + ').toUpperCase(), style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('TOTAL A PAGAR:', style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(_getTotalPriceDisplay(), style: AppTheme.displayFont(color: Colors.white, fontSize: 24)),
                    if (_isBonificado) ...[
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), color: Colors.greenAccent.withOpacity(0.1), child: Text('BONUS', style: AppTheme.dataFont(color: Colors.greenAccent, fontSize: 10))),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Text('MÉTODO DE PAGO', style: AppTheme.subheadFont(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            
            // Boton Efectivo
            ElevatedButton(
              onPressed: () => _processInscription('efectivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_money, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text('PAGAR EN EFECTIVO', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boton Transferencia
            OutlinedButton(
              onPressed: () => _processInscription('transfer'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text('TRANSFERENCIA BANCARIA', style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
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
        Text(label, style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: AppTheme.dataFont(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.white54),
            filled: true,
            fillColor: AppTheme.camimAsh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppTheme.camimRed, width: 2)),
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
          Text(label, style: AppTheme.dataFont(color: Colors.white54, fontSize: 12)),
          Text(value, style: AppTheme.dataFont(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
