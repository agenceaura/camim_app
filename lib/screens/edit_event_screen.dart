import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic>? initialEvent;

  const EditEventScreen({super.key, this.initialEvent});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _daysController;
  late TextEditingController _dateStartController; 
  late TextEditingController _dateEndController; 
  late TextEditingController _locationNameController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _satController;
  late TextEditingController _sunController;
  late TextEditingController _speedhiveController;
  late TextEditingController _extraInfoController;
  DateTime? _startDate; 
  DateTime? _endDate; 
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent ?? {};
    
    _titleController = TextEditingController(text: event['title']?.toString() ?? 'Gran Premio Misiones');
    _subtitleController = TextEditingController(text: event['subtitle']?.toString() ?? 'FECHA 1');
    _daysController = TextEditingController(text: event['days_text']?.toString() ?? 'Sáb 24 - Dom 25 de Marzo');
    _dateStartController = TextEditingController(text: event['date_start']?.toString() ?? '');
    _dateEndController = TextEditingController(text: event['date_end']?.toString() ?? '');
    _locationNameController = TextEditingController(text: event['location_name']?.toString() ?? 'Circuito Posadas, Misiones');
    _latController = TextEditingController(text: event['latitude']?.toString() ?? '-27.367083');
    _lngController = TextEditingController(text: event['longitude']?.toString() ?? '-55.896083');
    
    if (event['date_start'] != null) {
      _startDate = DateTime.tryParse(event['date_start']);
    }
    if (event['date_end'] != null) {
      _endDate = DateTime.tryParse(event['date_end']);
    }
    
    String satText = "08:00 - Apertura de inscripciones\n10:00 - Entrenamientos Libres MX1";
    String sunText = "09:00 - Series\n13:00 - Finales Todas las Categorías";

    if (event['schedule'] != null) {
      if (event['schedule'] is Map) {
        final Map<String, dynamic> schedMap = event['schedule'];
        if (schedMap.containsKey('saturday') && schedMap['saturday'] is List) {
          satText = (schedMap['saturday'] as List).map((s) => "${s['time']} - ${s['event']}").join('\n');
        } else { satText = ''; }
        if (schedMap.containsKey('sunday') && schedMap['sunday'] is List) {
          sunText = (schedMap['sunday'] as List).map((s) => "${s['time']} - ${s['event']}").join('\n');
        } else { sunText = ''; }
        
        // Cargar extra_info del JSONB si existe
        _extraInfoController = TextEditingController(text: schedMap['extra_info']?.toString() ?? '');
      } else if (event['schedule'] is List) {
        // Fallback por si era el array viejo
        satText = (event['schedule'] as List).map((s) => "${s['time']} - ${s['event']}").join('\n');
        sunText = ""; // Deja domingo libre
        _extraInfoController = TextEditingController(text: '');
      }
    } else {
      _extraInfoController = TextEditingController(text: '');
    }
    
    _satController = TextEditingController(text: satText);
    _sunController = TextEditingController(text: sunText);
    _speedhiveController = TextEditingController(text: event['speedhive_link']?.toString() ?? '');
    _isActive = event['is_active'] == true || widget.initialEvent == null; // New events are active by default
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null) 
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
      helpText: 'SELECCIONA EL RANGO DE LA CARRERA',
      cancelText: 'CANCELAR',
      confirmText: 'LISTO',
      saveText: 'LISTO',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateStartController.text = "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
        _dateEndController.text = "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      });
    }
  }

  List<Map<String, String>> _parseScheduleLines(String text) {
    List<Map<String, String>> list = [];
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('-');
      if (parts.length >= 2) {
        list.add({'time': parts[0].trim(), 'event': parts.sublist(1).join('-').trim()});
      } else {
        list.add({'time': '??:??', 'event': line.trim()});
      }
    }
    return list;
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> schedMap = {
        'saturday': _parseScheduleLines(_satController.text),
        'sunday': _parseScheduleLines(_sunController.text),
        'extra_info': _extraInfoController.text.trim(),
      };

      final Map<String, dynamic> eventData = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'days_text': _daysController.text.trim(),
        'date_start': _dateStartController.text.trim(),
        'date_end': _dateEndController.text.trim(),
        'location_name': _locationNameController.text.trim(),
        'latitude': double.tryParse(_latController.text) ?? -27.367083,
        'longitude': double.tryParse(_lngController.text) ?? -55.896083,
        'schedule': schedMap,
        'speedhive_link': _speedhiveController.text.trim(),
        'is_active': _isActive,
      };

      if (_isActive) {
        // Desactivar todos los demás si este evento será el activo
        final activeEvents = await Supabase.instance.client.from('events').select('id').eq('is_active', true);
        for (var evt in activeEvents) {
          if (widget.initialEvent != null && evt['id'] == widget.initialEvent!['id']) continue;
          await Supabase.instance.client.from('events').update({'is_active': false}).eq('id', evt['id']);
        }
      }

      if (widget.initialEvent != null && widget.initialEvent!['id'] != null) {
        await Supabase.instance.client
            .from('events')
            .update(eventData)
            .eq('id', widget.initialEvent!['id']);
      } else {
        await Supabase.instance.client.from('events').insert(eventData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento guardado con éxito', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
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
        title: const Text('Editar Carrera', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              const Text('Datos Principales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField(_subtitleController, 'Subtítulo (ej. FECHA 1)', hint: 'Ej: FECHA 1'),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Título (ej. Gran Premio Misiones)'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDateRange,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Expanded(child: _buildTextField(_dateStartController, 'Inicio', hint: 'Selecciona')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTextField(_dateEndController, 'Fin', hint: 'Selecciona')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Texto de días eliminado en favor de la cuenta regresiva automática
              _buildTextField(_speedhiveController, 'Link a Speedhive (Opcional)', isRequired: false),
              const SizedBox(height: 12),
              _buildTextField(_extraInfoController, 'Información Útil / Lugar (Opcional)', isRequired: false),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Mostrar en Inicio (Activo)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                subtitle: const Text('Si activas esta fecha, las demás se ocultarán del inicio.'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.black,
              ),
              
              const SizedBox(height: 32),
              const Text('Ubicación (Mapa)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              _buildTextField(_locationNameController, 'Nombre del circuito o lugar'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_latController, 'Latitud', isNumber: true, isRequired: false)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_lngController, 'Longitud', isNumber: true, isRequired: false)),
                ],
              ),

              const SizedBox(height: 32),
              const Text('Cronograma (SÁBADO)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Padding(
                 padding: EdgeInsets.only(top: 4, bottom: 12),
                 child: Text('Formato: 08:00 - Entrenamiento', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              _buildScheduleField(_satController),

              const SizedBox(height: 32),
              const Text('Cronograma (DOMINGO)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const Padding(
                 padding: EdgeInsets.only(top: 4, bottom: 12),
                 child: Text('Formato: 09:00 - Carrera', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              _buildScheduleField(_sunController),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool isRequired = true, String? hint}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal), // Texto negro
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87), // Etiqueta negra
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
      ),
      validator: (value) => (isRequired && value!.isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _buildScheduleField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 6,
      style: const TextStyle(color: Colors.black), // Texto negro
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
      ),
    );
  }
}
