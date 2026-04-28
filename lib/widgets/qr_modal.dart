import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void showQRModal(BuildContext context, String qrCode) {
  if (qrCode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tienes un código QR asignado.'))
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), 
          topRight: Radius.circular(30)
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, 
            height: 4, 
            decoration: BoxDecoration(
              color: Colors.grey[300], 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          const SizedBox(height: 24),
          const Text(
            'MI CÓDIGO DE INGRESO', 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
          ),
          const SizedBox(height: 12),
          Text(
            'Presenta este código en la puerta para ingresar a pista.', 
            textAlign: TextAlign.center, 
            style: TextStyle(color: Colors.grey[600])
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 10, 
                  offset: const Offset(0, 4)
                )
              ],
            ),
            child: QrImageView(
              data: qrCode,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            qrCode, 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              letterSpacing: 4, 
              color: Colors.grey
            )
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, 
                padding: const EdgeInsets.symmetric(vertical: 16), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                )
              ),
              child: const Text(
                'CERRAR', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
