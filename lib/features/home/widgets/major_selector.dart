import 'package:flutter/material.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/theme.dart';

class MajorLevelSelector extends StatelessWidget {
  final List<Major> majors;
  final List<String> levels;
  final String? selectedMajorId;
  final String? selectedLevel;
  final ValueChanged<String> onMajorChanged;
  final ValueChanged<String> onLevelChanged;

  const MajorLevelSelector({
    super.key,
    required this.majors,
    required this.levels,
    required this.selectedMajorId,
    required this.selectedLevel,
    required this.onMajorChanged,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Major selector
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: EduPulseColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduPulseColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: EduPulseColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMajorId,
                  hint: Text(
                    AppStrings.selectMajor,
                    style: TextStyle(
                      color: EduPulseColors.textMain.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: EduPulseColors.primary,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EduPulseColors.textMain,
                  ),
                  items: majors.map((major) {
                    return DropdownMenuItem<String>(
                      value: major.id,
                      child: Text(
                        major.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onMajorChanged(value);
                    }
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Level selector
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: EduPulseColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduPulseColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: EduPulseColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLevel,
                  hint: Text(
                    AppStrings.selectLevel,
                    style: TextStyle(
                      color: EduPulseColors.textMain.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: EduPulseColors.primary,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EduPulseColors.textMain,
                  ),
                  items: levels.map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(
                        level,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onLevelChanged(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}