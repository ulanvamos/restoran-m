import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/presentation/login_screen.dart';
import '../../main/presentation/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Splash animasyonunu göstermek için kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Supabase mevcut oturumu kontrol et
    final session = Supabase.instance.client.auth.currentSession;

    final Widget destination;
    if (session != null) {
      // Kullanıcı zaten giriş yapmış — doğrudan ana sayfaya git
      destination = const MainScreen();
    } else {
      // Oturum yok — giriş ekranına yönlendir
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Centerpiece Icon
                Container(
                  width: 128,
                  height: 128,
                  margin: const EdgeInsets.only(bottom: 48),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant, // Material Symbol Restaurant
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                ).animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),

                // Brand Identity
                Text(
                  'RESTORANIM',
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),

                // Divider
                Container(
                  width: 48,
                  height: 1,
                  color: AppColors.divider,
                ).animate().fade(delay: 800.ms).scaleX(),

                const SizedBox(height: 24),

                // Tagline
                Text(
                  'Yerinde ve zamanında lezzet',
                  style: AppTextStyles.tagline,
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

