import 'package:flutter/material.dart';
import 'package:focusquest/models/subject.dart';

enum SubjectChipSize { small, normal }

class SubjectChip extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final VoidCallback? onTap;
  final SubjectChipSize size;

  const SubjectChip({
    super.key,
    required this.subject,
    this.isSelected = false,
    this.onTap,
    this.size = SubjectChipSize.normal,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = size == SubjectChipSize.small;
    final bgColor = isSelected
        ? subject.color.withOpacity(0.3)
        : subject.color.withOpacity(0.15);
    final borderColor = isSelected
        ? subject.color
        : subject.color.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSmall ? 6 : 8,
              height: isSmall ? 6 : 8,
              decoration: BoxDecoration(
                color: subject.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isSmall ? 4 : 6),
            Text(
              subject.name,
              style: TextStyle(
                color: subject.color,
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
