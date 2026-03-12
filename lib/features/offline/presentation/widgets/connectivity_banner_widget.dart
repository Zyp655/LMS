import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ConnectivityBannerWidget extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;

  const ConnectivityBannerWidget({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: isOnline ? const Offset(0, -1) : Offset.zero,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isOnline ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.error, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withAlpha(80),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đang offline — chỉ hiển thị nội dung đã tải',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onRetry != null)
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
