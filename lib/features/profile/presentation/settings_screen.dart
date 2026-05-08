import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'profile_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedGender;
  bool _isSaving = false;
  bool _isLoaded = false;

  static const List<String> _genderOptions = ['Erkek', 'Kadın', 'Diğer', 'Belirtmek İstemiyorum'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile profile) {
    if (_isLoaded) return;
    _nameController.text = profile.fullName;
    _ageController.text = profile.age?.toString() ?? '';
    _bioController.text = profile.bio ?? '';
    _selectedGender = profile.gender;
    _isLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AYARLAR',
          style: AppTextStyles.headline.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null) _loadProfile(profile);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Info Section
                _buildSectionTitle('KİŞİSEL BİLGİLER'),
                const SizedBox(height: 20),

                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Ad Soyad',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // Age
                _buildTextField(
                  controller: _ageController,
                  label: 'Yaş',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Gender
                _buildGenderDropdown(),
                const SizedBox(height: 16),

                // Bio
                _buildTextField(
                  controller: _bioController,
                  label: 'Hakkımda',
                  icon: Icons.edit_note,
                  maxLines: 3,
                ),

                const SizedBox(height: 40),

                // Account Info Section
                _buildSectionTitle('HESAP BİLGİLERİ'),
                const SizedBox(height: 20),

                // Email (read-only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider.withAlpha(60)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('E-posta', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              Supabase.instance.client.auth.currentUser?.email ?? 'Bilinmiyor',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Phone (read-only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider.withAlpha(60)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Telefon', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              profile?.phoneNumber ?? 'Belirtilmemiş',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withAlpha(80),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                        : const Text(
                            'DEĞİŞİKLİKLERİ KAYDET',
                            style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 24, height: 1, color: AppColors.divider),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider.withAlpha(60))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider.withAlpha(60))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wc_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                hint: const Text('Cinsiyet', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                isExpanded: true,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
                dropdownColor: AppColors.background,
                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
      };

      final ageText = _ageController.text.trim();
      if (ageText.isNotEmpty) {
        updates['age'] = int.tryParse(ageText);
      }

      await supabase.from('users').update(updates).eq('id', userId);

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgileriniz güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
