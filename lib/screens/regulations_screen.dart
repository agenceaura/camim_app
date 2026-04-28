import 'package:flutter/material.dart';

class RegulationsScreen extends StatelessWidget {
  const RegulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Reglamentos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. SOBRE LA COMPETENCIA',
              content: 'El campeonato se regirá bajo las normas establecidas por la organización. Es obligatorio el uso de equipo de protección completo (casco, botas, pechera, guantes y antiparras) en todo momento que se esté sobre la moto/cuatriciclo.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '2. CATEGORÍAS',
              content: 'Las categorías se definen por edad y cilindrada del vehículo. Cada piloto es responsable de inscribirse en la categoría correspondiente. La organización se reserva el derecho de reubicar a un piloto si su nivel no corresponde a la categoría elegida.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '3. BANDERAS Y SEÑALES',
              content: '• Roja: Parada inmediata.\n• Amarilla: Peligro, prohibido saltar y sobrepasar.\n• Cuadros: Fin de la carrera o entrenamiento.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '4. COMPORTAMIENTO',
              content: 'No se permitirán maniobras antideportivas ni insultos a comisarios o demás pilotos. Cualquier falta de respeto será motivo de sanción o descalificación inmediata.',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para solicitar el reglamento completo en formato PDF, comunícate con la secretaría del campeonato.',
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
      ],
    );
  }
}
