import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:grace_academy/core/mock_data.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/core/validators.dart';
import 'package:grace_academy/data/models/university.dart';
import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/providers/university_provider.dart';
import 'package:grace_academy/theme.dart';

const List<String> _universityTypes = [
  AppStrings.universityTypeGovernment,
  AppStrings.universityTypePrivate,
];

class EditAccountPage extends ConsumerStatefulWidget {
  const EditAccountPage({super.key});

  @override
  ConsumerState<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends ConsumerState<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedGovernorate;
  String? _selectedUniversity;
  String? _selectedUniversityType;
  DateTime? _selectedBirthDate;
  Gender _selectedGender = Gender.male;

  bool _isSubmitting = false;
  bool _isInitialLoading = false;

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
        decoration: const InputDecoration(labelText: AppStrings.university),
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
          decoration: const InputDecoration(labelText: AppStrings.university),
          items: options.map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedUniversity = value),
          validator: (value) => (value == null || value.isEmpty) ? AppStrings.fieldRequired : null,
        );
      },
      loading: () => InputDecorator(
        decoration: const InputDecoration(labelText: AppStrings.university),
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
            decoration: const InputDecoration(labelText: AppStrings.university),
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
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _applyUser(user);
    }
    Future.microtask(_refreshFromServer);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    setState(() => _isInitialLoading = true);
    final result = await ref.read(authControllerProvider.notifier).fetchCurrentUser();
    if (!mounted) return;
    setState(() => _isInitialLoading = false);
    result.when(
      success: _applyUser,
      failure: _showError,
    );
  }

  void _applyUser(User user) {
    setState(() {
      _nameController.text = user.name;
      _selectedGovernorate = user.governorate.isNotEmpty ? user.governorate : null;
      _selectedUniversity = user.university.isNotEmpty ? user.university : null;
      if (user.birthDate.millisecondsSinceEpoch > 0) {
        _selectedBirthDate = user.birthDate;
      } else {
        _selectedBirthDate = null;
      }
      _selectedGender = user.gender;
    });

    if (_selectedUniversityType == null && user.university.isNotEmpty) {
      _inferUniversityType(user.university);
    }
  }

  Future<void> _inferUniversityType(String universityName) async {
    final trimmedName = universityName.trim();
    if (trimmedName.isEmpty) return;

    for (final type in _universityTypes) {
      try {
        final universities = await ref.read(universitiesProvider(type).future);
        final match = universities.any((u) => u.name.trim() == trimmedName);
        if (match && mounted) {
          setState(() {
            _selectedUniversityType = type;
          });
          return;
        }
      } catch (_) {
        // Ignore lookup errors, the user can select type manually.
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 18, 1, 1);
    final firstDate = DateTime(now.year - 90);
    final lastDate = DateTime(now.year - 12);

    final picked = await showDatePicker(
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

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGovernorate == null || _selectedGovernorate!.isEmpty) {
      _showError('يرجى اختيار المحافظة');
      return;
    }

    if (_selectedUniversity == null || _selectedUniversity!.isEmpty) {
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

    setState(() => _isSubmitting = true);

    final notifier = ref.read(authControllerProvider.notifier);
    final result = await notifier.updateProfile(
      name: _nameController.text.trim(),
      governorate: _selectedGovernorate,
      university: _selectedUniversity,
      birthDate: _selectedBirthDate,
      gender: _selectedGender,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        Navigator.of(context).pop(true);
      },
      failure: _showError,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EduPulseColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final governorates = [...MockData.governorates];
    if (_selectedGovernorate != null && _selectedGovernorate!.isNotEmpty && !governorates.contains(_selectedGovernorate)) {
      governorates.add(_selectedGovernorate!);
    }

    final selectedType = _selectedUniversityType;
    final universitiesAsync =
        selectedType != null ? ref.watch(universitiesProvider(selectedType)) : null;

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editAccount),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isInitialLoading)
                  const LinearProgressIndicator(minHeight: 4),
                if (_isInitialLoading)
                  const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullName,
                    hintText: 'أحمد محمد علي',
                  ),
                  validator: Validators.validateName,
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: const InputDecoration(labelText: AppStrings.governorate),
                  items: governorates.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGovernorate = value),
                  validator: (value) => (value == null || value.isEmpty) ? AppStrings.fieldRequired : null,
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedUniversityType,
                  decoration: const InputDecoration(labelText: AppStrings.universityType),
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
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.fieldRequired
                      : null,
                ),

                const SizedBox(height: 20),

                _buildUniversityField(context, universitiesAsync),

                const SizedBox(height: 20),

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
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
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
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                            activeColor: EduPulseColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: (_isSubmitting || _isInitialLoading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(AppStrings.updateProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}