import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/mock_data.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/core/validators.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/models/university.dart';
import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/providers/university_provider.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/widgets/app_logo.dart';

const List<String> _universityTypes = [
  AppStrings.universityTypeGovernment,
  AppStrings.universityTypePrivate,
];

class ProfileFormPage extends ConsumerStatefulWidget {
  final String phone;

  const ProfileFormPage({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends ConsumerState<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedUniversityType;
  String? _selectedGovernorate;
  String? _selectedUniversity;
  DateTime? _selectedBirthDate;
  Gender _selectedGender = Gender.male;
  bool _isLoading = false;

  void _retryUniversities() {
    final type = _selectedUniversityType;
    if (type != null) {
      ref.invalidate(universitiesProvider(type));
    }
  }

  Widget _buildUniversityField(
    BuildContext context,
    AsyncValue<List<University>>? universitiesAsync,
  ) {
    if (_selectedUniversityType == null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.university,
        ),
        child: Text(
          AppStrings.selectUniversityTypeFirst,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.6),
              ),
        ),
      );
    }

    if (universitiesAsync == null) {
      return const SizedBox.shrink();
    }

    return universitiesAsync.when(
      data: (universities) {
        final options = universities
            .map((u) => u.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

        if (_selectedUniversity != null &&
            _selectedUniversity!.isNotEmpty &&
            !options.contains(_selectedUniversity)) {
          options.add(_selectedUniversity!);
        }

        return DropdownButtonFormField<String>(
          value: _selectedUniversity,
          decoration: const InputDecoration(
            labelText: AppStrings.university,
          ),
          items: options.map((university) {
            return DropdownMenuItem(
              value: university,
              child: Text(university),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedUniversity = value);
          },
          validator: (value) => value == null ? AppStrings.fieldRequired : null,
        );
      },
      loading: () => InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.university,
        ),
        child: const SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: AppStrings.university,
            ),
            child: Text(
              error.toString(),
              style: const TextStyle(color: EduPulseColors.error),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _retryUniversities,
              child: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final initialDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    final firstDate = DateTime(DateTime.now().year - 90);
    final lastDate = DateTime(DateTime.now().year - 12);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) 
          ? firstDate 
          : initialDate.isAfter(lastDate) 
              ? lastDate 
              : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedBirthDate = date);
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGovernorate == null) {
      _showError('يرجى اختيار المحافظة');
      return;
    }

    if (_selectedUniversity == null) {
      _showError('يرجى اختيار الجامعة');
      return;
    }

    if (_selectedBirthDate == null) {
      _showError('يرجى اختيار تاريخ الميلاد');
      return;
    }

    final birthDateError = Validators.validateBirthDate(_selectedBirthDate);
    if (birthDateError != null) {
      _showError(birthDateError);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).createProfile(
      phone: widget.phone,
      name: _nameController.text.trim(),
      governorate: _selectedGovernorate!,
      university: _selectedUniversity!,
      birthDate: _selectedBirthDate!,
      gender: _selectedGender,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (_) => context.go(AppRoutes.home),
      failure: (error) => _showError(error),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EduPulseColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = _selectedUniversityType;
    final universitiesAsync =
        selectedType != null ? ref.watch(universitiesProvider(selectedType)) : null;
    return Scaffold(
      backgroundColor: EduPulseColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: const [
            AppLogo(size: 36),
            SizedBox(width: 8),
            Text(AppStrings.completeProfile),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Full name
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullName,
                    hintText: 'أحمد محمد علي',
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Governorate dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: const InputDecoration(
                    labelText: AppStrings.governorate,
                  ),
                  items: MockData.governorates.map((governorate) {
                    return DropdownMenuItem(
                      value: governorate,
                      child: Text(governorate),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGovernorate = value);
                  },
                  validator: (value) => value == null ? AppStrings.fieldRequired : null,
                ),
                
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _selectedUniversityType,
                  decoration: const InputDecoration(
                    labelText: AppStrings.universityType,
                  ),
                  items: _universityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUniversityType = value;
                      _selectedUniversity = null;
                    });
                    if (value != null) {
                      ref.invalidate(universitiesProvider(value));
                    }
                  },
                  validator: (value) => value == null ? AppStrings.fieldRequired : null,
                ),

                const SizedBox(height: 20),

                // University dropdown from API
                _buildUniversityField(context, universitiesAsync),
                
                const SizedBox(height: 20),
                
                // Birth date
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: AppStrings.birthDate,
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                          : 'اختر تاريخ الميلاد',
                      style: TextStyle(
                        color: _selectedBirthDate != null
                            ? EduPulseColors.textMain
                            : EduPulseColors.textMain.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Gender selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        AppStrings.gender,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<Gender>(
                            title: const Text(AppStrings.male),
                            value: Gender.male,
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() => _selectedGender = value!);
                            },
                            activeColor: EduPulseColors.primary,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<Gender>(
                            title: const Text(AppStrings.female),
                            value: Gender.female,
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() => _selectedGender = value!);
                            },
                            activeColor: EduPulseColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          AppStrings.save,
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}