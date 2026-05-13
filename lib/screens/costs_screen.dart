import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CostsScreen extends StatelessWidget {
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ COSTOS', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('TEMPORADA 2026', style: AppTheme.displayFont(color: Colors.white, fontSize: 34).copyWith(height: 1)),
            const SizedBox(height: 8),
            Text('Conoce los valores actualizados por categoría.', style: AppTheme.bodyFont(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Cards modernas para cada categoría
            _buildCostCard(
              category: 'CAT. QUADS',
              bonusCost: '\$180.000',
              generalCost: '\$200.000',
            ),
            _buildCostCard(
              category: 'CAT. MINI QUAD & CROSS',
              bonusCost: '\$100.000',
              generalCost: '\$120.000',
            ),
            _buildCostCard(
              category: 'CAT. VELOTERRA',
              bonusCost: '\$130.000',
              generalCost: '\$150.000',
            ),
            _buildCostCard(
              category: 'CAT. MOTOS',
              bonusCost: '\$170.000',
              generalCost: '\$190.000',
            ),
            
            const SizedBox(height: 24),
            
            // Advertencia / Atencion
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.camimRed.withOpacity(0.1),
                border: Border.all(color: AppTheme.camimRed.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.camimRed, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡ATENCIÓN!', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 16).copyWith(letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(
                          'Todos los pilotos que no cuenten con su credencial, abonarán el monto de inscripción general.',
                          style: AppTheme.bodyFont(color: Colors.red[200]!, fontSize: 14).copyWith(height: 1.4),
                        ),
                      ],
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

  Widget _buildCostCard({required String category, required String bonusCost, required String generalCost}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.camimAsh,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.white10),
                 child: const Icon(Icons.sports_motorsports_outlined, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(category, style: AppTheme.dataFont(fontSize: 16, color: Colors.white))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PILOTO BONIFICADO', style: AppTheme.dataFont(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text(bonusCost, style: AppTheme.displayFont(fontSize: 24, color: Colors.greenAccent).copyWith(height: 1)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GENERAL', style: AppTheme.dataFont(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text(generalCost, style: AppTheme.displayFont(fontSize: 24, color: Colors.white70).copyWith(height: 1)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
