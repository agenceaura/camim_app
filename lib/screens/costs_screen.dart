import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CostsScreen extends StatelessWidget {
  const CostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Mismo gris claro de las demás pantallas
      appBar: AppBar(
        title: const Text('Costos de Inscripción', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Temporada 2026', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text('Conoce los valores actualizados por categoría.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('¡ATENCIÓN!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(
                          'Todos los pilotos que no cuenten con su credencial, abonarán el monto de inscripción general.',
                          style: TextStyle(color: Colors.red[900], fontSize: 14, height: 1.4),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
                 child: const Icon(Icons.sports_motorsports_outlined, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black, letterSpacing: -0.5))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PILOTO BONIFICADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(bonusCost, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GENERAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(generalCost, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
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
