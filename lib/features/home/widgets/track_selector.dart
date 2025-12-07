import 'package:flutter/material.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/theme.dart';

class TrackSelector extends StatelessWidget {
  final CourseTrack selectedTrack;
  final ValueChanged<CourseTrack> onTrackChanged;

  const TrackSelector({
    super.key,
    required this.selectedTrack,
    required this.onTrackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
        child: Row(
          children: [
            Expanded(
              child: _TrackOption(
                title: AppStrings.firstTrack,
                isSelected: selectedTrack == CourseTrack.first,
                onTap: () => onTrackChanged(CourseTrack.first),
                isFirst: true,
              ),
            ),
            Expanded(
              child: _TrackOption(
                title: AppStrings.secondTrack,
                isSelected: selectedTrack == CourseTrack.second,
                onTap: () => onTrackChanged(CourseTrack.second),
                isFirst: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;

  const _TrackOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? EduPulseColors.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isSelected 
                ? Colors.white 
                : EduPulseColors.textMain,
            fontWeight: isSelected 
                ? FontWeight.w600 
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}