import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FilterChipGroup<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color selectedColor;
  final Color? unselectedColor;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.selectedColor = AppColors.accent,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selectedValue == option.value;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(option.value),
              backgroundColor: AppColors.surface(context),
              selectedColor: selectedColor,
              checkmarkColor: Colors.white,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border(context),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FilterOption<T> {
  final String label;
  final T value;

  const FilterOption({required this.label, required this.value});
}
