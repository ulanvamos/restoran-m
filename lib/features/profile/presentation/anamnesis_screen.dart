import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../main/presentation/main_screen.dart';

class AnamnesisScreen extends StatefulWidget {
  final bool isFromSettings;

  const AnamnesisScreen({super.key, this.isFromSettings = false});

  @override
  State<AnamnesisScreen> createState() => _AnamnesisScreenState();
}

class _AnamnesisScreenState extends State<AnamnesisScreen> {
  bool _isLoading = false;

  // Selections
  // Selections (Mandatory-ish)
  final List<String> _selectedDiets = [];
  final List<String> _selectedAllergies = [];
  final List<String> _selectedChronic = [];

  // Selections (Optional)
  final List<String> _selectedSeating = [];
  final List<String> _selectedInterests = [];
  
  String? _coffeePreference;
  String? _teaSugarPreference;
  bool _consumesAlcohol = false;

  // Other Text Controllers
  final _otherChronicController = TextEditingController();
  final _otherDietController = TextEditingController();
  final _otherAllergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingAnamnesis();
  }

  Future<void> _loadExistingAnamnesis() async {
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
        if (mounted) {
          setState(() {
            _selectedDiets.addAll(List<String>.from(prefs['dietary_preferences'] ?? []));
            _selectedAllergies.addAll(List<String>.from(prefs['allergies'] ?? []));
            _selectedChronic.addAll(List<String>.from(prefs['chronic_illnesses'] ?? []));
            _selectedSeating.addAll(List<String>.from(prefs['seating_preferences'] ?? []));
            _selectedInterests.addAll(List<String>.from(prefs['interests'] ?? []));
            final bev = prefs['beverages'] ?? {};
            _coffeePreference = bev['coffee'];
            _teaSugarPreference = bev['tea_sugar'];
            _consumesAlcohol = bev['alcohol'] ?? false;
            _otherChronicController.text = prefs['other_chronic'] ?? '';
            _otherDietController.text = prefs['other_diet'] ?? '';
            _otherAllergyController.text = prefs['other_allergy'] ?? '';
          });
        }
      }
    } catch (e) {
      // Ignore load errors, screen will start empty
    }
  }

  @override
  void dispose() {
    _otherChronicController.dispose();
    _otherDietController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  // Options
  final _dietOptions = ['Özel Diyetim Yok', 'Vejetaryen', 'Vegan', 'Pesketaryen', 'Glutensiz', 'Laktozsuz', 'Helal', 'Diğer'];
  final _allergyOptions = ['Alerjim Yok', 'Deniz Ürünleri', 'Kuruyemiş', 'Süt Ürünleri', 'Gluten', 'Yumurta', 'Diğer'];
  final _chronicOptions = ['Rahatsızlığım Yok', 'Diyabet', 'Tansiyon', 'Kalp Rahatsızlığı', 'Çölyak', 'Astım', 'Diğer'];

  final _seatingOptions = ['Sigara İçilmeyen', 'Sigara İçilen', 'Teras', 'Bahçe', 'İç Salon', 'Manzaralı', 'Sessiz Ortam'];
  final _interestOptions = ['Şef Tadım Menüleri', 'Degüstasyon Menüleri', 'Şarap Eşleşmeleri', 'Deniz Ürünleri', 'Et Menüleri', 'Dünya Mutfakları'];
  
  final _coffeeOptions = ['Espresso', 'Americano', 'Latte', 'Türk Kahvesi', 'Filtre Kahve', 'Macchiato', 'Mocha', 'Kapsül Kahve'];
  final _teaSugarOptions = ['Şekersiz', 'Az Şekerli', 'Orta Şekerli', 'Çok Şekerli'];

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Sadece zorunlu alanlar doldurulmuş mu diye bakıyoruz
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
        'has_mandatory': hasMandatory, // Check flag for login
      };

      // Upsert preferences JSON into customer_anamnesis table
      await supabase.from('customer_anamnesis').upsert({
        'user_id': userId,
        'preferences': preferencesJson,
        // Keeping old columns null or empty for compatibility
      });

      if (!mounted) return;
      if (widget.isFromSettings) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tercihler güncellendi!'), backgroundColor: Colors.green),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => const MainScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tercih Profiliniz'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: widget.isFromSettings
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Size kusursuz bir fine-dining deneyimi yaşatabilmemiz için restoranlara bazı ipuçları bırakabilirsiniz.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),

            // ZORUNLU ALANLAR BAŞLIĞI
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ÖNEMLİ SAĞLIK BİLGİLERİ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('🩺 Kronik Rahatsızlıklar'),
            _buildMultiSelectChip(_chronicOptions, _selectedChronic),
            if (_selectedChronic.contains('Diğer'))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildOtherTextField('Diğer rahatsızlığınızı belirtin', _otherChronicController),
              ),
            const SizedBox(height: 24),

            _buildSectionTitle('🍃 Beslenme Tercihleri'),
            _buildMultiSelectChip(_dietOptions, _selectedDiets),
            if (_selectedDiets.contains('Diğer'))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildOtherTextField('Diğer beslenme tercihinizi belirtin', _otherDietController),
              ),
            const SizedBox(height: 24),

            _buildSectionTitle('🥜 Alerji Bilgileri'),
            _buildMultiSelectChip(_allergyOptions, _selectedAllergies),
            if (_selectedAllergies.contains('Diğer'))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildOtherTextField('Diğer alerjinizi belirtin', _otherAllergyController),
              ),
            const SizedBox(height: 32),

            // İSTEĞE BAĞLI ALANLAR BAŞLIĞI
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_border, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'KİŞİSEL TERCİHLER (İSTEĞE BAĞLI)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade700, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('🌅 Masa & Ortam Tercihi'),
            _buildMultiSelectChip(_seatingOptions, _selectedSeating),
            const SizedBox(height: 24),

            _buildSectionTitle('☕ İçecek Alışkanlıkları'),
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
            const SizedBox(height: 24),

            _buildSectionTitle('⭐ İlgi Alanları'),
            _buildMultiSelectChip(_interestOptions, _selectedInterests),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(widget.isFromSettings ? 'Değişiklikleri Kaydet' : 'Kaydet ve İlerle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (!widget.isFromSettings) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (ctx) => const MainScreen()),
                  );
                },
                child: const Text('Şimdilik Atla', style: TextStyle(color: AppColors.textSecondary)),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
            fontSize: 13,
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                // If "Yok" is selected, clear others
                if (option.contains('Yok')) {
                  selectedList.clear();
                } else {
                  // If a normal option is selected, remove "Yok"
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: currentValue,
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
}
