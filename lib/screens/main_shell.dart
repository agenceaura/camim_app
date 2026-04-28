import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../widgets/qr_modal.dart';
import 'dashboard_screen.dart';
import 'ranking_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String? _role;
  String? _qrCode;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RankingScreen(),
    const HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    ProfileService().addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService().removeListener(_onProfileChanged);
    NotificationService().stopListening();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {
        _role = ProfileService().profileData?['role'];
        _qrCode = ProfileService().profileData?['qr_code_id'];
      });
      if (_role != null) {
        NotificationService().startListening(_role!);
      }
    }
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, qr_code_id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null && mounted) {
        ProfileService().updateProfile(profile);
        setState(() {
          _role = profile['role'];
          _qrCode = profile['qr_code_id'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showQRButton = _role == 'pilot' && _qrCode != null;
    final bool showScannerButton = _role == 'organizer';

    return Scaffold(
      body: Stack(
        children: [
          const DashboardScreen(),
          if (showQRButton || showScannerButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (showScannerButton) {
                      context.push('/scanner');
                    } else {
                      showQRModal(context, _qrCode!);
                    }
                  },
                  child: Container(
                    width: showScannerButton ? 86 : 72,
                    height: showScannerButton ? 86 : 72,
                    decoration: BoxDecoration(
                      color: showScannerButton ? Colors.red : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(showScannerButton ? 22 : 18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(showScannerButton ? Icons.qr_code_scanner : Icons.qr_code_2, color: showScannerButton ? Colors.white : Colors.black, size: showScannerButton ? 42 : 34),
                        Text(showScannerButton ? 'LEER' : 'QR', style: TextStyle(color: showScannerButton ? Colors.white : Colors.black, fontSize: showScannerButton ? 13 : 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
