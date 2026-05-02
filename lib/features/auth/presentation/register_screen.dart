import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()}, // Trigger will use this
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.')),
      );
      Navigator.of(context).pop(); // Go back to login
      
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmeyen bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ).animate().fade(duration: 600.ms).scale(curve: Curves.easeOut),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'RESTORANIM',
                  style: AppTextStyles.headline.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                
                Text(
                  'HESAP OLUŞTUR',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.6),
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 48),

                // Name Input
                _buildInputLabel('AD SOYAD').animate().fade(delay: 400.ms),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nameController,
                  hintText: 'İsminizi giriniz',
                  validator: (val) => val == null || val.isEmpty ? 'Ad soyad gerekli' : null,
                ).animate().fade(delay: 450.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Email Input
                _buildInputLabel('E-POSTA').animate().fade(delay: 500.ms),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _emailController,
                  hintText: 'ornek@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || !val.contains('@') ? 'Geçerli e-posta giriniz' : null,
                ).animate().fade(delay: 550.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Password Input
                _buildInputLabel('ŞİFRE').animate().fade(delay: 600.ms),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _passwordController,
                  hintText: '••••••••',
                  obscureText: true,
                  validator: (val) => val != null && val.length < 6 ? 'En az 6 karakter olmalı' : null,
                ).animate().fade(delay: 650.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Password Confirm Input
                _buildInputLabel('ŞİFRE TEKRAR').animate().fade(delay: 700.ms),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _passwordConfirmController,
                  hintText: '••••••••',
                  obscureText: true,
                  validator: (val) {
                    if (val != _passwordController.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ).animate().fade(delay: 750.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'KAYIT OL',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.5),
                      ),
                ).animate().fade(delay: 850.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          const TextSpan(text: 'Zaten hesabın var mı? '),
                          TextSpan(
                            text: 'Giriş Yap',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: 950.ms),

                const SizedBox(height: 48),

                // Tagline
                Text(
                  'Yerinde ve zamanında lezzet',
                  style: AppTextStyles.tagline.copyWith(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 1050.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
