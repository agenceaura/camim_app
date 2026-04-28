import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MotoGameScreen extends StatefulWidget {
  const MotoGameScreen({super.key});

  @override
  State<MotoGameScreen> createState() => _MotoGameScreenState();
}

enum VehicleType { moto, quad }

class _MotoGameScreenState extends State<MotoGameScreen> {
  // Game state
  bool _isGameOver = false;
  bool _gameStarted = false;
  bool _isSelecting = true;
  double _score = 0;
  double _highScore = 0;
  
  // Customization
  VehicleType _selectedVehicle = VehicleType.moto;
  Color _selectedColor = Colors.red;
  String _pilotNumber = '0';
  final TextEditingController _numberController = TextEditingController(text: '0');
  
  // Moto position
  double _motoY = 0;
  double _motoVelocity = 0;
  static const double _gravity = -0.6;
  static const double _jumpForce = 12;
  
  // Obstacles
  List<double> _obstaclesX = [];
  double _obstacleSpeed = 5.0;
  
  late Timer _gameTimer;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final user = Supabase.instance.client.auth.currentSession?.user;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('game_scores')
          .select('score')
          .eq('profile_id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _highScore = (data['score'] as int).toDouble());
      }
    }
  }

  void _startGame() {
    setState(() {
      _isSelecting = false;
      _gameStarted = true;
      _isGameOver = false;
      _score = 0;
      _motoY = 0;
      _motoVelocity = 0;
      _obstaclesX = [MediaQuery.of(context).size.width, MediaQuery.of(context).size.width + 400];
      _obstacleSpeed = 5.0;
      _pilotNumber = _numberController.text.isEmpty ? '0' : _numberController.text;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (_isGameOver || _isSelecting) return;
    
    setState(() {
      _motoVelocity += _gravity;
      _motoY += _motoVelocity;
      if (_motoY < 0) {
        _motoY = 0;
        _motoVelocity = 0;
      }

      for (int i = 0; i < _obstaclesX.length; i++) {
        _obstaclesX[i] -= _obstacleSpeed;
        
        // Capped speedup
        if (_obstacleSpeed < 15) {
          _obstacleSpeed += 0.0005; 
        }

        if (_obstaclesX[i] < 60 && _obstaclesX[i] > 20 && _motoY < 40) {
          _gameOver();
        }

        if (_obstaclesX[i] < -100) {
          _obstaclesX[i] = MediaQuery.of(context).size.width + Random().nextInt(400);
          _score += 10;
        }
      }
    });
  }

  void _jump() {
    if (_isSelecting) return;
    if (_isGameOver) {
      _startGame();
    } else if (_motoY == 0) {
      _motoVelocity = _jumpForce;
    } else if (_motoY > 20 && _motoVelocity > -5) {
      // FAST FALL! If tapping in air, slam down
      _motoVelocity = -_jumpForce;
    }
  }

  void _gameOver() {
    _gameTimer.cancel();
    _isGameOver = true;
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = Supabase.instance.client.auth.currentSession?.user;
    if (user == null) return;

    if (_score > _highScore) {
      setState(() => _highScore = _score);
      try {
        await Supabase.instance.client.from('game_scores').upsert({
          'profile_id': user.id,
          'score': _score.toInt(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error saving score: $e');
      }
    }
  }

  @override
  void dispose() {
    if (_gameStarted && !_isGameOver) _gameTimer.cancel();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MOTO DASH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSelecting ? _buildSelectionScreen() : _buildGameLayout(),
    );
  }

  Widget _buildSelectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('PERSONALIZA TU PILOTO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          
          const Text('Vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVehicleOption(VehicleType.moto, Icons.motorcycle, 'MOTO'),
              const SizedBox(width: 16),
              _buildVehicleOption(VehicleType.quad, Icons.minor_crash, 'QUAD'),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text('Color del Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.black].map((c) {
              final isSel = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: c, 
                    shape: BoxShape.circle,
                    border: Border.all(color: isSel ? Colors.blue : Colors.transparent, width: 3),
                    boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)] : null,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          const Text('Número de Piloto (Max 3)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            maxLength: 3,
            decoration: InputDecoration(
              hintText: 'Ej. 65',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('¡A CORRER!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(VehicleType type, IconData icon, String label) {
    final isSel = _selectedVehicle == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVehicle = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSel ? Colors.blue[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSel ? Colors.blue : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: isSel ? Colors.blue : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.blue : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameLayout() {
    return GestureDetector(
      onTap: _jump,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Stack(
          children: [
            // Score
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PUNTOS: ${_score.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
                  Text('RECORD: ${_highScore.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),

            // Ground
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Container(height: 3, color: Colors.black12),
            ),

            // The Vehicle
            Positioned(
              bottom: 150 + _motoY,
              left: 40,
              child: Column(
                children: [
                   Stack(
                     alignment: Alignment.center,
                     children: [
                       // Dynamic Render based on type
                       Container(
                         width: 100, height: 100,
                         child: _selectedVehicle == VehicleType.quad
                           ? Image.asset('assets/quad_sprite.png', 
                               errorBuilder: (context, e, s) => CustomPaint(
                                 painter: VehiclePainter(type: VehicleType.quad, color: _selectedColor),
                                 size: const Size(80, 80),
                               ))
                           : Image.asset('assets/moto_sprite.png', 
                               errorBuilder: (context, e, s) => CustomPaint(
                                 painter: VehiclePainter(type: VehicleType.moto, color: _selectedColor),
                                 size: const Size(80, 80),
                               )),
                       ),

                       // Pilot Number (Number Plate style)
                       Positioned(
                         top: 15,
                         right: 5,
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: Colors.black, width: 1.5),
                             boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                           ),
                           child: Text(
                             _pilotNumber, 
                             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)
                           ),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
            ),

            // Obstacles (Bolts / Gears)
            ..._obstaclesX.map((x) => Positioned(
              bottom: 150,
              left: x,
              child: const Icon(Icons.settings, size: 30, color: Colors.black45),
            )),

            // High Speed Indicator
            if (_obstacleSpeed > 8)
              Positioned(
                bottom: 180,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: const Text('¡VELOCIDAD ALTA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),

            // Game Over Overlay
            if (_isGameOver)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('¡FIN DEL JUEGO!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 16),
                      Text('Puntaje Logrado: ${_score.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text('REINTENTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isSelecting = true),
                        child: const Text('CAMBIAR VEHÍCULO'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VehiclePainter extends CustomPainter {
  final VehicleType type;
  final Color color;

  VehiclePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final trailPaint = Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.fill;
    
    // Draw Fire/Trail (Semejanza al logo)
    final trailPath = Path();
    trailPath.moveTo(0, size.height * 0.4);
    trailPath.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.4);
    trailPath.quadraticBezierTo(size.width * 0.2, size.height * 0.5, 0, size.height * 0.6);
    trailPath.close();
    canvas.drawPath(trailPath, trailPaint);

    if (type == VehicleType.moto) {
      _drawMoto(canvas, size, paint);
    } else {
      _drawQuad(canvas, size, paint);
    }
    
    // Pilot Helmet
    final helmetPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.3), 6, helmetPaint);
  }

  void _drawMoto(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.7);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.close();
    
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 10, paint);
    canvas.drawPath(path, paint);
  }

  void _drawQuad(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.5, size.width * 0.4, size.height * 0.2),
      const Radius.circular(4)
    ));
    
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 12, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 12, paint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.7), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.7), 8, paint);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
