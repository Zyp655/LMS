import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ReviewCardWidget extends StatelessWidget {
  final String userName;
  final int rating;
  final String? comment;

  const ReviewCardWidget({
    super.key,
    required this.userName,
    required this.rating,
    this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              AppSpacing.gapH12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Anonymous',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _StarRating(rating: rating),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            AppSpacing.gapV12,
            Text(
              comment!,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 14,
        );
      }),
    );
  }
}
