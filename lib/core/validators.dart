import 'package:grace_academy/core/strings.dart';

class Validators {
  // Iraqi phone validation - accepts 7X XXXXXXXX format after +964
  static String? validateIraqiPhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    // Remove any spaces or formatting
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it matches Iraqi mobile pattern: 7(3|7|8|9)XXXXXXXX
    final iraqiPattern = RegExp(r'^7[3789]\d{8}$');
    
    if (!iraqiPattern.hasMatch(cleanValue)) {
      return AppStrings.invalidPhoneNumber;
    }
    
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.trim().length < 2) {
      return AppStrings.invalidName;
    }
    
    return null;
  }
  
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
  
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return AppStrings.invalidCode;
    }
    
    return null;
  }
  
  static String? validateBirthDate(DateTime? date) {
    if (date == null) {
      return AppStrings.fieldRequired;
    }
    
    final now = DateTime.now();
    final age = now.year - date.year;
    
    // Check if user is between 12 and 90 years old
    if (age < 12 || age > 90) {
      return AppStrings.invalidBirthDate;
    }
    
    return null;
  }
  
  static String formatIraqiPhone(String phone) {
    // Remove any existing formatting
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Add +964 prefix if not present
    if (!cleanPhone.startsWith('+964')) {
      return '+964$cleanPhone';
    }
    
    return cleanPhone;
  }
}