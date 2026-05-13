import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AdminInscriptionsScreen extends StatefulWidget {
  const AdminInscriptionsScreen({super.key});

  @override
  State<AdminInscriptionsScreen> createState() => _AdminInscriptionsScreenState();
}

class _AdminInscriptionsScreenState extends State<AdminInscriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _inscriptions = [];
  String? _activeEventTitle;

  @override
  void initState() {
    super.initState();
    _loadInscriptions();
  }

  Future<void> _loadInscriptions() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get active event
      final events = await Supabase.instance.client
          .from('events')
          .select()
          .eq('is_active', true)
          .limit(1);
          
      if (events.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final eventId = events[0]['id'];
      _activeEventTitle = events[0]['title'];

      // 2. Get inscriptions for this event
      final response = await Supabase.instance.client
          .from('inscriptions')
          .select('*, profiles(first_name, last_name, dni, phone, motorcycle_model, racing_number)')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _inscriptions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading inscriptions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('inscriptions')
          .update({'payment_status': newStatus})
          .eq('id', id);
      _loadInscriptions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.camimRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.camimInk,
      appBar: AppBar(
        title: Text('◆ INSCRIPCIONES RECIENTES', style: AppTheme.dataFont(color: Colors.white, fontSize: 16).copyWith(letterSpacing: 2)),
        backgroundColor: AppTheme.camimInk,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInscriptions),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.camimRed))
          : _inscriptions.isEmpty
              ? Center(child: Text('NO HAY INSCRIPCIONES AÚN', style: AppTheme.dataFont(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _inscriptions.length,
                  itemBuilder: (context, index) {
                    final item = _inscriptions[index];
                    final profile = item['profiles'] ?? {};
                    final String fullName = '${profile['first_name'] ?? 'PILOTO'} ${profile['last_name'] ?? ''}'.toUpperCase();
                    final String category = item['category']?.toString().toUpperCase() ?? 'N/A';
                    final String payMethod = item['payment_method']?.toString().toUpperCase() ?? 'N/A';
                    final String status = item['payment_status']?.toString().toUpperCase() ?? 'PENDING';
                    final String price = item['total_price']?.toString() ?? '0';
                    final String phone = profile['phone'] ?? 'NO INDICADO';
                    final String dni = profile['dni'] ?? 'NO INDICADO';
                    final String moto = profile['motorcycle_model']?.toString().toUpperCase() ?? 'NO INDICADA';
                    final String number = profile['racing_number']?.toString() ?? '??';

                    Color statusColor = Colors.orangeAccent;
                    if (status == 'PAID' || status == 'COMPLETED') statusColor = Colors.green;
                    if (status == 'CANCELLED') statusColor = AppTheme.camimRed;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.camimAsh,
                        border: Border(left: BorderSide(color: statusColor, width: 4)),
                      ),
                      child: ExpansionTile(
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white54,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(fullName, style: AppTheme.dataFont(color: Colors.white, fontSize: 14))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: statusColor.withOpacity(0.1),
                              child: Text(status, style: AppTheme.dataFont(color: statusColor, fontSize: 10)),
                            ),
                          ],
                        ),
                        subtitle: Text('$category • \$${price} • $payMethod', style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.black12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow('TELÉFONO', phone),
                                _DetailRow('DNI', dni),
                                _DetailRow('MOTO/QUAD', moto),
                                _DetailRow('N° CARRERA', '#$number'),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status != 'PAID')
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(item['id'], 'paid'),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                        child: Text('MARCAR PAGADO', style: AppTheme.dataFont(color: Colors.green, fontSize: 10)),
                                      ),
                                    const SizedBox(width: 8),
                                    if (status != 'CANCELLED')
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(item['id'], 'cancelled'),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.camimRed), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                        child: Text('CANCELAR', style: AppTheme.dataFont(color: AppTheme.camimRed, fontSize: 10)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.dataFont(color: Colors.white54, fontSize: 10)),
          Text(value, style: AppTheme.dataFont(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
