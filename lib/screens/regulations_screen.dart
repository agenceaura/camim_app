import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RegulationsScreen extends StatelessWidget {
  const RegulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ REGLAMENTOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
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
            const SizedBox(height: 32),
            _buildSection(
              title: '2. CATEGORÍAS',
              content: 'Las categorías se definen por edad y cilindrada del vehículo. Cada piloto es responsable de inscribirse en la categoría correspondiente. La organización se reserva el derecho de reubicar a un piloto si su nivel no corresponde a la categoría elegida.',
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: '3. BANDERAS Y SEÑALES',
              content: '• ROJA: Parada inmediata.\n• AMARILLA: Peligro, prohibido saltar y sobrepasar.\n• CUADROS: Fin de la carrera o entrenamiento.',
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: '4. COMPORTAMIENTO',
              content: 'No se permitirán maniobras antideportivas ni insultos a comisarios o demás pilotos. Cualquier falta de respeto será motivo de sanción o descalificación inmediata.',
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.camimAsh, 
                border: const Border(left: BorderSide(color: AppTheme.camimRed, width: 4))
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Para solicitar el reglamento completo en formato PDF, comunícate con la secretaría del campeonato.',
                      style: AppTheme.bodyFont(color: Colors.white70, fontSize: 13),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: Colors.white10,
          child: Text(title, style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        Text(content, style: AppTheme.bodyFont(color: Colors.white70, fontSize: 15).copyWith(height: 1.5)),
      ],
    );
  }
}
