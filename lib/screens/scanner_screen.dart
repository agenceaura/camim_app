import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _activeEventId;
  String? _eventName;

  @override
  void initState() {
    super.initState();
    _getActiveEvent();
  }

  Future<void> _getActiveEvent() async {
    final data = await Supabase.instance.client
        .from('events')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle(); 

    if (data != null) {
      if (mounted) {
        setState(() {
          _activeEventId = data['id'].toString();
          _eventName = data['title'];
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Atención: No hay ninguna carrera activa.'),
            backgroundColor: Colors.orange));
      }
    }
  }

  Future<void> _processScan(String qrCode) async {
    if (_isProcessing || _activeEventId == null) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Encontrar al piloto por QR
      final pilot = await Supabase.instance.client
          .from('profiles')
          .select('id, first_name, last_name, photo_url, racing_number, motorcycle_model')
          .eq('qr_code_id', qrCode)
          .maybeSingle();

      if (pilot == null) {
        _showResult(qrCode, false, 'QR NO VÁLIDO o no pertenece a ningún piloto registrado.', Colors.orange);
        return;
      }

      final pilotId = pilot['id'];
      final pilotName = '${pilot['first_name'] ?? ''} ${pilot['last_name'] ?? ''}'.trim();
      final photoUrl = pilot['photo_url'];

      // 2. Comprobar si ya ingresó a este evento
      final check = await Supabase.instance.client
          .from('check_ins')
          .select()
          .eq('profile_id', pilotId)
          .eq('event_id', _activeEventId!)
          .maybeSingle();

      if (check != null) {
        _showResult(qrCode, false, 'DENEGADO. $pilotName ya ingresó previamente a esta fecha.', Colors.red, photoUrl: photoUrl);
      } else {
        // 3. Registrar "escaneo exitoso"
        await Supabase.instance.client.from('check_ins').insert({
          'profile_id': pilotId,
          'event_id': _activeEventId!,
        });
        
        _showResult(qrCode, true, '¡INGRESO VÁLIDO!\nBienvenido $pilotName', Colors.green, photoUrl: photoUrl);
      }
    } catch (e) {
      _showResult(qrCode, false, 'Falló la conexión o lectura: $e', Colors.black);
    }
  }

  void _showResult(String qr, bool success, String message, Color bgColor, {String? photoUrl}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.camimPaper,
        icon: photoUrl != null 
          ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(photoUrl))
          : Icon(success ? Icons.check_circle : Icons.cancel, color: bgColor, size: 80),
        title: Text(success ? "AUTORIZADO" : "DENEGADO", style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("QR: $qr", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: bgColor, padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: () {
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _isProcessing = false);
                });
              },
              child: const Text('LISTO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Control de Ingreso'),
            if (_eventName != null) 
              Text('Fecha: $_eventName', style: const TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          if (_isProcessing)
            Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))),
            
          if (_activeEventId == null && !_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'ATENCIÓN: Activa una carrera en el calendario para poder registrar los ingresos.',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
          if (_activeEventId != null && !_isProcessing)
             Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.camimRed, width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
        ],
      ),
    );
  }
}
