import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'profile_controller.dart';
import '../../support/presentation/customer_support_screen.dart';
import '../../support/presentation/customer_support_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isSaving = false;
  bool _isLoaded = false;
  bool _anamnesisLoaded = false;

  // Anamnesis Selections
  List<String> _selectedDiets = [];
  List<String> _selectedAllergies = [];
  List<String> _selectedChronic = [];
  List<String> _selectedSeating = [];
  List<String> _selectedInterests = [];
  String? _coffeePreference;
  String? _teaSugarPreference;
  bool _consumesAlcohol = false;

  // Other Text Controllers
  final _otherChronicController = TextEditingController();
  final _otherDietController = TextEditingController();
  final _otherAllergyController = TextEditingController();

  // Options
  final _dietOptions = ['Özel Diyetim Yok', 'Vejetaryen', 'Vegan', 'Pesketaryen', 'Glutensiz', 'Laktozsuz', 'Helal', 'Diğer'];
  final _allergyOptions = ['Alerjim Yok', 'Deniz Ürünleri', 'Kuruyemiş', 'Süt Ürünleri', 'Gluten', 'Yumurta', 'Diğer'];
  final _chronicOptions = ['Rahatsızlığım Yok', 'Diyabet', 'Tansiyon', 'Kalp Rahatsızlığı', 'Çölyak', 'Astım', 'Diğer'];
  final _seatingOptions = ['Sigara İçilmeyen', 'Sigara İçilen', 'Teras', 'Bahçe', 'İç Salon', 'Manzaralı', 'Sessiz Ortam'];
  final _interestOptions = ['Şef Tadım Menüleri', 'Degüstasyon Menüleri', 'Şarap Eşleşmeleri', 'Deniz Ürünleri', 'Et Menüleri', 'Dünya Mutfakları'];
  final _coffeeOptions = ['Espresso', 'Americano', 'Latte', 'Türk Kahvesi', 'Filtre Kahve', 'Macchiato', 'Mocha', 'Kapsül Kahve'];
  final _teaSugarOptions = ['Şekersiz', 'Az Şekerli', 'Orta Şekerli', 'Çok Şekerli'];

  static const List<String> _genderOptions = ['Erkek', 'Kadın', 'Diğer', 'Belirtmek İstemiyorum'];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _otherChronicController.dispose();
    _otherDietController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile profile) {
    if (_isLoaded) return;
    _nameController.text = profile.fullName;
    _cityController.text = profile.city ?? '';
    _bioController.text = profile.bio ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _selectedBirthDate = profile.birthDate;
    _selectedGender = profile.gender;
    _isLoaded = true;
    _loadAnamnesis();
  }

  Future<void> _loadAnamnesis() async {
    if (_anamnesisLoaded) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('customer_anamnesis')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['preferences'] != null) {
        final prefs = response['preferences'];
        setState(() {
          _selectedDiets = List<String>.from(prefs['dietary_preferences'] ?? []);
          _selectedAllergies = List<String>.from(prefs['allergies'] ?? []);
          _selectedChronic = List<String>.from(prefs['chronic_illnesses'] ?? []);
          _selectedSeating = List<String>.from(prefs['seating_preferences'] ?? []);
          _selectedInterests = List<String>.from(prefs['interests'] ?? []);
          final bev = prefs['beverages'] ?? {};
          _coffeePreference = bev['coffee'];
          _teaSugarPreference = bev['tea_sugar'];
          _consumesAlcohol = bev['alcohol'] ?? false;
          _otherChronicController.text = prefs['other_chronic'] ?? '';
          _otherDietController.text = prefs['other_diet'] ?? '';
          _otherAllergyController.text = prefs['other_allergy'] ?? '';
          _anamnesisLoaded = true;
        });
      } else {
        setState(() => _anamnesisLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _anamnesisLoaded = true);
    }
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

                // City
                _buildTextField(
                  controller: _cityController,
                  label: 'Şehir',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 16),

                // Birth Date
                _buildBirthDateSelector(),
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

                // Anamnesis Fields
                _buildSectionTitle('ÖNEMLİ SAĞLIK BİLGİLERİ'),
                const SizedBox(height: 16),
                _buildAnamnesisTitle('🩺 Kronik Rahatsızlıklar'),
                _buildMultiSelectChip(_chronicOptions, _selectedChronic),
                if (_selectedChronic.contains('Diğer'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildOtherTextField('Diğer rahatsızlığınızı belirtin', _otherChronicController),
                  ),
                const SizedBox(height: 16),

                _buildAnamnesisTitle('🍃 Beslenme Tercihleri'),
                _buildMultiSelectChip(_dietOptions, _selectedDiets),
                if (_selectedDiets.contains('Diğer'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildOtherTextField('Diğer beslenme tercihinizi belirtin', _otherDietController),
                  ),
                const SizedBox(height: 16),

                _buildAnamnesisTitle('🥜 Alerji Bilgileri'),
                _buildMultiSelectChip(_allergyOptions, _selectedAllergies),
                if (_selectedAllergies.contains('Diğer'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _buildOtherTextField('Diğer alerjinizi belirtin', _otherAllergyController),
                  ),
                const SizedBox(height: 32),

                _buildSectionTitle('KİŞİSEL TERCİHLER (İSTEĞE BAĞLI)'),
                const SizedBox(height: 16),
                
                _buildAnamnesisTitle('🌅 Masa & Ortam Tercihi'),
                _buildMultiSelectChip(_seatingOptions, _selectedSeating),
                const SizedBox(height: 16),

                _buildAnamnesisTitle('☕ İçecek Alışkanlıkları'),
                _buildSingleSelectDropdown('Çay Şekeri', _teaSugarOptions, _teaSugarPreference, (val) => setState(() => _teaSugarPreference = val)),
                const SizedBox(height: 12),
                _buildSingleSelectDropdown('Kahve Tercihi', _coffeeOptions, _coffeePreference, (val) => setState(() => _coffeePreference = val)),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alkollü İçecek Tüketimi', style: TextStyle(fontSize: 14)),
                  value: _consumesAlcohol,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _consumesAlcohol = val),
                ),
                const SizedBox(height: 16),

                _buildAnamnesisTitle('⭐ İlgi Alanları'),
                _buildMultiSelectChip(_interestOptions, _selectedInterests),

                const SizedBox(height: 40),

                // Account Info Section
                _buildSectionTitle('HESAP BİLGİLERİ'),
                const SizedBox(height: 20),

                // Email
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
                      TextButton(
                        onPressed: _showEmailChangeDialog,
                        child: const Text('Değiştir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 40),

                // Support Section
                _buildSectionTitle('DESTEK'),
                const SizedBox(height: 20),
                _buildSupportButton(context),

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

  Future<void> _showEmailChangeDialog() async {
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool codeSent = false;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('E-Posta Değiştir', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!codeSent) ...[
                  const Text('Yeni e-posta adresinizi girin. Size bir doğrulama kodu göndereceğiz.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Yeni E-Posta',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  Text('\${emailCtrl.text} adresine doğrulama kodu gönderildi.', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('MOCK KOD: 1234', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Doğrulama Kodu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  if (!codeSent) {
                    if (emailCtrl.text.isNotEmpty && emailCtrl.text.contains('@')) {
                      setDialogState(() => codeSent = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir e-posta girin')));
                    }
                  } else {
                    if (codeCtrl.text == '1234') {
                      Navigator.pop(ctx, emailCtrl.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hatalı Kod (İpucu: 1234)')));
                    }
                  }
                },
                child: Text(codeSent ? 'Doğrula' : 'Kod Gönder', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      )
    ).then((newEmail) async {
      if (newEmail != null && newEmail is String) {
        setState(() => _isSaving = true);
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          
          // Try updating auth email
          try {
            await Supabase.instance.client.auth.updateUser(UserAttributes(email: newEmail));
          } catch (_) {
            // Ignored if Supabase enforces confirmation link and fails immediately. 
            // We just mock it and save it to public users.
          }
          
          // Save to public users table
          if (userId != null) {
            await Supabase.instance.client.from('users').update({'email': newEmail}).eq('id', userId);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta başarıyla güncellendi!'), backgroundColor: Colors.green));
          }
          ref.invalidate(userProfileProvider);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      }
    });
  }

  Widget _buildSupportButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomerSupportScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withAlpha(60)),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withAlpha(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.headset_mic, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Canlı Destek',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bir probleminiz mi var? Bizimle iletişime geçin.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
          ],
        ),
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

  Widget _buildAnamnesisTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildMultiSelectChip(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return FilterChip(
          label: Text(option),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                if (option.contains('Yok')) {
                  selectedList.clear();
                } else {
                  selectedList.removeWhere((name) => name.contains('Yok'));
                }
                selectedList.add(option);
              } else {
                selectedList.removeWhere((String name) => name == option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSingleSelectDropdown(String hint, List<String> options, String? currentValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider.withAlpha(60))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider.withAlpha(60))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: AppColors.background,
      ),
      value: currentValue,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
      dropdownColor: AppColors.background,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOtherTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider.withAlpha(60))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(fontSize: 14),
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

  Widget _buildBirthDateSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _selectedBirthDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider.withAlpha(60)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedBirthDate != null
                  ? "\${_selectedBirthDate!.day}/\${_selectedBirthDate!.month}/\${_selectedBirthDate!.year}"
                  : "Doğum Tarihi",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _selectedBirthDate != null ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed previous VIP Preferences Button

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı giriş yapmamış');

      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'gender': _selectedGender,
      };

      if (_selectedBirthDate != null) {
        updates['birth_date'] = _selectedBirthDate!.toIso8601String();
      }

      await supabase.from('users').update(updates).eq('id', userId);

      // Save Anamnesis
      final hasMandatory = _selectedDiets.isNotEmpty || _selectedAllergies.isNotEmpty || _selectedChronic.isNotEmpty;
      final preferencesJson = {
        'dietary_preferences': _selectedDiets,
        'other_diet': _selectedDiets.contains('Diğer') ? _otherDietController.text.trim() : null,
        'allergies': _selectedAllergies,
        'other_allergy': _selectedAllergies.contains('Diğer') ? _otherAllergyController.text.trim() : null,
        'chronic_illnesses': _selectedChronic,
        'other_chronic': _selectedChronic.contains('Diğer') ? _otherChronicController.text.trim() : null,
        'seating_preferences': _selectedSeating,
        'interests': _selectedInterests,
        'beverages': {
          'coffee': _coffeePreference,
          'tea_sugar': _teaSugarPreference,
          'alcohol': _consumesAlcohol,
        },
        'has_mandatory': hasMandatory,
      };

      await supabase.from('customer_anamnesis').upsert({
        'user_id': userId,
        'preferences': preferencesJson,
      });

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
